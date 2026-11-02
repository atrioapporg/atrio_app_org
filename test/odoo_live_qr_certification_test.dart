import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/servicios/join_church_service.dart';
import 'package:atrio/utils/qr_token_parser.dart';

void main() {
  const liveJoinUrl = 'https://atrioapp.odoo19rd.com/c/935e11a7-98be-40c5-8ea8-14daa04277c5';
  const expectedUuid = '935e11a7-98be-40c5-8ea8-14daa04277c5';

  group('Certificación en Vivo Odoo 19 - Flujo QR Real', () {
    test('1. Parser extrae el UUID exacto de la URL canónica real', () {
      final parsedToken = joinTokenFromUri(liveJoinUrl);
      expect(parsedToken, equals(expectedUuid));
    });

    test('2. GET /churches/join/{token} en vivo resuelve Parroquia San Pedro Nolasco (ID: 18)', () async {
      final service = JoinChurchService(baseUrl: 'https://atrioapp.odoo19rd.com');
      final preview = await service.getChurchPreview(expectedUuid);

      expect(preview.church.id, equals(18));
      expect(preview.church.name, equals('Parroquia San Pedro Nolasco'));
      expect(preview.canJoin, isTrue);
      expect(preview.joinUrl, equals(liveJoinUrl));
    });

    test('3. Flujo completo en vivo con usuario autenticado (leningrado777@demo.app)', () async {
      // 1. Login real en Odoo 19
      final api = AtrioApi(baseUrl: 'https://atrioapp.odoo19rd.com');
      final authData = await api.login('leningrado777@demo.app', '123456');

      final accessToken = (authData['access_token'] ?? authData['token']) as String?;
      expect(accessToken, isNotNull);
      expect(accessToken!.isNotEmpty, isTrue);

      // 2. Solicitud de membresía real en Odoo 19
      final service = JoinChurchService(baseUrl: 'https://atrioapp.odoo19rd.com');
      final result = await service.requestMembership(
        churchId: 18,
        accessToken: accessToken,
      );

      expect(result.status, equals('pending'));
    });
  });
}
