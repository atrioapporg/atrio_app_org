import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/join_church_models.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/join_church_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/servicios/join_church_service.dart';
import 'package:atrio/servicios/token_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  const testToken = '6f1c2b1e-8a3d-4b7e-9c55-2d0e7a41c3f9';
  const testUrl = 'https://atrioapp.odoo19rd.com/c/$testToken';

  group('JoinChurchProvider State Machine & Deferred Join', () {
    late TokenStorageService tokenStorage;
    late JoinChurchService joinService;
    late JoinChurchProvider joinProvider;
    late UserProvider userProvider;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      tokenStorage = TokenStorageService();
      await tokenStorage.clearTokens();

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/churches/join/')) {
          return http.Response(
            jsonEncode({
              'church': {
                'id': 1,
                'name': 'Parroquia San Pedro Nolasco',
                'logo_url': '/atrio/portal/api/image/atrio.church/1/logo',
              },
              'can_join': true,
              'join_url': testUrl,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.contains('/membership/request')) {
          return http.Response(
            jsonEncode({'status': 'pending', 'message': 'Solicitud enviada'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      joinService = JoinChurchService(
        baseUrl: 'https://atrioapp.odoo19rd.com',
        client: mockClient,
      );

      joinProvider = JoinChurchProvider(
        service: joinService,
        tokenStorage: tokenStorage,
      );

      userProvider = UserProvider(
        api: AtrioApi(
          baseUrl: 'https://atrioapp.odoo19rd.com',
          client: mockClient,
          storageService: tokenStorage,
        ),
        storageService: tokenStorage,
      );
    });

    test('1. Flujo Deferred Join (Usuario sin sesión): Guarda token y transiciona a requiresLogin', () async {
      expect(userProvider.isAuthenticated, isFalse);

      final success = await joinProvider.handleJoinToken(
        rawInput: testUrl,
        userProvider: userProvider,
      );

      expect(success, isTrue);
      expect(joinProvider.step, equals(JoinChurchStep.requiresLogin));
      expect(joinProvider.isScannerActive, isFalse);

      // Certificar que el token quedó salvaguardado en FlutterSecureStorage
      final pendingToken = await joinProvider.getPendingToken();
      expect(pendingToken, equals(testToken));
    });

    test('2. Reanudación tras login (checkAndResumePendingJoin): Consume token diferido y presenta preview', () async {
      // Simular token guardado previamente durante escaneo sin sesión
      await joinProvider.handleJoinToken(
        rawInput: testUrl,
        userProvider: userProvider,
      );
      expect(await joinProvider.getPendingToken(), equals(testToken));

      // Simular login exitoso
      await tokenStorage.saveTokens(
        accessToken: 'authenticated_access_token_123',
        refreshToken: 'refresh_token_123',
      );
      userProvider.api.token = 'authenticated_access_token_123';
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 10,
          nombre: 'Feligrés Prueba',
          email: 'feligres@demo.app',
          iglesiaActual: 'Sin iglesia seleccionada',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'FP',
          esMiembroVerificado: false,
          role: UserRole.user,
        ),
      );

      expect(userProvider.isAuthenticated, isTrue);

      // Reanudar el flujo post-login
      final resumed = await joinProvider.checkAndResumePendingJoin(
        userProvider: userProvider,
      );

      expect(resumed, isTrue);
      expect(joinProvider.step, equals(JoinChurchStep.previewReady));
      expect(joinProvider.currentPreview?.church.name, equals('Parroquia San Pedro Nolasco'));

      // Certificar que el token pendiente fue consumido y limpiado de storage
      final remainingPending = await joinProvider.getPendingToken();
      expect(remainingPending, isNull);
    });

    test('3. Confirmación formal de membresía (confirmJoinMembership): Radica POST y transiciona a success', () async {
      await tokenStorage.saveTokens(
        accessToken: 'authenticated_access_token_123',
        refreshToken: 'refresh_token_123',
      );
      userProvider.api.token = 'authenticated_access_token_123';
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 10,
          nombre: 'Feligrés Prueba',
          email: 'feligres@demo.app',
          iglesiaActual: 'Sin iglesia seleccionada',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'FP',
          esMiembroVerificado: false,
          role: UserRole.user,
        ),
      );



      await joinProvider.handleJoinToken(
        rawInput: testUrl,
        userProvider: userProvider,
      );

      expect(joinProvider.step, equals(JoinChurchStep.previewReady));

      final confirmed = await joinProvider.confirmJoinMembership(
        userProvider: userProvider,
      );

      expect(confirmed, isTrue);
      expect(joinProvider.step, equals(JoinChurchStep.success));
    });
  });
}
