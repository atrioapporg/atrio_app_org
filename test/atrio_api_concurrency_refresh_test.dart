import 'dart:convert';
import 'dart:typed_data';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/inicio_sesion_screen.dart';
import 'package:atrio/servicios/token_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Almacenamiento seguro en memoria para verificar el orden exacto de persistencia
/// antes de liberar las peticiones encoladas en el Completer.
class FakeMemoryTokenStorage extends TokenStorageService {
  String? storedAccessToken;
  String? storedRefreshToken;
  DateTime? storedExpiresAt;
  int saveTokensCallCount = 0;

  FakeMemoryTokenStorage({
    this.storedAccessToken,
    this.storedRefreshToken,
    this.storedExpiresAt,
  });

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    saveTokensCallCount++;
    storedAccessToken = accessToken;
    storedRefreshToken = refreshToken;
    if (expiresAt != null) {
      storedExpiresAt = expiresAt;
    }
  }

  @override
  Future<void> saveAccessToken(
    String accessToken, {
    DateTime? expiresAt,
  }) async {
    storedAccessToken = accessToken;
    if (expiresAt != null) {
      storedExpiresAt = expiresAt;
    }
  }

  @override
  Future<void> saveTokenExpiry(DateTime expiresAt) async {
    storedExpiresAt = expiresAt;
  }

  @override
  Future<String?> getAccessToken() async => storedAccessToken;

  @override
  Future<String?> getRefreshToken() async => storedRefreshToken;

  @override
  Future<DateTime?> getTokenExpiry() async => storedExpiresAt;

  @override
  Future<void> clearTokens() async {
    storedAccessToken = null;
    storedRefreshToken = null;
    storedExpiresAt = null;
  }

  @override
  Future<void> clearAll() async {
    await clearTokens();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'https://atrioapp.odoo19rd.com';
  final dummyPngBytes = Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ]);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AtrioApi - Control de Concurrencia (Single Flight) y Resiliencia OAuth2/JWT', () {
    test(
      '1. Single Flight Mutex & Persistencia Inmediata: 5 llamadas paralelas (QR, notificaciones, posts, ads, me) con 401 disparan UN SOLO /auth/refresh y persisten antes de reintentar',
      () async {
        int refreshCalls = 0;
        final List<String> retryObservedStoredTokens = [];

        final storage = FakeMemoryTokenStorage(
          storedAccessToken: 'expired_access_v1',
          storedRefreshToken: 'valid_refresh_v1',
        );

        final mockClient = MockClient((request) async {
          final path = request.url.path;
          final authHeader = request.headers['authorization'] ?? '';

          if (path.endsWith('/auth/refresh')) {
            refreshCalls++;
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['refresh_token'], equals('valid_refresh_v1'));

            // Simular latencia de red en Odoo 19 durante la rotación del par de tokens
            await Future<void>.delayed(const Duration(milliseconds: 60));

            return http.Response(
              jsonEncode({
                'access_token': 'fresh_access_v2',
                'refresh_token': 'fresh_refresh_v2',
                'expires_in': 1800,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          // Si usa el token expirado v1, devolver 401 simultáneamente
          if (authHeader == 'Bearer expired_access_v1') {
            await Future<void>.delayed(const Duration(milliseconds: 15));
            return http.Response(
              jsonEncode({
                'code': 'expired_token',
                'error': 'Token expirado',
              }),
              401,
              headers: {'content-type': 'application/json'},
            );
          }

          // Cuando reintenta con el nuevo token v2, verificamos que YA fue persistido en storage
          expect(authHeader, equals('Bearer fresh_access_v2'));
          retryObservedStoredTokens.add(
            '${storage.storedAccessToken}:${storage.storedRefreshToken}',
          );

          if (path.endsWith('/church/qr.png')) {
            return http.Response.bytes(
              dummyPngBytes,
              200,
              headers: {
                'content-type': 'image/png',
                'x-atrio-join-url': 'https://atrioapp.odoo19rd.com/c/iglesia-1',
              },
            );
          }

          return http.Response(
            jsonEncode({'status': 'ok', 'path': path}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = AtrioApi(
          baseUrl: baseUrl,
          storageService: storage,
          client: mockClient,
          enableLogging: false,
        );
        await api.initFromStorage();

        // Disparar ráfaga concurrente al volver a la app tras 30 minutos
        final results = await Future.wait<Object>([
          api.me(),
          api.getChurchQr(download: true),
          api.notifications(),
          api.posts(limit: 10),
          api.ads(placement: 'all'),
        ]);

        expect(results.length, equals(5));
        // Exactamente 1 llamada a /auth/refresh para las 5 peticiones paralelas
        expect(refreshCalls, equals(1));
        expect(storage.saveTokensCallCount, equals(1));
        expect(storage.storedAccessToken, equals('fresh_access_v2'));
        expect(storage.storedRefreshToken, equals('fresh_refresh_v2'));
        expect(storage.storedExpiresAt, isNotNull);

        // Todas las peticiones reintentadas vieron el nuevo par de tokens YA persistido en storage
        expect(retryObservedStoredTokens.length, equals(5));
        for (final entry in retryObservedStoredTokens) {
          expect(entry, equals('fresh_access_v2:fresh_refresh_v2'));
        }
      },
    );

    test(
      '2. Protección ante 401 escalonados (Staggered 401s): una petición lenta que recibe 401 después de completado el refresh reutiliza el nuevo token sin rotar de nuevo',
      () async {
        int refreshCalls = 0;

        final storage = FakeMemoryTokenStorage(
          storedAccessToken: 'expired_access_v1',
          storedRefreshToken: 'valid_refresh_v1',
        );

        final mockClient = MockClient((request) async {
          final path = request.url.path;
          final authHeader = request.headers['authorization'] ?? '';

          if (path.endsWith('/auth/refresh')) {
            refreshCalls++;
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return http.Response(
              jsonEncode({
                'access_token': 'fresh_access_v2',
                'refresh_token': 'fresh_refresh_v2',
                'expires_in': 1800,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (authHeader == 'Bearer expired_access_v1') {
            // /posts tarda mucho más en responder 401 (llega después de que /me ya refrescó y liberó el Completer)
            if (path.endsWith('/posts')) {
              await Future<void>.delayed(const Duration(milliseconds: 120));
            } else {
              await Future<void>.delayed(const Duration(milliseconds: 10));
            }
            return http.Response(
              jsonEncode({'code': 'unauthorized', 'error': 'Expired'}),
              401,
              headers: {'content-type': 'application/json'},
            );
          }

          expect(authHeader, equals('Bearer fresh_access_v2'));
          return http.Response(
            jsonEncode({'ok': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = AtrioApi(
          baseUrl: baseUrl,
          storageService: storage,
          client: mockClient,
          enableLogging: false,
        );
        await api.initFromStorage();

        await Future.wait([
          api.me(),
          api.posts(),
        ]);

        // Aunque el segundo 401 llegó mucho después de cerrarse el primer Completer,
        // NO se disparó un segundo /auth/refresh porque el token en memoria ya había cambiado.
        expect(refreshCalls, equals(1));
        expect(api.token, equals('fresh_access_v2'));
        expect(api.refreshToken, equals('fresh_refresh_v2'));
      },
    );

    test(
      '3. Renovación Proactiva / Preventiva (Pre-emptive Refresh): renueva silenciosamente 2 a 3 min antes de vencer evitando cualquier 401',
      () async {
        int refreshCalls = 0;
        int unauthorizedResponses = 0;

        // El token vence en 2 minutos (dentro de la ventana preventiva de 3 minutos)
        final storage = FakeMemoryTokenStorage(
          storedAccessToken: 'expiring_soon_access_v1',
          storedRefreshToken: 'valid_refresh_v1',
          storedExpiresAt: DateTime.now().add(const Duration(minutes: 2)),
        );

        final mockClient = MockClient((request) async {
          final path = request.url.path;
          final authHeader = request.headers['authorization'] ?? '';

          if (path.endsWith('/auth/refresh')) {
            refreshCalls++;
            await Future<void>.delayed(const Duration(milliseconds: 30));
            return http.Response(
              jsonEncode({
                'access_token': 'proactive_access_v2',
                'refresh_token': 'proactive_refresh_v2',
                'expires_in': 1800,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (authHeader != 'Bearer proactive_access_v2') {
            unauthorizedResponses++;
            return http.Response(
              jsonEncode({'code': 'unauthorized'}),
              401,
              headers: {'content-type': 'application/json'},
            );
          }

          if (path.endsWith('/church/qr.png')) {
            return http.Response.bytes(dummyPngBytes, 200);
          }

          return http.Response(
            jsonEncode({'ok': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = AtrioApi(
          baseUrl: baseUrl,
          storageService: storage,
          client: mockClient,
          enableLogging: false,
        );
        await api.initFromStorage();

        expect(api.shouldRefreshTokenPreemptively, isTrue);

        // Disparar múltiples peticiones en paralelo cuando el token está a 2 minutos de expirar
        await Future.wait<Object>([
          api.me(),
          api.notifications(),
          api.getChurchQr(),
        ]);

        // Se renovó 1 sola vez de forma preventiva y NINGUNA petición ordinaria recibió 401
        expect(refreshCalls, equals(1));
        expect(unauthorizedResponses, equals(0));
        expect(api.token, equals('proactive_access_v2'));
        expect(api.refreshToken, equals('proactive_refresh_v2'));
        expect(api.shouldRefreshTokenPreemptively, isFalse);
      },
    );

    test(
      '4. Tratamiento Seguro de Excepciones (Error Transitorio vs Error Fatal): fallo 503 en refresh NO cierra la sesión; fallo 401 fatal SÍ limpia sesión y redirige a InicioSesionScreen',
      () async {
        int sessionExpiredCount = 0;
        bool simulateFatalRefreshError = false;

        final storage = FakeMemoryTokenStorage(
          storedAccessToken: 'expired_access_v1',
          storedRefreshToken: 'refresh_token_90d',
        );

        final mockClient = MockClient((request) async {
          final path = request.url.path;

          if (path.endsWith('/auth/refresh')) {
            if (!simulateFatalRefreshError) {
              // Error transitorio de servidor (503 Service Unavailable)
              return http.Response(
                jsonEncode({
                  'code': 'service_unavailable',
                  'error': 'Mantenimiento temporal',
                }),
                503,
                headers: {'content-type': 'application/json'},
              );
            } else {
              // Error fatal tras agotar período de gracia o superar 90 días
              return http.Response(
                jsonEncode({
                  'code': 'invalid_refresh_token',
                  'error': 'Refresh token expirado o revocado',
                }),
                401,
                headers: {'content-type': 'application/json'},
              );
            }
          }

          return http.Response(
            jsonEncode({'code': 'unauthorized', 'error': 'Token vencido'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = AtrioApi(
          baseUrl: baseUrl,
          storageService: storage,
          client: mockClient,
          enableLogging: false,
          onSessionExpired: () {
            sessionExpiredCount++;
          },
        );
        await api.initFromStorage();

        // Caso A: Error 503 transitorio en /auth/refresh -> NO debe invalidar la sesión ni borrar tokens
        await expectLater(
          () => api.me(),
          throwsA(
            isA<AtrioApiException>().having((e) => e.status, 'status', 503),
          ),
        );
        expect(sessionExpiredCount, equals(0));
        expect(storage.storedRefreshToken, equals('refresh_token_90d'));
        expect(api.refreshToken, equals('refresh_token_90d'));

        // Caso B: Error 401 fatal en /auth/refresh -> invalida sesión una sola vez aunque haya ráfaga paralela
        simulateFatalRefreshError = true;
        await Future.wait([
          api.me().catchError((_) => <String, dynamic>{}),
          api.notifications().catchError((_) => <String, dynamic>{}),
          api.posts().catchError((_) => <String, dynamic>{}),
        ]);

        expect(sessionExpiredCount, equals(1));
        expect(api.token, isNull);
        expect(api.refreshToken, isNull);
        expect(storage.storedAccessToken, isNull);
        expect(storage.storedRefreshToken, isNull);
      },
    );

    testWidgets(
      '5. Redirección limpia a InicioSesionScreen en UserProvider tras error fatal de refresh',
      (tester) async {
        SharedPreferences.setMockInitialValues({'isLoggedIn': true});

        final navKey = GlobalKey<NavigatorState>();
        final storage = FakeMemoryTokenStorage(
          storedAccessToken: 'expired_access',
          storedRefreshToken: 'revoked_refresh',
        );

        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'invalid_refresh_token',
              'error': 'Token revocado',
            }),
            401,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = AtrioApi(
          baseUrl: baseUrl,
          storageService: storage,
          client: mockClient,
          enableLogging: false,
        );

        String? currentRoute;

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navKey,
            initialRoute: '/home',
            routes: {
              '/home': (_) => const Scaffold(body: Text('Home Screen')),
              InicioSesionScreen.routeName: (_) {
                currentRoute = InicioSesionScreen.routeName;
                return const Scaffold(body: Text('Login Screen Mock'));
              },
            },
          ),
        );

        final userProvider = UserProvider(
          api: api,
          storageService: storage,
          navigatorKey: navKey,
        );

        await tester.pumpAndSettle();

        expect(userProvider.currentUser, isNull);
        expect(currentRoute, equals(InicioSesionScreen.routeName));
        expect(find.text('Login Screen Mock'), findsOneWidget);
      },
    );
  });
}

