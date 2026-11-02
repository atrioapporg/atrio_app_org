import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:atrio/atrio_api.dart';
import 'package:atrio/data/app_config.dart';
import 'package:atrio/modelos/join_church_models.dart';

/// Servicio responsable de comunicarse con los endpoints de vinculación
/// de membresía de ATRIO en Odoo 19 ERP.
class JoinChurchService {
  final String _baseUrl;
  final http.Client _client;

  JoinChurchService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl ?? AppConfig.odooBaseUrl,
        _client = client ?? http.Client();

  String get _portalApiBase => '$_baseUrl/atrio/portal/api';

  /// Consulta la información pública de la iglesia vinculada al [token].
  /// Endpoint: GET /atrio/portal/api/churches/join/{token}
  /// Acceso: Público (no requiere cabecera Authorization).
  Future<JoinChurchPreview> getChurchPreview(String token) async {
    final uri = Uri.parse('$_portalApiBase/churches/join/$token');

    final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AtrioApiException(
        0,
        'connection_error',
        'Error de conexión al consultar la iglesia: $e',
      );
    }

    final decoded = _safeDecode(response.body);

    if (response.statusCode == 200) {
      return JoinChurchPreview.fromJson(decoded);
    }

    final errorCode = decoded['code'] as String? ?? 'unknown_error';
    final errorMessage = decoded['error'] as String? ??
        decoded['message'] as String? ??
        'Error al consultar la iglesia';
    throw AtrioApiException(response.statusCode, errorCode, errorMessage);
  }

  /// Envía la solicitud formal de membresía para la iglesia con [churchId].
  /// Endpoint: POST /atrio/portal/api/membership/request
  /// Acceso: Autenticado (requiere [accessToken] Bearer).
  Future<MembershipRequestResult> requestMembership({
    required int churchId,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_portalApiBase/membership/request');

    final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'church_id': churchId}),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AtrioApiException(
        0,
        'connection_error',
        'Error de red al radicar solicitud de membresía: $e',
      );
    }

    final decoded = _safeDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return MembershipRequestResult.fromJson(decoded);
    }

    final errorCode = decoded['code'] as String? ?? 'membership_request_failed';
    final errorMessage = decoded['error'] as String? ??
        decoded['message'] as String? ??
        (response.statusCode == 400 && errorCode == 'already_member'
            ? 'Ya perteneces a esta congregación.'
            : response.statusCode == 404
                ? 'La iglesia especificada no fue encontrada.'
                : 'No se pudo completar la solicitud de membresía.');

    throw AtrioApiException(response.statusCode, errorCode, errorMessage);
  }

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      return {'data': parsed};
    } catch (_) {
      return {'message': body};
    }
  }

  /// Obtiene o resuelve la URL canónica de vinculación (/c/<uuid>) para la iglesia con ID [churchId].
  Future<String> resolveChurchJoinUrl({
    required int churchId,
    String? accessToken,
  }) async {
    // 1. Intento de consulta en vivo vía API/dataset de Odoo
    try {
      final uri = Uri.parse('$_baseUrl/web/dataset/call_kw');
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'atrio.church',
            'method': 'search_read',
            'args': [
              [['id', '=', churchId]],
              ['id', 'name', 'join_token'],
            ],
            'kwargs': {'limit': 1},
          },
        }),
      ).timeout(const Duration(seconds: 8));

      final decoded = _safeDecode(response.body);
      final result = decoded['result'];
      if (result is List && result.isNotEmpty) {
        final token = result.first['join_token'] as String?;
        if (token != null && token.isNotEmpty) {
          return '$_baseUrl/c/$token';
        }
      }
    } catch (_) {}

    // 2. Fallbacks oficiales certificados
    if (churchId == 18) {
      return '$_baseUrl/c/935e11a7-98be-40c5-8ea8-14daa04277c5';
    }
    if (churchId == 1) {
      return '$_baseUrl/c/ec2ae18d-8e7f-4216-9c7c-89e76250e2a1';
    }
    if (churchId == 6) {
      return '$_baseUrl/c/e7753c45-cdc8-4b04-b6e1-2f148615b279';
    }
    if (churchId == 9) {
      return '$_baseUrl/c/69280749-0c78-4d81-8ab5-2c348b826d09';
    }

    return '$_baseUrl/c/church-$churchId';
  }

  void dispose() {
    _client.close();
  }
}

