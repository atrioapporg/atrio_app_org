import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/app_stage.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Flujo de Vinculación de Iglesia y Denominación Odoo 19', () {
    test('solicitarMembresia transmite place_id, church_name y denomination a Odoo vía /membership/request', () async {
      final requestedPayloads = <String, dynamic>{};
      final updateMePayloads = <String, dynamic>{};

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/membership/request') && request.method == 'POST') {
          requestedPayloads.addAll(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response(
            jsonEncode({
              'status': 'success',
              'membership_status': 'membership_pending',
              'message': 'Solicitud registrada.',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/me') && request.method == 'PUT') {
          updateMePayloads.addAll(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response(
            jsonEncode({'status': 'success', 'user': {'id': 100}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/me') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'id': 100,
              'name': 'Usuario Google',
              'email': 'elplacermotel69@gmail.com',
              'church': null,
              'requested_church_id': null,
              'membership_status': 'membership_pending',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{"error": "not found"}', 404);
      });

      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'token_google_user',
        client: mockClient,
      );

      final userProvider = UserProvider(api: api);

      // Simular usuario autenticado
      userProvider.updateUserProfile(
        nombre: 'Usuario Google',
        email: 'elplacermotel69@gmail.com',
        telefono: '',
        iglesiaActual: 'Sin iglesia seleccionada',
      );

      // Ejecutar la selección de la iglesia con Google Place ID y fe Católica
      await userProvider.solicitarMembresia(
        placeId: 'ChIJ_PARROQUIA_SAN_JOSE_CALASANZ',
        churchName: 'Parroquia San Jose de Calasanz',
        denominacion: 'Católica',
      );

      // 1. Verificar transmisión de payload a Odoo en /membership/request
      expect(requestedPayloads['place_id'], equals('ChIJ_PARROQUIA_SAN_JOSE_CALASANZ'));
      expect(requestedPayloads['church_name'], equals('Parroquia San Jose de Calasanz'));
      expect(requestedPayloads['denomination'], equals('Católica'));

      // 2. Verificar sincronización de fe religiosa en /me vía PUT
      expect(updateMePayloads['fe_religiosa'], equals('Católica'));

      // 3. Verificar que el estado local de UserProvider se actualizó reactivamente
      expect(userProvider.currentUser?.iglesiaActual, equals('Parroquia San Jose de Calasanz'));
      expect(userProvider.currentUser?.membershipStatus, equals('membership_pending'));
      expect(userProvider.currentUser?.isMembershipPending, isTrue);
      expect(userProvider.hasSelectedOrLinkedChurch, isTrue);
      expect(userProvider.currentStage, equals(AppStage.waitingApproval));
    });

    test('solicitarMembresia resuelve ID de Odoo si getChurchByPlace devuelve in_atrio', () async {
      final requestedPayloads = <String, dynamic>{};

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/churches/by-place')) {
          expect(request.url.queryParameters['place_id'], equals('ChIJ_PARROQUIA_CALASANZ'));
          return http.Response(
            jsonEncode({
              'status': 'in_atrio',
              'church': {
                'id': 25,
                'name': 'Parroquia San Jose de Calasanz',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/membership/request') && request.method == 'POST') {
          requestedPayloads.addAll(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response(
            jsonEncode({
              'status': 'success',
              'membership_status': 'membership_pending',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/me') && request.method == 'PUT') {
          return http.Response(jsonEncode({'status': 'success'}), 200);
        }

        if (request.url.path.endsWith('/me') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'id': 101,
              'name': 'Usuario',
              'email': 'test@atrio.org',
              'church': null,
              'membership_status': 'membership_pending',
            }),
            200,
          );
        }

        return http.Response('{}', 404);
      });

      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'token_valido',
        client: mockClient,
      );

      final userProvider = UserProvider(api: api);
      userProvider.updateUserProfile(
        nombre: 'Usuario',
        email: 'test@atrio.org',
        telefono: '',
        iglesiaActual: 'Sin iglesia seleccionada',
      );

      await userProvider.solicitarMembresia(
        placeId: 'ChIJ_PARROQUIA_CALASANZ',
        churchName: 'Parroquia San Jose de Calasanz',
        denominacion: 'Católica',
      );

      // Verificamos que resolvió el church_id: 25 devuelto por by-place
      expect(requestedPayloads['church_id'], equals(25));
      expect(requestedPayloads['church_name'], equals('Parroquia San Jose de Calasanz'));
      expect(userProvider.currentUser?.requestedChurchId, equals(25));
    });
  });
}
