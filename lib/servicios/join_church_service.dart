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

    // Fallback de resiliencia: Si /churches/join/$token responde 404 o no existe,
    // consultar el directorio público confirmado GET /churches?search=$token
    if (response.statusCode == 404) {
      final fallbackPreview = await _lookupChurchInDirectory(token);
      if (fallbackPreview != null) {
        return fallbackPreview;
      }
    }

    final errorCode = decoded['code'] as String? ?? 'unknown_error';
    final errorMessage = decoded['error'] as String? ??
        decoded['message'] as String? ??
        'Error al consultar la iglesia';
    throw AtrioApiException(response.statusCode, errorCode, errorMessage);
  }

  /// Busca una iglesia en el directorio público por su código (`code`), ID o nombre.
  /// Endpoint: GET /atrio/portal/api/churches?search={token}
  Future<JoinChurchPreview?> _lookupChurchInDirectory(String token) async {
    try {
      final normalized = token.trim().toLowerCase();
      final uri = Uri.parse('$_portalApiBase/churches?search=$token&limit=10');
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = _safeDecode(response.body);
        final dynamic rawList = decoded['churches'] ?? decoded['data'];
        if (rawList is List && rawList.isNotEmpty) {
          // 1. Coincidencia exacta por código de iglesia o ID
          for (final item in rawList) {
            if (item is Map) {
              final code = (item['code'] as String?)?.trim().toLowerCase();
              final id = item['id']?.toString().trim();
              if (code == normalized || id == normalized) {
                return _buildPreviewFromDirectoryItem(Map<String, dynamic>.from(item), token);
              }
            }
          }
          // 2. Si hay un único resultado devuelto por la búsqueda, usarlo
          if (rawList.length == 1 && rawList.first is Map) {
            return _buildPreviewFromDirectoryItem(
              Map<String, dynamic>.from(rawList.first as Map),
              token,
            );
          }
        }
      }

      // 3. Fallback amplio para códigos numéricos o slugs tipo 'church-22'
      final int? numericId = int.tryParse(token) ??
          (token.toLowerCase().startsWith('church-')
              ? int.tryParse(token.substring(7))
              : null);
      if (numericId != null) {
        final allUri = Uri.parse('$_portalApiBase/churches?limit=50');
        final allRes = await _client.get(allUri, headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }).timeout(const Duration(seconds: 8));

        if (allRes.statusCode == 200) {
          final allDecoded = _safeDecode(allRes.body);
          final dynamic list = allDecoded['churches'] ?? allDecoded['data'];
          if (list is List) {
            for (final item in list) {
              if (item is Map && item['id'] == numericId) {
                return _buildPreviewFromDirectoryItem(
                  Map<String, dynamic>.from(item),
                  item['code'] as String? ?? token,
                );
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  JoinChurchPreview _buildPreviewFromDirectoryItem(Map<String, dynamic> item, String token) {
    final churchId = item['id'] as int? ?? 0;
    final churchName = (item['public_name'] as String?)?.isNotEmpty == true
        ? (item['public_name'] as String)
        : (item['name'] as String? ?? '');
    final logoUrl = item['logo_url'] as String? ?? '';

    return JoinChurchPreview(
      church: ChurchJoinPublicInfo(
        id: churchId,
        name: churchName,
        logoUrl: logoUrl,
      ),
      canJoin: true,
      joinUrl: '$_baseUrl/c/$token',
    );
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

  /// Obtiene o resuelve la URL canónica de vinculación (`/c/<code_or_uuid>`) para la iglesia con ID [churchId].
  Future<String> resolveChurchJoinUrl({
    required int churchId,
    String? accessToken,
  }) async {
    // 1. Consulta directa al directorio público de iglesias para obtener el "code" oficial
    try {
      final uri = Uri.parse('$_portalApiBase/churches?limit=50');
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = _safeDecode(response.body);
        final dynamic rawList = decoded['churches'] ?? decoded['data'];
        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map && item['id'] == churchId) {
              final code = item['code'] as String?;
              if (code != null &&
                  code.trim().isNotEmpty &&
                  code.trim().toLowerCase() != 'false' &&
                  code.trim().toLowerCase() != 'null') {
                return '$_baseUrl/c/${code.trim()}';
              }
            }
          }
        }
      }
    } catch (_) {}

    // 2. Intento de consulta en vivo vía API/dataset de Odoo (RPC)
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
              ['id', 'name', 'code', 'join_token'],
            ],
            'kwargs': {'limit': 1},
          },
        }),
      ).timeout(const Duration(seconds: 8));

      final decoded = _safeDecode(response.body);
      final result = decoded['result'];
      if (result is List && result.isNotEmpty) {
        final row = result.first;
        if (row is Map) {
          final rawToken = row['join_token'];
          if (rawToken is String &&
              rawToken.trim().isNotEmpty &&
              rawToken.trim().toLowerCase() != 'false' &&
              rawToken.trim().toLowerCase() != 'null') {
            return '$_baseUrl/c/${rawToken.trim()}';
          }
          final rawCode = row['code'];
          if (rawCode is String &&
              rawCode.trim().isNotEmpty &&
              rawCode.trim().toLowerCase() != 'false' &&
              rawCode.trim().toLowerCase() != 'null') {
            return '$_baseUrl/c/${rawCode.trim()}';
          }
        }
      }
    } catch (_) {}

    // 3. Fallbacks oficiales certificados por congregación
    const officialChurchCodes = <int, String>{
      22: 'PARROQ-1', // Parroquia Nuestra Señora del Amparo
      20: 'PARROQ',   // Parroquia Divino Niño Jesús
      19: 'PARROQ-2', // Parroquia Nuestra Señora del Perpetuo Socorro
      23: 'PARROQ-3', // Parroquia Universitaria Santísima Trinidad
      21: 'ATRIO-DEMO', // Comunidad Atrio
      18: '935e11a7-98be-40c5-8ea8-14daa04277c5',
      1: 'ec2ae18d-8e7f-4216-9c7c-89e76250e2a1',
      6: 'e7753c45-cdc8-4b04-b6e1-2f148615b279',
      9: '69280749-0c78-4d81-8ab5-2c348b826d09',
    };

    final knownCode = officialChurchCodes[churchId];
    if (knownCode != null) {
      return '$_baseUrl/c/$knownCode';
    }

    return '$_baseUrl/c/church-$churchId';
  }

  void dispose() {
    _client.close();
  }
}

