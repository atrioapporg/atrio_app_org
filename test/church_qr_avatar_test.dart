import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:atrio/atrio_api.dart';

void main() {
  group('AtrioApi Church QR Tests', () {
    const baseUrl = 'https://atrioapp.odoo19rd.com';
    final dummyPngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    const mockJoinUrl = 'https://atrioapp.odoo19rd.com/c/6f1c2b1e-8a3d-4b7e-9c55-2d0e7a41c3f9';

    test('churchQrUrl genera la URL esperada con y sin download', () {
      final api = AtrioApi(baseUrl: baseUrl);
      expect(
        api.churchQrUrl(),
        equals('https://atrioapp.odoo19rd.com/atrio/portal/api/church/qr.png'),
      );
      expect(
        api.churchQrUrl(download: true),
        equals('https://atrioapp.odoo19rd.com/atrio/portal/api/church/qr.png?download=1'),
      );
    });

    test('getChurchQr descarga imagen PNG y lee encabezado X-Atrio-Join-Url', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(
          request.url.toString(),
          equals('https://atrioapp.odoo19rd.com/atrio/portal/api/church/qr.png?download=1'),
        );
        expect(request.headers['authorization'], equals('Bearer test_token'));

        return http.Response.bytes(
          dummyPngBytes,
          200,
          headers: {
            'content-type': 'image/png',
            'x-atrio-join-url': mockJoinUrl,
          },
        );
      });

      final api = AtrioApi(
        baseUrl: baseUrl,
        token: 'test_token',
        client: mockClient,
      );

      final result = await api.getChurchQr(download: true);
      expect(result.bytes, equals(dummyPngBytes));
      expect(result.joinUrl, equals(mockJoinUrl));
    });

    test('getChurchQr maneja 404 no_church lanzando AtrioApiException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'code': 'no_church', 'error': 'El usuario no tiene iglesia asignada.'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = AtrioApi(
        baseUrl: baseUrl,
        token: 'test_token',
        client: mockClient,
      );

      expect(
        () => api.getChurchQr(),
        throwsA(
          isA<AtrioApiException>()
              .having((e) => e.status, 'status', 404)
              .having((e) => e.code, 'code', 'no_church'),
        ),
      );
    });
  });
}

