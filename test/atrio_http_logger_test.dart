import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/servicios/atrio_http_logger.dart';

void main() {
  group('AtrioHttpLogger & AtrioApi Network Logging (Odoo 19)', () {
    test('Registra correctamente peticiones exitosas 🚀 [ATRIO REQ] y ✅ [ATRIO RES]', () async {
      final logs = <String>[];

      // Redirigir debugPrint a una lista para verificar la salida
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      try {
        final mockClient = MockClient((request) async {
          expect(request.headers['X-Atrio-Church'], equals('77'));
          return http.Response(
            jsonEncode({'status': 'ok', 'user_id': 10}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = AtrioApi(
          baseUrl: 'https://test.atrioapp.org',
          token: 'token_prueba',
          defaultChurchId: 77,
          isReadOnly: true,
          client: mockClient,
          enableLogging: true,
        );

        final result = await api.me();
        expect(result['status'], equals('ok'));

        // Verificar logs capturados
        final reqLog = logs.firstWhere((l) => l.contains('🚀 [ATRIO REQ]'));
        expect(reqLog, contains('GET'));
        expect(reqLog, contains('/me'));
        expect(reqLog, contains('X-Atrio-Church: 77'));

        final resLog = logs.firstWhere((l) => l.contains('✅ [ATRIO RES]'));
        expect(resLog, contains('200 OK'));
        expect(resLog, contains('"status": "ok"'));
      } finally {
        debugPrint = originalDebugPrint;
      }
    });

    test('Registra correctamente errores HTTP ❌ [ATRIO ERR] ante códigos >= 400', () async {
      final logs = <String>[];

      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      try {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'church_declined',
                'message': 'La congregación fue declinada por administración.',
              }
            }),
            403,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = AtrioApi(
          baseUrl: 'https://test.atrioapp.org',
          token: 'token_prueba',
          client: mockClient,
          enableLogging: true,
        );

        await expectLater(
          api.me(),
          throwsA(isA<AtrioApiException>()),
        );

        final errLog = logs.firstWhere((l) => l.contains('❌ [ATRIO ERR]'));
        expect(errLog, contains('403 Forbidden'));
        expect(errLog, contains('church_declined'));
        expect(errLog, contains('La congregación fue declinada'));
      } finally {
        debugPrint = originalDebugPrint;
      }
    });

    test('Registra fallos de red y excepciones ❌ [ATRIO ERR] en logNetworkException', () {
      final logs = <String>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      try {
        AtrioHttpLogger.logNetworkException(
          method: 'POST',
          uri: Uri.parse('https://test.atrioapp.org/api/test'),
          exception: const FormatException('Fallo de socket o DNS'),
          duration: const Duration(milliseconds: 120),
        );

        final errLog = logs.firstWhere((l) => l.contains('❌ [ATRIO ERR]'));
        expect(errLog, contains('POST'));
        expect(errLog, contains('Fallo de socket o DNS'));
        expect(errLog, contains('120 ms'));
      } finally {
        debugPrint = originalDebugPrint;
      }
    });
  });
}
