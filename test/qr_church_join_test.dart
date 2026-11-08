import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/servicios/join_church_service.dart';
import 'package:atrio/utils/qr_token_parser.dart';

void main() {
  group('1. Validador y Parser de Token QR (joinTokenFromUri)', () {
    const validUuid = '6f1c2b1e-8a3d-4b7e-9c55-2d0e7a41c3f9';

    test('Extrae token correctamente de URL canónica de Odoo 19', () {
      const url = 'https://atrioapp.odoo19rd.com/c/6f1c2b1e-8a3d-4b7e-9c55-2d0e7a41c3f9';
      expect(joinTokenFromUri(url), equals(validUuid));
    });

    test('Extrae token de URL canónica con trailing slash', () {
      const url = 'https://atrioapp.odoo19rd.com/c/6f1c2b1e-8a3d-4b7e-9c55-2d0e7a41c3f9/';
      expect(joinTokenFromUri(url), equals(validUuid));
    });

    test('Extrae token de esquema personalizado de la app (atrio://app/c/<uuid>)', () {
      const url = 'atrio://app/c/6f1c2b1e-8a3d-4b7e-9c55-2d0e7a41c3f9';
      expect(joinTokenFromUri(url), equals(validUuid));
    });

    test('Extrae token de texto plano que contenga solo el UUID', () {
      expect(joinTokenFromUri(validUuid), equals(validUuid));
    });

    test('Normaliza UUIDs con mayúsculas a minúsculas', () {
      final upper = validUuid.toUpperCase();
      expect(joinTokenFromUri(upper), equals(validUuid));
    });

    test('Retorna null ante URLs o textos no válidos', () {
      expect(joinTokenFromUri(null), isNull);
      expect(joinTokenFromUri(''), isNull);
      expect(joinTokenFromUri('   '), isNull);
      expect(joinTokenFromUri('https://google.com'), isNull);
      expect(joinTokenFromUri('https://atrioapp.odoo19rd.com/c/token-invalido'), isNull);
      expect(joinTokenFromUri('12345678-not-a-uuid'), isNull);
    });
  });

  group('2. Servicio JoinChurchService (Odoo 19 REST)', () {
    const testToken = '6f1c2b1e-8a3d-4b7e-9c55-2d0e7a41c3f9';

    test('getChurchPreview() retorna JoinChurchPreview exitoso en 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(
          request.url.toString(),
          equals('https://atrioapp.odoo19rd.com/atrio/portal/api/churches/join/$testToken'),
        );

        final responseJson = {
          'church': {
            'id': 1,
            'name': 'Parroquia San Pedro Nolasco',
            'logo_url': '/atrio/portal/api/image/atrio.church/1/logo',
          },
          'can_join': true,
          'join_url': 'https://atrioapp.odoo19rd.com/c/$testToken',
        };

        return http.Response(jsonEncode(responseJson), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final service = JoinChurchService(
        baseUrl: 'https://atrioapp.odoo19rd.com',
        client: mockClient,
      );

      final preview = await service.getChurchPreview(testToken);
      expect(preview.church.id, equals(1));
      expect(preview.church.name, equals('Parroquia San Pedro Nolasco'));
      expect(preview.canJoin, isTrue);
      expect(preview.joinUrl, contains(testToken));
    });

    test('getChurchPreview() lanza AtrioApiException(404, "church_not_found") si no existe', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'La iglesia no está disponible.',
            'code': 'church_not_found',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = JoinChurchService(
        baseUrl: 'https://atrioapp.odoo19rd.com',
        client: mockClient,
      );

      expect(
        () => service.getChurchPreview(testToken),
        throwsA(
          isA<AtrioApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.code, 'code', 'church_not_found'),
        ),
      );
    });

    test('requestMembership() envía church_id con Bearer token en cabecera', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.headers['Authorization'], equals('Bearer valid_access_token_xyz'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['church_id'], equals(1));

        return http.Response(
          jsonEncode({'status': 'pending', 'message': 'Solicitud radicada con éxito'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = JoinChurchService(
        baseUrl: 'https://atrioapp.odoo19rd.com',
        client: mockClient,
      );

      final result = await service.requestMembership(
        churchId: 1,
        accessToken: 'valid_access_token_xyz',
      );

      expect(result.status, equals('pending'));
      expect(result.message, equals('Solicitud radicada con éxito'));
    });

    test('requestMembership() maneja error 400 "already_member"', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'Ya perteneces a esta congregación.',
            'code': 'already_member',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = JoinChurchService(
        baseUrl: 'https://atrioapp.odoo19rd.com',
        client: mockClient,
      );

      expect(
        () => service.requestMembership(
          churchId: 1,
          accessToken: 'valid_access_token_xyz',
        ),
        throwsA(
          isA<AtrioApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.code, 'code', 'already_member'),
        ),
      );
    });
  });
}
