import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Sistema centralizado de logging visual para el tráfico de red de Odoo 19 en ATRIO.
///
/// Imprime en consola de Flutter DevTools las solicitudes (🚀 [ATRIO REQ]),
/// respuestas exitosas (✅ [ATRIO RES]) y fallos de HTTP o red (❌ [ATRIO ERR])
/// con formato enriquecido, cabeceras contextuales (ej. X-Atrio-Church) y payloads JSON.
class AtrioHttpLogger {
  const AtrioHttpLogger._();

  static const String _lineSeparator =
      '══════════════════════════════════════════════════════════════════';
  static const String _subSeparator =
      '──────────────────────────────────────────────────────────────────';

  /// Registra una petición HTTP saliente hacia Odoo 19.
  static void logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('🚀 [ATRIO REQ] $_lineSeparator');
    buffer.writeln('   • Método:  $method');
    buffer.writeln('   • URL:     $uri');
    buffer.writeln('   • Headers:');

    if (headers.isEmpty) {
      buffer.writeln('       (ninguna cabecera personalizada)');
    } else {
      headers.forEach((key, value) {
        final displayValue = _sanitizeHeader(key, value);
        // Destacar cabeceras contextuales clave de Odoo
        final isContextual = key == 'X-Atrio-Church' ||
            key == 'X-Odoo-Database' ||
            key == 'Idempotency-Key';
        final marker = isContextual ? '⭐ ' : '   ';
        buffer.writeln('     $marker$key: $displayValue');
      });
    }

    buffer.writeln('   • Payload:');
    if (body == null || body.isEmpty) {
      buffer.writeln('       (sin payload)');
    } else {
      buffer.writeln(_prettyJson(body, indent: '       '));
    }
    buffer.writeln('   $_subSeparator');

    _printMultiline(buffer.toString());
  }

  /// Registra una respuesta HTTP exitosa devuelta por Odoo 19 (códigos 2xx / 3xx).
  static void logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required Duration duration,
    required Map<String, dynamic> data,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('✅ [ATRIO RES] $_lineSeparator');
    buffer.writeln('   • Petición: $method $uri');
    buffer.writeln('   • Estado:   $statusCode ${_httpStatusText(statusCode)}');
    buffer.writeln('   • Duración: ${duration.inMilliseconds} ms');
    buffer.writeln('   • Datos Recibidos:');

    if (data.isEmpty) {
      buffer.writeln('       (respuesta vacía)');
    } else {
      buffer.writeln(_prettyJson(data, indent: '       '));
    }
    buffer.writeln('   $_subSeparator');

    _printMultiline(buffer.toString());
  }

  /// Registra un error de respuesta HTTP devuelto por Odoo 19 (códigos 400, 401, 403, 404, 500, etc.).
  static void logHttpError({
    required String method,
    required Uri uri,
    required int statusCode,
    required Duration duration,
    required String errorCode,
    required String errorMessage,
    dynamic rawBody,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('❌ [ATRIO ERR] $_lineSeparator');
    buffer.writeln('   • Petición: $method $uri');
    buffer.writeln('   • Estado:   $statusCode ${_httpStatusText(statusCode)}');
    buffer.writeln('   • Duración: ${duration.inMilliseconds} ms');
    buffer.writeln('   • Odoo Code:    $errorCode');
    buffer.writeln('   • Odoo Mensaje: $errorMessage');

    if (rawBody != null) {
      buffer.writeln('   • Respuesta del Servidor:');
      if (rawBody is Map || rawBody is List) {
        buffer.writeln(_prettyJson(rawBody, indent: '       '));
      } else {
        buffer.writeln('       $rawBody');
      }
    }
    buffer.writeln('   $_subSeparator');

    _printMultiline(buffer.toString());
  }

  /// Registra una excepción de transporte o de red (TimeoutException, SocketException, ClientException).
  static void logNetworkException({
    required String method,
    required Uri uri,
    required Object exception,
    required Duration duration,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('❌ [ATRIO ERR] $_lineSeparator');
    buffer.writeln('   • Petición: $method $uri');
    buffer.writeln('   • Fallo de Red / Excepción tras ${duration.inMilliseconds} ms');
    buffer.writeln('   • Excepción: $exception');
    if (stackTrace != null && kDebugMode) {
      final traceSnippet = stackTrace.toString().split('\n').take(3).join('\n       ');
      buffer.writeln('   • Traza:\n       $traceSnippet');
    }
    buffer.writeln('   $_subSeparator');

    _printMultiline(buffer.toString());
  }

  /// Ofusca tokens y datos altamente sensibles mientras mantiene la visibilidad de debugging.
  static String _sanitizeHeader(String key, String value) {
    final lowerKey = key.toLowerCase();
    if (lowerKey == 'authorization') {
      if (value.startsWith('Bearer ') && value.length > 25) {
        final prefix = value.substring(0, 15);
        final suffix = value.substring(value.length - 6);
        return '$prefix...$suffix (${value.length} chars)';
      }
      return 'Bearer [presente]';
    }
    return value;
  }

  /// Convierte una estructura de datos a JSON formateado con sangría consistente.
  static String _prettyJson(dynamic data, {required String indent}) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(data);
      return jsonString
          .split('\n')
          .map((line) => '$indent$line')
          .join('\n');
    } catch (_) {
      return '$indent$data';
    }
  }

  /// Imprime mediante debugPrint línea por línea para evitar truncamiento en terminales móviles/Logcat.
  static void _printMultiline(String message) {
    debugPrint(message);
  }

  /// Retorna una descripción canónica para el código de estado HTTP.
  static String _httpStatusText(int code) {
    switch (code) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 204:
        return 'No Content';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 405:
        return 'Method Not Allowed';
      case 409:
        return 'Conflict';
      case 422:
        return 'Unprocessable Entity';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      case 504:
        return 'Gateway Timeout';
      default:
        return '';
    }
  }
}
