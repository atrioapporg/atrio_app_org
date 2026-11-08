import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/ajustes_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/perfil_screen.dart';
import 'package:atrio/servicios/auth_service.dart';
import 'package:atrio/servicios/token_storage_service.dart';

/// Implementación en memoria de TokenStorageService para pruebas herméticas
class MockTokenStorageService extends TokenStorageService {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> saveAccessToken(String accessToken) async {
    _accessToken = accessToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<void> clearAll() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<bool> hasToken() async => _accessToken != null && _accessToken!.isNotEmpty;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Flujo OAuth & Social Login (Google Sign-In) y Persistencia', () {
    test('AtrioApi.loginWithSocial persiste tokens en TokenStorageService', () async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        storageService: mockStorage,
      );

      expect(api.isAuthenticated, isFalse);

      final result = await api.loginWithSocial(
        provider: 'google',
        email: 'leningrado.google@gmail.com',
        name: 'Lenin Google Test',
        idToken: 'mock_google_id_token_12345',
        accessToken: 'mock_google_access_token_abcde',
      );

      // Verificamos que los tokens se hayan guardado en memoria y en el almacenamiento seguro
      expect(api.isAuthenticated, isTrue);
      expect(api.token, isNotNull);
      expect(await mockStorage.getAccessToken(), isNotNull);
      expect(await mockStorage.getRefreshToken(), isNotNull);
      expect(result['user'], isNotNull);
      expect(result['user']['email'], 'leningrado.google@gmail.com');
    });

    test('UserProvider.loginWithSocial actualiza el estado global reactivo', () async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);

      expect(userProvider.isAuthenticated, isFalse);
      expect(userProvider.currentUser, isNull);

      final ok = await userProvider.loginWithSocial(
        provider: 'google',
        email: 'juan.social@gmail.com',
        nombre: 'Juan Social Google',
        idToken: 'token_google_999',
        iglesiaActual: 'Comunidad de Gracia',
      );

      expect(ok, isTrue);
      expect(userProvider.isAuthenticated, isTrue);
      expect(userProvider.currentUser, isNotNull);
      expect(userProvider.currentUser!.nombre, 'Juan Social Google');
      expect(userProvider.currentUser!.email, 'juan.social@gmail.com');
      expect(userProvider.currentUser!.iglesiaActual, 'Comunidad de Gracia');
      expect(userProvider.role, UserRole.user);

      // Verificar que SharedPreferences guardó la sesión
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isLoggedIn'), isTrue);
      expect(prefs.getString('userEmail'), 'juan.social@gmail.com');
    });

    test('UserProvider.updateUserProfile inicializa UserModel si era null (resiliencia)', () {
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(null);
      expect(userProvider.currentUser, isNull);

      userProvider.updateUserProfile(
        nombre: 'Carlos Resiliente',
        email: 'carlos@demo.com',
        telefono: '8095551234',
        iglesiaActual: 'Iglesia Central',
      );

      expect(userProvider.currentUser, isNotNull);
      expect(userProvider.currentUser!.nombre, 'Carlos Resiliente');
      expect(userProvider.currentUser!.email, 'carlos@demo.com');
      expect(userProvider.currentUser!.avatarIniciales, 'C');
    });

    testWidgets('PerfilScreen refleja la sesión activa de Google y no cae en modo invitado',
        (tester) async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'valid_bearer_token',
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);

      // Simulamos el usuario autenticado vía Google
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 55,
          nombre: 'Lenin Google',
          email: 'leningrado.google@gmail.com',
          iglesiaActual: 'Iglesia Atrio Central',
          iglesiaId: 1,
          fechaRegistro: '2026-10-23',
          avatarIniciales: 'LG',
          esMiembroVerificado: true,
          role: UserRole.user,
          permissions: const {'view_content', 'manage_profile'},
          isReadOnly: false,
        ),
      );

      expect(userProvider.isAuthenticated, isTrue);

      final iglesiaProvider = IglesiaProvider();
      final ajustesProvider = AjustesProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<IglesiaProvider>.value(value: iglesiaProvider),
            ChangeNotifierProvider<AjustesProvider>.value(value: ajustesProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('es'),
            home: Scaffold(
              body: PerfilScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Debe mostrar el nombre del usuario autenticado por Google
      expect(find.text('Lenin Google'), findsOneWidget);

      // 2. NO debe mostrar "Usuario invitado"
      expect(find.text('Usuario invitado'), findsNothing);

      // 3. NO debe mostrar el banner amarillo de advertencia de modo invitado
      expect(
        find.textContaining('Estás navegando en modo invitado'),
        findsNothing,
      );

      // 4. Debe mostrar el botón de Cerrar sesión (no el de Iniciar sesión)
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('PerfilScreen muestra modo invitado cuando no hay sesión activa',
        (tester) async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: null, // Sin token
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);
      userProvider.setCurrentUserForTesting(null); // Sin usuario

      expect(userProvider.isAuthenticated, isFalse);

      final iglesiaProvider = IglesiaProvider();
      final ajustesProvider = AjustesProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<IglesiaProvider>.value(value: iglesiaProvider),
            ChangeNotifierProvider<AjustesProvider>.value(value: ajustesProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('es'),
            home: Scaffold(
              body: PerfilScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Debe mostrar "Usuario invitado" y el banner de modo invitado
      expect(find.text('Usuario invitado'), findsOneWidget);
      expect(
        find.textContaining('Estás navegando en modo invitado'),
        findsOneWidget,
      );
      expect(find.text('Iniciar sesión'), findsWidgets);
    });

    test('UserProvider.loginWithGoogle captura excepciones de red sin filtrar texto técnico crudo', () async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);

      // Simulamos llamada con token inválido que provoca fallo
      final result = await userProvider.loginWithGoogle(idToken: 'invalid_token_test');

      expect(result, isNull);
      expect(userProvider.isAuthenticated, isFalse);
      expect(userProvider.errorMessage, isNotNull);
      // Blindaje: El mensaje NUNCA debe contener trazas de Java/ApiException ni objetos crudos
      expect(userProvider.errorMessage!.contains('com.google.android.gms'), isFalse);
      expect(userProvider.errorMessage!.contains('ApiException'), isFalse);
    });

    testWidgets('AppLocalizations contiene claves para blindaje y feedback de Google Sign-In',
        (tester) async {
      late AppLocalizations l10nEs;
      late AppLocalizations l10nEn;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Builder(
            builder: (ctx) {
              l10nEs = AppLocalizations.of(ctx)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();

      expect(l10nEs.errorConexionGoogleTitulo, 'Conexión con Google');
      expect(l10nEs.errorGoogleRed.contains('servicios de Google'), isTrue);
      expect(l10nEs.errorGoogleConfig.contains('ApiException 10'), isTrue);
      expect(l10nEs.errorGoogleGenerico.isNotEmpty, isTrue);
      expect(l10nEs.bienvenidoAtrioUsuario('Carlos'), '¡Bienvenido a ATRIO, Carlos!');
      expect(l10nEs.bienvenidoDeNuevoUsuario('Carlos'), '¡Bienvenido de nuevo, Carlos!');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (ctx) {
              l10nEn = AppLocalizations.of(ctx)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();

      expect(l10nEn.errorConexionGoogleTitulo, 'Google Connection');
      expect(l10nEn.errorGoogleRed.contains('Google services'), isTrue);
      expect(l10nEn.bienvenidoAtrioUsuario('John'), 'Welcome to ATRIO, John!');
      expect(l10nEn.bienvenidoDeNuevoUsuario('John'), 'Welcome back, John!');
    });

    test('AuthService.isDeveloperConfigError detecta con precisión ApiException 10 (Play App Signing)', () {
      final apiEx10 = PlatformException(
        code: 'sign_in_failed',
        message: 'com.google.android.gms.common.api.ApiException: 10: ',
      );
      final networkEx = PlatformException(
        code: 'network_error',
        message: 'com.google.android.gms.common.api.ApiException: 7: ',
      );
      final canceledEx = PlatformException(
        code: 'sign_in_canceled',
        message: 'com.google.android.gms.common.api.ApiException: 12501: ',
      );

      expect(AuthService.isDeveloperConfigError(apiEx10), isTrue);
      expect(AuthService.isDeveloperConfigError(networkEx), isFalse);
      expect(AuthService.isDeveloperConfigError(canceledEx), isFalse);
    });
  });
}
