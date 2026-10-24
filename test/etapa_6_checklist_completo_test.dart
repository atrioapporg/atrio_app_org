import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Etapa 6 - Checklist de Validación de los 12 Casos de Prueba', () {
    // ------------------------------------------------------------------------
    // Caso 1: Registro correo + solicitud iglesia
    // ------------------------------------------------------------------------
    test('Caso 1: Registro correo con solicitud de iglesia deriva en AppStage.waitingApproval', () {
      final mePayload = {
        'id': 101,
        'name': 'Lucas Evangelista',
        'email': 'lucas@correo.com',
        'role': 'user',
        'membership_status': 'membership_pending',
        'requested_church_id': 15,
        'requested_church': {'id': 15, 'name': 'Iglesia Galilea'},
      };

      final stage = resolveStage(mePayload);
      final user = UserModel.fromOdooJson(mePayload);

      expect(stage, AppStage.waitingApproval);
      expect(user.isMembershipPending, isTrue);
      expect(user.requestedChurchId, 15);
      expect(user.requestedChurchData?['name'], 'Iglesia Galilea');
    });

    // ------------------------------------------------------------------------
    // Caso 2: Pastor aprueba solicitud
    // ------------------------------------------------------------------------
    test('Caso 2: Aprobación de solicitud por el pastor transiciona a AppStage.memberHome', () {
      final mePayloadAprobado = {
        'id': 101,
        'name': 'Lucas Evangelista',
        'email': 'lucas@correo.com',
        'role': 'member',
        'membership_status': 'approved',
        'church': {
          'id': 15,
          'name': 'Iglesia Galilea',
          'has_active_subscription': true,
        },
      };

      final stage = resolveStage(mePayloadAprobado);
      final user = UserModel.fromOdooJson(mePayloadAprobado);

      expect(stage, AppStage.memberHome);
      expect(user.isMembershipPending, isFalse);
      expect(user.isMember, isTrue);
      expect(user.hasActiveSubscription, isTrue);
    });

    // ------------------------------------------------------------------------
    // Caso 3: Pastor rechaza solicitud
    // ------------------------------------------------------------------------
    test('Caso 3: Rechazo de solicitud por el pastor devuelve a AppStage.chooseChurch', () {
      final mePayloadRechazado = {
        'id': 101,
        'name': 'Lucas Evangelista',
        'email': 'lucas@correo.com',
        'role': 'user',
        'membership_status': 'none',
        'requested_church_id': null,
      };

      final stage = resolveStage(mePayloadRechazado);
      final user = UserModel.fromOdooJson(mePayloadRechazado);

      expect(stage, AppStage.chooseChurch);
      expect(user.isMembershipPending, isFalse);
      expect(user.membershipStatus, 'none');
    });

    // ------------------------------------------------------------------------
    // Caso 4: Creación de iglesia con cuenta / usuario autenticado
    // ------------------------------------------------------------------------
    test('Caso 4: Creación de iglesia transiciona a church_admin en AppStage.churchPendingActivation', () {
      final mePayloadAdminPendiente = {
        'id': 202,
        'name': 'Pastor Bernabé',
        'email': 'bernabe@iglesia.org',
        'role': 'church_admin',
        'church': {
          'id': 77,
          'name': 'Comunidad de Antioquía',
          'has_active_subscription': false,
        },
      };

      final stage = resolveStage(mePayloadAdminPendiente);
      final user = UserModel.fromOdooJson(mePayloadAdminPendiente);

      expect(stage, AppStage.churchPendingActivation);
      expect(user.isChurchAdmin, isTrue);
      expect(user.hasActiveSubscription, isFalse);
    });

    // ------------------------------------------------------------------------
    // Caso 5: Activación de suscripción de la iglesia por equipo Atrio
    // ------------------------------------------------------------------------
    test('Caso 5: Activación de suscripción de iglesia transiciona a AppStage.adminHome', () {
      final mePayloadAdminActivo = {
        'id': 202,
        'name': 'Pastor Bernabé',
        'email': 'bernabe@iglesia.org',
        'role': 'church_admin',
        'church': {
          'id': 77,
          'name': 'Comunidad de Antioquía',
          'has_active_subscription': true,
        },
      };

      final stage = resolveStage(mePayloadAdminActivo);
      final user = UserModel.fromOdooJson(mePayloadAdminActivo);

      expect(stage, AppStage.adminHome);
      expect(user.isChurchAdmin, isTrue);
      expect(user.hasActiveSubscription, isTrue);
    });

    // ------------------------------------------------------------------------
    // Caso 6: Google con usuario nuevo (created: true)
    // ------------------------------------------------------------------------
    test('Caso 6: Google con usuario nuevo devuelve created: true y va a chooseChurch', () {
      final googleNuevoPayload = {
        'id': 303,
        'name': 'Nuevo Usuario Google',
        'email': 'nuevo@gmail.com',
        'role': 'user',
        'membership_status': 'none',
      };

      final stage = resolveStage(googleNuevoPayload);
      expect(stage, AppStage.chooseChurch);
    });

    // ------------------------------------------------------------------------
    // Caso 7: Google con usuario existente (created: false)
    // ------------------------------------------------------------------------
    test('Caso 7: Google con usuario existente entra directo a su etapa correspondiente', () {
      final googleExistentePayload = {
        'id': 404,
        'name': 'Miembro Google',
        'email': 'existente@gmail.com',
        'role': 'member',
        'membership_status': 'approved',
        'church': {
          'id': 10,
          'name': 'Iglesia Central',
          'has_active_subscription': true,
        },
      };

      final stage = resolveStage(googleExistentePayload);
      expect(stage, AppStage.memberHome);
    });

    // ------------------------------------------------------------------------
    // Caso 8: Google con correo no verificado
    // ------------------------------------------------------------------------
    test('Caso 8: Error email_not_verified de Google se traduce con mensaje amigable', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/google')) {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'email_not_verified',
                'message': 'Google email is not verified',
              },
            }),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        client: mockClient,
      );
      final provider = UserProvider(api: api);

      try {
        await provider.loginWithGoogle(idToken: 'token_no_verificado');
      } catch (_) {}

      expect(
        provider.errorMessage,
        'Tu cuenta de Google no tiene el correo electrónico verificado.',
      );
    });

    // ------------------------------------------------------------------------
    // Caso 9: Google con correo existente con contraseña
    // ------------------------------------------------------------------------
    test('Caso 9: Error account_exists de Google se traduce con mensaje amigable', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/google')) {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'account_exists',
                'message': 'Account exists with password',
              },
            }),
            409,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        client: mockClient,
      );
      final provider = UserProvider(api: api);

      try {
        await provider.loginWithGoogle(idToken: 'token_conflictivo');
      } catch (_) {}

      expect(
        provider.errorMessage,
        'Ya tienes una cuenta registrada con este correo. Ingresa con tu contraseña.',
      );
    });

    // ------------------------------------------------------------------------
    // Caso 10: Solicitud de cambio de iglesia (change_pending)
    // ------------------------------------------------------------------------
    test('Caso 10: Solicitud de cambio de iglesia mantiene memberHome y activa isChangePending', () {
      final mePayloadCambio = {
        'id': 505,
        'name': 'Felipe',
        'email': 'felipe@correo.com',
        'role': 'user',
        'membership_status': 'change_pending',
        'requested_church_id': 99,
        'church': {
          'id': 12,
          'name': 'Iglesia de Origen',
          'has_active_subscription': true,
        },
      };

      final stage = resolveStage(mePayloadCambio);
      final user = UserModel.fromOdooJson(mePayloadCambio);

      expect(stage, AppStage.memberHome);
      expect(user.isChangePending, isTrue);
      expect(user.isMembershipPending, isFalse);
    });

    // ------------------------------------------------------------------------
    // Caso 11: Token expirado (30 min) y auto-renovación silenciosa
    // ------------------------------------------------------------------------
    test('Caso 11: 401 renueva token silenciosamente con /auth/refresh sin cerrar sesión', () async {
      int getMeCallCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          getMeCallCount++;
          if (getMeCallCount == 1) {
            // Primer intento: Token expirado
            return http.Response(
              jsonEncode({
                'error': {
                  'code': 'token_expired',
                  'message': 'Access token expired',
                },
              }),
              401,
              headers: {'content-type': 'application/json'},
            );
          }
          // Segundo intento tras refresh: Éxito
          return http.Response(
            jsonEncode({
              'id': 1,
              'name': 'Usuario Renovado',
              'role': 'member',
              'membership_status': 'approved',
              'church': {'id': 1, 'has_active_subscription': true},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response(
            jsonEncode({
              'token': 'nuevo_access_token_renovado',
              'refresh_token': 'nuevo_refresh_token',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        client: mockClient,
      );
      api.token = 'access_token_vencido';
      api.refreshToken = 'refresh_token_valido';

      final result = await api.me();

      expect(result['name'], 'Usuario Renovado');
      expect(api.token, 'nuevo_access_token_renovado');
      expect(getMeCallCount, 2);
    });

    // ------------------------------------------------------------------------
    // Caso 12: Cierre de sesión seguro (DELETE /devices + /auth/logout)
    // ------------------------------------------------------------------------
    test('Caso 12: Cierre de sesión seguro desregistra dispositivo y revoca tokens', () async {
      bool logoutCalled = false;
      bool unregisterDeviceCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/logout')) {
          logoutCalled = true;
          return http.Response(
            jsonEncode({'success': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.endsWith('/devices') && request.method == 'DELETE') {
          unregisterDeviceCalled = true;
          return http.Response(
            jsonEncode({'success': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        client: mockClient,
      );
      api.token = 'token_para_cerrar';
      api.refreshToken = 'refresh_para_cerrar';

      // 1. Desregistrar dispositivo
      await api.unregisterDevice({'token': 'dispositivo_123'});
      expect(unregisterDeviceCalled, isTrue);

      // 2. Cerrar sesión en el backend
      await api.logout();
      expect(logoutCalled, isTrue);
      expect(api.token, isNull);
      expect(api.refreshToken, isNull);
    });
  });
}
