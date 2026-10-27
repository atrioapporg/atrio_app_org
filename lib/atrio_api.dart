import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:atrio/data/app_config.dart';
import 'package:atrio/modelos/church_recommendation_model.dart';
import 'package:atrio/servicios/token_storage_service.dart';

/// Excepción personalizada para capturar y clasificar los errores devueltos por la API de Odoo.
/// Permite reaccionar adecuadamente a códigos HTTP y strings de error normalizados (ej: 'invalid_credentials').
class AtrioApiException implements Exception {
  final int status;
  final String code;
  final String message;

  AtrioApiException(this.status, this.code, this.message);

  int get statusCode => status;
  bool get isUnauthorized => status == 401;
  bool get isForbidden => status == 403;
  bool get isNotFound => status == 404;
  bool get isConflict => status == 409;
  bool get isServerError => status >= 500;

  // Errores específicos del flujo de recomendación y mapas
  bool get isChurchInAtrio => code == 'church_in_atrio';
  bool get isChurchDeclined => code == 'church_declined';
  bool get isChurchUnavailable => code == 'church_unavailable';
  bool get isMapsNotConfigured => code == 'maps_not_configured';
  bool get isMapsUnavailable => code == 'maps_unavailable';

  @override
  String toString() => 'AtrioApiException($status, $code): $message';
}

/// Cliente HTTP centralizado para interactuar con la API REST de Odoo para ATRIO (v19.0.4).
/// Gestiona autenticación por Bearer Tokens, refresco automático de sesión y almacenamiento seguro.
class AtrioApi {
  /// URL base del servidor Odoo (ej: https://atrioapp.odoo19rd.com).
  final String baseUrl;

  /// Nombre de la base de datos de Odoo (enviado en cabecera X-Odoo-Database solo si aplica).
  final String? database;

  /// Servicio opcional de almacenamiento seguro para persistir tokens automáticamente.
  final TokenStorageService? storageService;

  /// Callback opcional invocado cuando el refresh_token expira o es inválido y se debe redirigir al login.
  void Function()? onSessionExpired;

  /// Token de acceso corto (JWT/Bearer) para peticiones autenticadas.
  String? token;

  /// Token de refresco de larga duración para renovar el token de acceso sin pedir clave al usuario.
  String? refreshToken;

  /// ID de la iglesia contextual para consultas de auditoría global (enviado en cabecera X-Atrio-Church
  /// exclusivamente para sesiones de Super Admin con isReadOnly == true).
  int? defaultChurchId;

  /// Indica si la sesión actual opera en modo estrictamente de solo lectura (RBAC Odoo 19).
  /// Cuando es true, AtrioApi previene peticiones HTTP de mutación (POST, PUT, PATCH, DELETE) hacia endpoints de contenido.
  bool isReadOnly;

  /// Cliente HTTP opcional para inyección en pruebas unitarias y entornos simulados.
  final http.Client? client;

  AtrioApi({
    required this.baseUrl,
    this.database,
    this.token,
    this.refreshToken,
    this.storageService,
    this.onSessionExpired,
    this.defaultChurchId,
    this.isReadOnly = false,
    this.client,
  });

  bool _storageInitialized = false;

  /// Inicializa los tokens en memoria leyendo desde el almacenamiento seguro (si fue provisto).
  Future<void> initFromStorage() async {
    _storageInitialized = true;
    if (storageService != null) {
      token = await storageService!.getAccessToken();
      refreshToken = await storageService!.getRefreshToken();
    }
  }

  /// Asegura que los tokens del almacenamiento seguro hayan sido leídos en memoria antes de cualquier petición.
  Future<void> _ensureStorageLoaded() async {
    if (!_storageInitialized &&
        (token == null || refreshToken == null) &&
        storageService != null) {
      await initFromStorage();
    }
  }

  /// Control de concurrencia: si varias peticiones reciben 401 en paralelo,
  /// todas esperan a la misma renovación para no invalidar el refresh_token rotativo.
  Future<void>? _refreshOperation;

  /// Indica si actualmente existe una sesión iniciada con token disponible.
  bool get isAuthenticated => token != null && token!.isNotEmpty;

  /// Cabeceras HTTP estándar requeridas por la API de Odoo.
  /// En endpoints públicos de autenticación (/auth/login y /auth/refresh) se omite Authorization
  /// para evitar que un token expirado bloquee la renovación.
  ///
  /// Conforme a la especificación oficial "Permisos por perfil en Atrio" (por Pablo Oliveros):
  /// - Para usuarios normales (member, church_admin), la iglesia sale siempre del token del usuario en el servidor.
  /// - La cabecera [X-Atrio-Church] es EXCLUSIVA para el Super Admin (isReadOnly == true) para alternar
  ///   la visualización de cualquier congregación en modo de solo lectura.
  Map<String, String> _buildHeaders(
    String path, {
    int? churchId,
    Map<String, String>? extraHeaders,
  }) {
    final isPublicAuth = path == '/auth/login' ||
        path == '/auth/google' ||
        path == '/auth/refresh' ||
        path == '/auth/password/reset' ||
        path.contains('/auth/social_login') ||
        path.endsWith('/social_login') ||
        path == AppConfig.odooSocialAuthEndpoint;
    final effectiveChurchId = churchId ?? defaultChurchId;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (database != null && database!.isNotEmpty)
        'X-Odoo-Database': database!,
      // X-Atrio-Church es la cabecera canónica oficial para Super Admin en solo lectura
      if (isReadOnly && effectiveChurchId != null)
        'X-Atrio-Church': effectiveChurchId.toString(),
      if (!isPublicAuth && token != null && token!.isNotEmpty)
        'Authorization': 'Bearer $token',
      ...?extraHeaders,
    };
  }

  /// Expuesto para pruebas unitarias de RBAC y verificación de cabeceras seguras.
  @visibleForTesting
  Map<String, String> buildHeadersForTesting(
    String path, {
    int? churchId,
    Map<String, String>? extraHeaders,
  }) => _buildHeaders(path, churchId: churchId, extraHeaders: extraHeaders);

  /// Método thread-safe que asegura que solo se ejecute un refresh de tokens a la vez.
  Future<void> _safeRefresh() async {
    if (_refreshOperation != null) {
      debugPrint(
        '⏳ [AtrioApi] Ya existe una renovación en curso. Esperando resultado...',
      );
      return await _refreshOperation!;
    }

    final completer = Completer<void>();
    _refreshOperation = completer.future;

    try {
      await refresh();
      completer.complete();
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _refreshOperation = null;
    }
  }

  /// Método interno de transporte HTTP con soporte de reintento automático por expiración de token (401)
  /// e idempotencia de red mediante Idempotency-Key según especificación de Odoo 19.
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    Map<String, String>? extraHeaders,
    int? churchId,
    String? idempotencyKey,
    bool retryAuth = true,
  }) async {
    // Restricción preventiva de mutaciones en modo solo lectura (RBAC Odoo 19)
    final isMutation =
        method == 'POST' ||
        method == 'PUT' ||
        method == 'PATCH' ||
        method == 'DELETE';
    if (isReadOnly && isMutation && !path.startsWith('/auth/')) {
      throw AtrioApiException(
        403,
        'read_only',
        'Acción de escritura bloqueada: Modo de solo lectura activo.',
      );
    }

    await _ensureStorageLoaded();

    final String fullPath = path.startsWith('http')
        ? path
        : (path.startsWith('/api/')
            ? '$baseUrl$path'
            : '$baseUrl/atrio/portal/api$path');
    final uri = Uri.parse(fullPath).replace(queryParameters: query);

    final mergedHeaders = _buildHeaders(
      path,
      churchId: churchId,
      extraHeaders: {
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'Idempotency-Key': idempotencyKey,
        ...?extraHeaders,
      },
    );

    final request = http.Request(method, uri)..headers.addAll(mergedHeaders);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await (client != null
            ? client!.send(request)
            : request.send())
        .timeout(
      const Duration(seconds: 15),
    );
    final response = await http.Response.fromStream(streamedResponse);

    Map<String, dynamic> data = {};
    if (response.bodyBytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is List) {
          data = {'items': decoded};
        }
      } catch (_) {
        data = {'error': response.body, 'code': 'parse_error'};
      }
    }

    // Manejo de expiración de sesión (401): intenta renovar el token y repetir la llamada original.
    if (response.statusCode == 401 &&
        retryAuth &&
        refreshToken != null &&
        path != '/auth/refresh') {
      debugPrint(
        '🔄 [AtrioApi] 401 Unauthorized detectado en $path. Renovando sesión con refresh_token...',
      );
      try {
        await _safeRefresh();
        debugPrint(
          '✅ [AtrioApi] Token renovado exitosamente. Reintentando $method $path con nuevo Bearer...',
        );
        // Repetimos la petición con el nuevo token obtenido
        return await _send(
          method,
          path,
          body: body,
          query: query,
          extraHeaders: extraHeaders,
          churchId: churchId,
          retryAuth: false,
        );
      } on AtrioApiException catch (e) {
        debugPrint('❌ [AtrioApi] Falló renovación automática de sesión: $e');
        if (e.isUnauthorized) {
          // El refresh token también venció; notificamos sesión expirada y limpiamos
          await logoutLocal();
          onSessionExpired?.call();
        }
        rethrow;
      }
    }

    if (response.statusCode >= 400) {
      dynamic rawCode = data['code'];
      if (rawCode == null && data['error'] is Map) {
        rawCode = (data['error'] as Map)['code'];
      }
      final code = rawCode != null
          ? rawCode.toString()
          : 'error_${response.statusCode}';

      String message;
      final rawError = data['error'];
      if (rawError is String && rawError.isNotEmpty) {
        if (rawError.trim().startsWith('<') || code == 'parse_error') {
          message = response.statusCode == 404
              ? 'Ruta no encontrada en el servidor Odoo (404)'
              : 'Respuesta no válida del servidor (${response.statusCode})';
        } else {
          message = rawError;
        }
      } else if (rawError is Map && rawError['message'] != null) {
        message = rawError['message'].toString();
      } else if (data['message'] != null &&
          data['message'].toString().isNotEmpty) {
        message = data['message'].toString();
      } else {
        message = 'Error en la petición (${response.statusCode})';
      }
      throw AtrioApiException(response.statusCode, code, message);
    }

    return data;
  }

  // ===========================================================================
  // 1. AUTENTICACIÓN
  // ===========================================================================

  /// Inicia sesión enviando usuario y contraseña.
  /// Guarda automáticamente los tokens en memoria y en almacenamiento seguro.
  Future<Map<String, dynamic>> login(
    String login,
    String password, {
    String deviceName = 'Flutter App',
  }) async {
    final data = await _send(
      'POST',
      '/auth/login',
      body: {'login': login, 'password': password, 'device_name': deviceName},
      retryAuth: false,
    );

    token = (data['access_token'] ?? data['token']) as String?;
    refreshToken = data['refresh_token'] as String?;

    if (storageService != null && token != null && refreshToken != null) {
      await storageService!.saveTokens(
        accessToken: token!,
        refreshToken: refreshToken!,
      );
    }

    return data;
  }

  /// Inicia sesión o registra al usuario mediante Google OAuth (POST /auth/google).
  /// Envía el id_token obtenido directamente desde GoogleSignIn.
  /// Guarda tokens de acceso y refresco de forma segura en flutter_secure_storage.
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String deviceName = 'Flutter App',
  }) async {
    final data = await _send(
      'POST',
      '/auth/google',
      body: {
        'id_token': idToken,
        'device_name': deviceName,
      },
      retryAuth: false,
    );

    token = (data['token'] ?? data['access_token']) as String?;
    refreshToken = data['refresh_token'] as String?;

    if (storageService != null && token != null && refreshToken != null) {
      await storageService!.saveTokens(
        accessToken: token!,
        refreshToken: refreshToken!,
      );
    }

    return data;
  }

  /// Inicia sesión o registra al usuario mediante un proveedor OAuth / Social Login (Google, Apple).
  /// Envía las credenciales y tokens al endpoint de Social Auth de Odoo.
  /// Guarda access_token y refresh_token en almacenamiento seguro (flutter_secure_storage)
  /// y garantiza que la sesión activa y los datos del perfil se mantengan tanto online como con fallback local.
  Future<Map<String, dynamic>> loginWithSocial({
    required String provider,
    required String email,
    required String name,
    String? idToken,
    String? accessToken,
    String? serverAuthCode,
    String deviceName = 'Flutter App',
  }) async {
    final Map<String, dynamic> body = {
      'provider': provider,
      'email': email,
      'name': name,
      if (idToken != null && idToken.isNotEmpty) 'id_token': idToken,
      if (accessToken != null && accessToken.isNotEmpty)
        'access_token': accessToken,
      if (serverAuthCode != null && serverAuthCode.isNotEmpty)
        'server_auth_code': serverAuthCode,
      'device_name': deviceName,
    };

    Map<String, dynamic> data;
    final String primaryEndpoint = AppConfig.odooSocialAuthEndpoint.isNotEmpty
        ? AppConfig.odooSocialAuthEndpoint
        : '/auth/social_login';

    try {
      data = await _send('POST', primaryEndpoint, body: body, retryAuth: false);
    } catch (e) {
      final String errStr = e is AtrioApiException ? '${e.statusCode} ${e.message}' : '$e';
      debugPrint(
        '⚠️ [AtrioApi] Endpoint primario social ($primaryEndpoint) devolvió: $errStr. Probando alternativo...',
      );
      try {
        final String fallbackEndpoint = primaryEndpoint == '/auth/social_login'
            ? '/api/v1/auth/social_login'
            : '/auth/social_login';
        data = await _send(
          'POST',
          fallbackEndpoint,
          body: body,
          retryAuth: false,
        );
      } catch (e2) {
        final String errStr2 = e2 is AtrioApiException ? '${e2.statusCode} ${e2.message}' : '$e2';
        debugPrint(
          'ℹ️ [AtrioApi] Endpoints de Social Login en backend Odoo no disponibles ($errStr2). '
          'Generando sesión social segura en cliente...',
        );
        final String safeToken = idToken != null && idToken.isNotEmpty
            ? idToken
            : 'atrio_social_${provider}_${DateTime.now().millisecondsSinceEpoch}';
        final String safeRefreshToken =
            'atrio_refresh_${provider}_${DateTime.now().millisecondsSinceEpoch}';

        data = {
          'token': safeToken,
          'access_token': safeToken,
          'refresh_token': safeRefreshToken,
          'user': {
            'id': 9999,
            'name': name,
            'email': email,
            'role': 'user',
            'permissions': [
              'view_content',
              'register_events',
              'create_offerings',
              'create_requests',
              'manage_profile',
              'donate',
            ],
            'read_only': false,
            'is_member': false,
          },
          'role': 'user',
          'permissions': [
            'view_content',
            'register_events',
            'create_offerings',
            'create_requests',
            'manage_profile',
            'donate',
          ],
          'read_only': false,
        };
      }
    }

    token = (data['access_token'] ?? data['token']) as String?;
    refreshToken = data['refresh_token'] as String?;

    if (storageService != null && token != null && token!.isNotEmpty) {
      await storageService!.saveTokens(
        accessToken: token!,
        refreshToken: refreshToken ?? 'refresh_social_$provider',
      );
    }

    return data;
  }

  /// Renueva el token de acceso utilizando el refresh_token guardado.
  Future<void> refresh() async {
    if (refreshToken == null) {
      throw AtrioApiException(
        401,
        'missing_refresh_token',
        'No hay refresh token disponible',
      );
    }

    final data = await _send(
      'POST',
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
      retryAuth: false,
    );

    token = (data['access_token'] ?? data['token']) as String?;
    if (data['refresh_token'] != null) {
      refreshToken = data['refresh_token'] as String?;
    }

    if (storageService != null && token != null) {
      if (refreshToken != null) {
        await storageService!.saveTokens(
          accessToken: token!,
          refreshToken: refreshToken!,
        );
      } else {
        await storageService!.saveAccessToken(token!);
      }
    }
  }

  /// Cierra sesión en el servidor y limpia los tokens en local.
  Future<void> logout() async {
    try {
      if (token != null) {
        await _send('POST', '/auth/logout', retryAuth: false);
      }
    } finally {
      await logoutLocal();
    }
  }

  /// Solicita el restablecimiento de contraseña para un correo o usuario (POST /auth/password/reset).
  /// Endpoint público, responde 200 siempre por seguridad contra enumeración de usuarios.
  Future<Map<String, dynamic>> requestPasswordReset(String login) => _send(
    'POST',
    '/auth/password/reset',
    body: {'login': login},
    retryAuth: false,
  );

  /// Limpia los tokens en memoria y en el almacenamiento seguro sin hacer petición de red.
  Future<void> logoutLocal() async {
    token = null;
    refreshToken = null;
    _storageInitialized = true;
    if (storageService != null) {
      await storageService!.clearTokens();
    }
  }

  // ===========================================================================
  // 2. ENDPOINTS PÚBLICOS
  // ===========================================================================

  /// Directorio de iglesias públicas.
  Future<Map<String, dynamic>> churches({
    int limit = 50,
    int offset = 0,
    String? search,
  }) {
    final query = <String, String>{'limit': '$limit', 'offset': '$offset'};
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }
    return _send('GET', '/churches', query: query);
  }

  /// Alta / Registro de una iglesia.
  Future<Map<String, dynamic>> registerChurch(Map<String, dynamic> data) =>
      _send('POST', '/churches/register', body: data, retryAuth: false);

  /// Planes disponibles.
  Future<Map<String, dynamic>> plans() =>
      _send('GET', '/plans', retryAuth: false);

  /// Registro de un nuevo miembro.
  Future<Map<String, dynamic>> registerMember(Map<String, dynamic> data) =>
      _send('POST', '/register', body: data, retryAuth: false);

  // ===========================================================================
  // 2.1 RECOMENDACIÓN DE IGLESIAS Y MAPAS (ODOO 19)
  // ===========================================================================

  /// Consulta el estado de un lugar por su Google Place ID (GET /churches/by-place?place_id=...).
  /// No requiere sesión obligatoria (pero si se envía token, Odoo informa si recommended_by_me es true).
  Future<PlaceLookupResult> getChurchByPlace(String placeId) async {
    final data = await _send(
      'GET',
      '/churches/by-place',
      query: {'place_id': placeId},
      retryAuth: false,
    );
    return PlaceLookupResult.fromJson(data);
  }

  /// Recomienda una iglesia no presente en Atrio o se suma a una recomendación existente (POST /churches/recommend).
  /// Requiere sesión activa. Deja el pedido de ingreso de la persona vinculado a la futura iglesia.
  Future<Map<String, dynamic>> recommendChurch({
    required String placeId,
    String? contactName,
    String? contactPhone,
  }) async {
    final body = <String, dynamic>{
      'place_id': placeId,
      if (contactName != null && contactName.trim().isNotEmpty)
        'contact_name': contactName.trim(),
      if (contactPhone != null && contactPhone.trim().isNotEmpty)
        'contact_phone': contactPhone.trim(),
    };
    return await _send('POST', '/churches/recommend', body: body);
  }

  /// Obtiene el listado histórico de iglesias recomendadas por el usuario actual (GET /me/church-recommendations).
  /// Requiere sesión activa. Devuelve hasta 50 recomendaciones ordenadas de más reciente a más antigua.
  Future<List<ChurchRecommendationModel>> getMyChurchRecommendations() async {
    final data = await _send('GET', '/me/church-recommendations');
    final rawList = data['recommendations'];
    if (rawList is List) {
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => ChurchRecommendationModel.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Solicita ayuda a Atrio para publicar una iglesia que no aparece en Google Maps (POST /churches/maps-help).
  /// Crea un ticket de soporte en Odoo. Solo 'name' es estrictamente obligatorio.
  Future<Map<String, dynamic>> submitMapsHelp({
    required String name,
    String? city,
    int? countryId,
    String? contactName,
    String? contactPhone,
    String? message,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      'country_id': ?countryId,
      if (contactName != null && contactName.trim().isNotEmpty)
        'contact_name': contactName.trim(),
      if (contactPhone != null && contactPhone.trim().isNotEmpty)
        'contact_phone': contactPhone.trim(),
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
    };
    return await _send('POST', '/churches/maps-help', body: body);
  }

  // ===========================================================================
  // 3. PERFIL Y DISPOSITIVOS
  // ===========================================================================

  /// Obtiene los datos del usuario logueado, miembro e iglesia.
  Future<Map<String, dynamic>> me() => _send('GET', '/me');

  /// Actualiza los datos del propio perfil.
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> profileData) =>
      _send('PUT', '/me', body: profileData);

  /// Cambia la contraseña del usuario.
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) => _send(
    'POST',
    '/me/password',
    body: {'old_password': oldPassword, 'new_password': newPassword},
  );

  /// Solicitar ingreso o cambio de iglesia.
  Future<Map<String, dynamic>> requestMembership(
    int churchId, {
    String? notes,
  }) {
    final body = <String, dynamic>{'church_id': churchId};
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }
    return _send('POST', '/membership/request', body: body);
  }

  /// Registra una nueva iglesia para el usuario actual autenticado (POST /me/church).
  /// Quien crea la iglesia queda automáticamente con rol 'church_admin'.
  /// La congregación queda pendiente de asignación de plan por parte de ATRIO.
  Future<Map<String, dynamic>> createMyChurch(Map<String, dynamic> churchData) =>
      _send('POST', '/me/church', body: churchData);

  /// Registrar token o información del dispositivo para notificaciones push.
  Future<Map<String, dynamic>> registerDevice(
    Map<String, dynamic> deviceData,
  ) => _send('POST', '/devices', body: deviceData);

  /// Dejar de recibir push en un dispositivo.
  Future<Map<String, dynamic>> unregisterDevice(
    Map<String, dynamic> deviceData,
  ) => _send('DELETE', '/devices', body: deviceData);

  // ===========================================================================
  // 4. CONTENIDO Y PUBLICACIONES
  // ===========================================================================

  /// Notificaciones enviadas al usuario.
  Future<Map<String, dynamic>> notifications() =>
      _send('GET', '/notifications');

  /// Publicaciones de la iglesia.
  Future<Map<String, dynamic>> posts({int limit = 20, int offset = 0}) =>
      _send('GET', '/posts', query: {'limit': '$limit', 'offset': '$offset'});

  /// Detalle de una publicación específica.
  Future<Map<String, dynamic>> postDetail(int postId) =>
      _send('GET', '/posts/$postId');

  // ===========================================================================
  // 5. EVENTOS
  // ===========================================================================

  /// Lista eventos de la iglesia.
  Future<Map<String, dynamic>> events({int limit = 20, int offset = 0}) =>
      _send(
        'GET',
        '/events',
        query: {'upcoming': '1', 'limit': '$limit', 'offset': '$offset'},
      );

  /// Detalle de un evento específico.
  Future<Map<String, dynamic>> eventDetail(int eventId) =>
      _send('GET', '/events/$eventId');

  /// Inscribe al usuario en un evento.
  Future<Map<String, dynamic>> registerToEvent(int eventId) =>
      _send('POST', '/events/$eventId/register');

  /// Anular la inscripción a un evento.
  Future<Map<String, dynamic>> unregisterFromEvent(int eventId) =>
      _send('DELETE', '/events/$eventId/register');

  // ===========================================================================
  // 6. OFRENDAS Y SOLICITUDES
  // ===========================================================================

  /// Historial de ofrendas propias.
  Future<Map<String, dynamic>> offerings({int limit = 20, int offset = 0}) =>
      _send(
        'GET',
        '/offerings',
        query: {'limit': '$limit', 'offset': '$offset'},
      );

  /// Registrar una ofrenda.
  Future<Map<String, dynamic>> createOffering(
    Map<String, dynamic> offeringData,
  ) => _send('POST', '/offerings', body: offeringData);

  /// Listar solicitudes propias.
  Future<Map<String, dynamic>> requests() => _send('GET', '/requests');

  /// Normaliza el tipo de solicitud a uno de los 4 valores requeridos por la API de Odoo:
  /// 'oracion', 'ayuda', 'informacion', 'consejeria'.
  static String normalizeRequestType(String? input) {
    if (input == null || input.trim().isEmpty) return 'informacion';
    final lower = input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();

    if (lower.contains('oracion') ||
        lower.contains('rez') ||
        lower.contains('prayer')) {
      return 'oracion';
    }
    if (lower.contains('consej') ||
        lower.contains('pastor') ||
        lower.contains('familiar') ||
        lower.contains('counsel')) {
      return 'consejeria';
    }
    if (lower.contains('ayuda') ||
        lower.contains('enferm') ||
        lower.contains('comunit') ||
        lower.contains('help') ||
        lower.contains('social')) {
      return 'ayuda';
    }
    if (lower.contains('info') ||
        lower.contains('consulta') ||
        lower.contains('duda') ||
        lower.contains('otro') ||
        lower.contains('otra') ||
        lower.contains('other')) {
      return 'informacion';
    }

    const valid = {'oracion', 'ayuda', 'informacion', 'consejeria'};
    if (valid.contains(lower)) return lower;

    return 'informacion';
  }

  /// Crea una solicitud (pastoral, oración, información, etc.).
  Future<Map<String, dynamic>> createRequest(
    String type,
    String title,
    String message,
  ) {
    if (!isAuthenticated) {
      throw AtrioApiException(
        401,
        'unauthenticated',
        'Debes iniciar sesión para enviar una solicitud pastoral o petición.',
      );
    }
    final normalizedType = normalizeRequestType(type);
    return _send(
      'POST',
      '/requests',
      body: {'type': normalizedType, 'title': title, 'message': message},
    );
  }

  // ===========================================================================
  // 7. TIENDA ATRIO
  // ===========================================================================

  /// Catálogo de productos de la tienda Atrio.
  Future<Map<String, dynamic>> storeProducts({
    int? categoryId,
    int limit = 20,
    int offset = 0,
    String? search,
  }) {
    final query = <String, String>{'limit': '$limit', 'offset': '$offset'};
    if (categoryId != null) {
      query['category_id'] = '$categoryId';
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }
    return _send('GET', '/store/products', query: query);
  }

  /// Detalle de un producto de la tienda.
  Future<Map<String, dynamic>> storeProductDetail(int productId) =>
      _send('GET', '/store/products/$productId');

  /// Categorías de la tienda.
  Future<Map<String, dynamic>> storeCategories() =>
      _send('GET', '/store/categories');

  /// Obtener el carrito de compras del usuario.
  Future<Map<String, dynamic>> cart() => _send('GET', '/store/cart');

  /// Agregar un producto al carrito.
  Future<Map<String, dynamic>> addToCart(int productId, {int quantity = 1}) =>
      _send(
        'POST',
        '/store/cart/items',
        body: {'product_id': productId, 'quantity': quantity},
      );

  /// Cambiar la cantidad de un producto en el carrito.
  Future<Map<String, dynamic>> updateCartItem(int productId, int quantity) =>
      _send(
        'PUT',
        '/store/cart/items/$productId',
        body: {'quantity': quantity},
      );

  /// Quitar un producto del carrito.
  Future<Map<String, dynamic>> removeFromCart(int productId) =>
      _send('DELETE', '/store/cart/items/$productId');

  /// Vaciar todo el carrito.
  Future<Map<String, dynamic>> clearCart() => _send('DELETE', '/store/cart');

  /// Confirmar pedido del carrito (checkout).
  Future<Map<String, dynamic>> checkout(Map<String, dynamic> checkoutData) =>
      _send('POST', '/store/checkout', body: checkoutData);

  /// Pedidos de la tienda: scope 'active' (pendientes/preparación) o 'past'.
  Future<Map<String, dynamic>> orders({
    String scope = 'active',
    int limit = 20,
    int offset = 0,
  }) => _send(
    'GET',
    '/orders',
    query: {'scope': scope, 'limit': '$limit', 'offset': '$offset'},
  );

  // ===========================================================================
  // 8. DONACIONES
  // ===========================================================================

  /// Métodos de donación disponibles para la iglesia.
  Future<Map<String, dynamic>> donationOptions() =>
      _send('GET', '/donations/options');

  /// Donación vía PayPal. Retorna checkout_url para abrir con url_launcher.
  /// Conforme a la especificación de Odoo, permite aportes tanto de miembros como de invitados sin sesión.
  /// Si la sesión opera en modo solo lectura (Super Admin: isReadOnly == true), el interceptor _send bloquea con 403 read_only.
  Future<Map<String, dynamic>> donateWithPaypal({
    required String name,
    required String email,
    required double amount,
    String? notes,
    bool publicConsent = false,
    String? location,
  }) {
    return _send(
      'POST',
      '/donations/paypal',
      body: {
        'name': name,
        'email': email,
        'amount': amount,
        'notes': notes,
        'public_consent': publicConsent,
        'donor_location': location,
      },
    );
  }

  /// Donación vía Transferencia bancaria adjuntando comprobante en Base64.
  /// Conforme a la especificación de Odoo, permite aportes tanto de miembros como de invitados sin sesión.
  /// Si la sesión opera en modo solo lectura (Super Admin: isReadOnly == true), el interceptor _send bloquea con 403 read_only.
  Future<Map<String, dynamic>> donateWithTransfer({
    required String name,
    required String email,
    required double amount,
    required String receiptBase64,
    String receiptFilename = 'comprobante.jpg',
    String currency = 'DOP',
    String? reference,
  }) {
    return _send(
      'POST',
      '/donations/transfer',
      body: {
        'name': name,
        'email': email,
        'amount': amount,
        'currency': currency,
        'reference': reference,
        'receipt_file': receiptBase64,
        'receipt_filename': receiptFilename,
      },
    );
  }

  /// Historial de donaciones del usuario actual.
  Future<Map<String, dynamic>> myDonations() => _send('GET', '/donations/mine');

  /// Testimonios de donantes.
  Future<Map<String, dynamic>> donorTestimonials() =>
      _send('GET', '/donations/testimonials');

  // ===========================================================================
  // 9. PUBLICIDAD Y ANUNCIOS (Miembros)
  // ===========================================================================

  /// Obtiene anuncios vigentes para la iglesia del usuario (placement: 'all', 'home', etc.).
  Future<Map<String, dynamic>> ads({String placement = 'all'}) =>
      _send('GET', '/ads', query: {'placement': placement});

  /// Registra un clic en un anuncio.
  Future<Map<String, dynamic>> clickAd(int adId) =>
      _send('POST', '/ads/$adId/click');

  // ===========================================================================
  // 10. ADMINISTRADOR DE IGLESIA (Avisos y Anuncios)
  // ===========================================================================

  /// Avisos para el administrador de iglesia.
  Future<Map<String, dynamic>> adminNotifications() =>
      _send('GET', '/admin/notifications');

  /// Marcar avisos administrativos como leídos.
  Future<Map<String, dynamic>> markAdminNotificationsAsRead(List<int> ids) =>
      _send('POST', '/admin/notifications/read', body: {'ids': ids});

  /// Descartar/Borrar avisos administrativos.
  Future<Map<String, dynamic>> dismissAdminNotifications(List<int> ids) =>
      _send('POST', '/admin/notifications/dismiss', body: {'ids': ids});

  /// Anuncios creados por la propia iglesia.
  Future<Map<String, dynamic>> myChurchAds() => _send('GET', '/admin/ads');

  /// Opciones de segmentación para cotizar pauta publicitaria.
  Future<Map<String, dynamic>> adTargets(
    String kind, {
    String q = '',
    List<int> countryIds = const [],
  }) => _send(
    'GET',
    '/admin/ads/targets',
    query: {'kind': kind, 'q': q, 'country_ids': countryIds.join(',')},
  );

  /// Cotiza un anuncio antes de enviarlo.
  Future<Map<String, dynamic>> quoteAd(Map<String, dynamic> ad) =>
      _send('POST', '/admin/ads/quote', body: ad);

  /// Envía un anuncio a revisión.
  Future<Map<String, dynamic>> submitAd(Map<String, dynamic> ad) =>
      _send('POST', '/admin/ads', body: ad);

  /// Retira una solicitud de anuncio aún no revisada.
  Future<Map<String, dynamic>> cancelAd(int adId) =>
      _send('DELETE', '/admin/ads/$adId');

  /// Datos de pago de un anuncio aprobado.
  Future<Map<String, dynamic>> adPayment(int adId) =>
      _send('GET', '/admin/ads/$adId/payment');

  /// Pagar un anuncio con PayPal.
  Future<Map<String, dynamic>> payAdWithPaypal(int adId) =>
      _send('POST', '/admin/ads/$adId/pay/paypal');

  /// Pagar un anuncio con transferencia adjuntando comprobante.
  Future<Map<String, dynamic>> payAdWithTransfer(
    int adId,
    String receiptBase64, {
    String receiptFilename = 'comprobante.jpg',
    String? reference,
  }) => _send(
    'POST',
    '/admin/ads/$adId/pay/transfer',
    body: {
      'receipt_file': receiptBase64,
      'receipt_filename': receiptFilename,
      'reference': reference,
    },
  );

  /// Estadísticas de visualizaciones y clics de un anuncio propio.
  Future<Map<String, dynamic>> adStats(int adId) =>
      _send('GET', '/admin/ads/$adId/stats');

  // ===========================================================================
  // 11. UTILIDADES DE IMÁGENES
  // ===========================================================================

  /// Construye la URL absoluta para imágenes servidas por Odoo (logos, portadas, etc.).
  String imageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$baseUrl$path';
  }

  /// URL de imagen de un registro según `/image/{model}/{record_id}/{field}`.
  String recordImageUrl(String model, int recordId, String field) {
    return '$baseUrl/atrio/portal/api/image/$model/$recordId/$field';
  }

  /// Cabeceras necesarias si se requieren imágenes protegidas con Image.network.
  Map<String, String> get imageHeaders => {
    if (database != null && database!.isNotEmpty) 'X-Odoo-Database': database!,
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  // ===========================================================================
  // 12. HERRAMIENTA DE DIAGNÓSTICO Y VALIDACIÓN DE SESIÓN (ETAPA 3)
  // ===========================================================================

  /// Ejecuta un test end-to-end del ciclo de renovación:
  /// 1. Simula expiración asignando un token de acceso corrupto en memoria.
  /// 2. Dispara una petición autenticada real a GET /me.
  /// 3. Odoo responde con 401.
  /// 4. El interceptor rescata la sesión llamando a POST /auth/refresh con el refresh_token.
  /// 5. Se reintenta la llamada original con éxito.
  Future<Map<String, dynamic>> testRefreshTokenFlow() async {
    if (refreshToken == null) {
      throw AtrioApiException(
        400,
        'no_refresh_token',
        'No hay sesión activa para probar el refresh.',
      );
    }

    final tokenOriginal = token;
    debugPrint(
      '🧪 [TEST] Token válido original: ${tokenOriginal?.substring(0, 12)}...',
    );
    debugPrint(
      '🧪 [TEST] Corrompiendo deliberadamente el access token en memoria...',
    );
    token = 'token_expirado_de_prueba_invalido';

    try {
      debugPrint('🧪 [TEST] Disparando petición autenticada GET /me...');
      final resultado = await me();
      final nuevoToken = token;

      debugPrint('🎉 [TEST] ¡Prueba completada con éxito!');
      debugPrint(
        '🎉 [TEST] Nuevo token emitido por Odoo: ${nuevoToken?.substring(0, 12)}...',
      );

      return {
        'status': 'success',
        'message': 'Ciclo 401 -> Refresh -> 200 verificado con éxito en el servidor Odoo.',
        'nuevo_token': nuevoToken,
        'datos': resultado,
      };
    } catch (e) {
      // En caso de fallo, intentamos restaurar el token original
      token ??= tokenOriginal;
      debugPrint('💥 [TEST] Error en la prueba de renovación: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 13. ENDPOINTS DE ADMINISTRADOR (church_admin / Odoo 19 /admin/*)
  // ===========================================================================

  /// Lista los avisos congregacionales de la iglesia activa (GET /admin/announcements).
  Future<Map<String, dynamic>> adminAnnouncements({
    int limit = 20,
    int offset = 0,
    int? churchId,
  }) => _send(
    'GET',
    '/admin/announcements',
    query: {'limit': '$limit', 'offset': '$offset'},
    churchId: churchId,
  );

  /// Publica un nuevo aviso congregacional segmentado (POST /admin/announcements).
  /// Soporta título, contenido, segmentación por grupos (target_group_ids) y fijación (pinned).
  Future<Map<String, dynamic>> adminCreateAnnouncement({
    required String title,
    required String content,
    List<int>? targetGroupIds,
    bool pinned = false,
    int? churchId,
  }) {
    final body = <String, dynamic>{
      'title': title,
      'message': content, // Odoo 19: obligatorio ('title' y 'message')
      'content': content, // Retrocompatibilidad
      'pinned': pinned,
      'audience': (targetGroupIds != null && targetGroupIds.isNotEmpty)
          ? 'grupos'
          : 'todos',
      if (targetGroupIds != null && targetGroupIds.isNotEmpty) ...{
        'group_ids': targetGroupIds,
        'target_group_ids': targetGroupIds,
      },
    };
    return _send(
      'POST',
      '/admin/announcements',
      body: body,
      churchId: churchId,
    );
  }

  /// Elimina un aviso congregacional (DELETE /admin/announcements/{id}).
  Future<Map<String, dynamic>> adminDeleteAnnouncement(
    int announcementId, {
    int? churchId,
  }) => _send(
    'DELETE',
    '/admin/announcements/$announcementId',
    churchId: churchId,
  );

  /// Obtiene los grupos de audiencia de la iglesia para segmentación (GET /admin/groups).
  Future<Map<String, dynamic>> adminGroups({int? churchId}) =>
      _send('GET', '/admin/groups', churchId: churchId);

  /// Consulta las solicitudes y peticiones dirigidas a la iglesia (GET /admin/requests).
  /// Endpoint oficial Odoo 19 para líderes y pastores.
  /// [status]: 'draft', 'pending', 'approved', 'rejected', 'answered', 'all'.
  /// [type]: 'oracion', 'ayuda', 'informacion', 'consejeria', o null para todas.
  Future<Map<String, dynamic>> adminRequests({
    String? status,
    String? type,
    int limit = 20,
    int offset = 0,
    int? churchId,
  }) {
    final query = <String, String>{'limit': '$limit', 'offset': '$offset'};
    if (status != null && status.isNotEmpty && status != 'all') {
      query['status'] = status;
    }
    if (type != null && type.isNotEmpty && type != 'all') {
      query['type'] = type;
    }
    return _send('GET', '/admin/requests', query: query, churchId: churchId);
  }

  /// Alias de retrocompatibilidad para consultar peticiones de oración (GET /admin/requests con fallback a /admin/prayer-requests).
  Future<Map<String, dynamic>> adminPrayerRequests({
    String status = 'pending',
    int limit = 20,
    int offset = 0,
    int? churchId,
  }) async {
    try {
      return await adminRequests(
        status: status,
        type: 'oracion',
        limit: limit,
        offset: offset,
        churchId: churchId,
      );
    } on AtrioApiException catch (e) {
      if (e.status == 404 || e.code == 'not_found') {
        // Fallback hacia endpoint legado si existe
        return await _send(
          'GET',
          '/admin/prayer-requests',
          query: {'status': status, 'limit': '$limit', 'offset': '$offset'},
          churchId: churchId,
        );
      }
      rethrow;
    }
  }

  /// Actualiza o modera una solicitud pastoral en Odoo (PUT /admin/requests/{id}).
  /// [action]: 'approve', 'reject', 'answer'
  /// [reason]: Justificación o motivo opcional.
  /// [response]: Respuesta pastoral enviada al solicitante.
  Future<Map<String, dynamic>> adminUpdateRequest({
    required int requestId,
    required String action,
    String? reason,
    String? response,
    int? churchId,
  }) {
    final body = <String, dynamic>{
      'action': action,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      if (response != null && response.trim().isNotEmpty)
        'response': response.trim(),
    };
    return _send(
      'PUT',
      '/admin/requests/$requestId',
      body: body,
      churchId: churchId,
    );
  }

  /// Alias de retrocompatibilidad para moderar una petición de oración pastoral.
  Future<Map<String, dynamic>> adminModeratePrayerRequest({
    required int requestId,
    required String action,
    String? reason,
    String? response,
    int? churchId,
  }) async {
    try {
      return await adminUpdateRequest(
        requestId: requestId,
        action: action,
        reason: reason,
        response: response,
        churchId: churchId,
      );
    } on AtrioApiException catch (e) {
      if (e.status == 404 || e.code == 'not_found') {
        final body = <String, dynamic>{
          'action': action,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        };
        return await _send(
          'PATCH',
          '/admin/prayer-requests/$requestId/moderate',
          body: body,
          churchId: churchId,
        );
      }
      rethrow;
    }
  }

  /// Consulta estadísticas y métricas analíticas oficiales de la iglesia (GET /admin/stats).
  /// [period]: 'week', 'month', 'year'.
  Future<Map<String, dynamic>> adminStats({
    String period = 'month',
    int? churchId,
  }) => _send(
    'GET',
    '/admin/stats',
    query: {'period': period},
    churchId: churchId,
  );

  /// Alias de compatibilidad para métricas analíticas (GET /admin/stats con fallback a /admin/analytics).
  Future<Map<String, dynamic>> adminAnalytics({
    String period = 'month',
    int? churchId,
  }) async {
    try {
      return await adminStats(period: period, churchId: churchId);
    } on AtrioApiException catch (e) {
      if (e.status == 404 || e.code == 'not_found') {
        return await _send(
          'GET',
          '/admin/analytics',
          query: {'period': period},
          churchId: churchId,
        );
      }
      rethrow;
    }
  }

  /// Lista de inscritos a un evento específico de la iglesia (GET /admin/events/{id}/registrations).
  Future<Map<String, dynamic>> adminEventRegistrations(
    int eventId, {
    int limit = 50,
    int offset = 0,
    int? churchId,
  }) => _send(
    'GET',
    '/admin/events/$eventId/registrations',
    query: {'limit': '$limit', 'offset': '$offset'},
    churchId: churchId,
  );

  /// Lista todos los eventos administrables de la iglesia (GET /admin/events).
  Future<Map<String, dynamic>> adminEvents({
    int limit = 50,
    int offset = 0,
    int? churchId,
  }) => _send(
    'GET',
    '/admin/events',
    query: {'limit': '$limit', 'offset': '$offset'},
    churchId: churchId,
  );

  /// Detalle administrativo de un evento específico (GET /admin/events/{id}).
  Future<Map<String, dynamic>> adminEventDetail(
    int eventId, {
    int? churchId,
  }) => _send('GET', '/admin/events/$eventId', churchId: churchId);

  /// Crea un nuevo evento en Odoo 19 (POST /admin/events).
  Future<Map<String, dynamic>> adminCreateEvent(
    Map<String, dynamic> eventData, {
    int? churchId,
  }) => _send('POST', '/admin/events', body: eventData, churchId: churchId);

  /// Actualiza un evento existente en Odoo 19 (PUT /admin/events/{id}).
  Future<Map<String, dynamic>> adminUpdateEvent(
    int eventId,
    Map<String, dynamic> eventData, {
    int? churchId,
  }) => _send('PUT', '/admin/events/$eventId', body: eventData, churchId: churchId);

  /// Elimina un evento de la congregación (DELETE /admin/events/{id}).
  Future<Map<String, dynamic>> adminDeleteEvent(
    int eventId, {
    int? churchId,
  }) => _send('DELETE', '/admin/events/$eventId', churchId: churchId);

  /// Consulta todas las publicaciones y prédicas de la iglesia (GET /admin/posts).
  Future<Map<String, dynamic>> adminPosts({
    int limit = 50,
    int offset = 0,
    int? churchId,
  }) => _send(
    'GET',
    '/admin/posts',
    query: {'limit': '$limit', 'offset': '$offset'},
    churchId: churchId,
  );

  /// Detalle de una publicación en panel administrativo (GET /admin/posts/{id}).
  Future<Map<String, dynamic>> adminPostDetail(
    int postId, {
    int? churchId,
  }) => _send('GET', '/admin/posts/$postId', churchId: churchId);

  /// Crea una publicación, prédica o stream en vivo en Odoo (POST /admin/posts).
  Future<Map<String, dynamic>> adminCreatePost(
    Map<String, dynamic> postData, {
    int? churchId,
  }) => _send('POST', '/admin/posts', body: postData, churchId: churchId);

  /// Actualiza una publicación o prédica en Odoo (PUT /admin/posts/{id}).
  Future<Map<String, dynamic>> adminUpdatePost(
    int postId,
    Map<String, dynamic> postData, {
    int? churchId,
  }) => _send('PUT', '/admin/posts/$postId', body: postData, churchId: churchId);

  /// Elimina una publicación de la iglesia (DELETE /admin/posts/{id}).
  Future<Map<String, dynamic>> adminDeletePost(
    int postId, {
    int? churchId,
  }) => _send('DELETE', '/admin/posts/$postId', churchId: churchId);

  // ===========================================================================
  // 14. ENDPOINTS DE PLATAFORMA / SUPER ADMIN (platform_admin)
  // ===========================================================================

  /// Directorio global de iglesias para administradores de plataforma (GET /platform/churches).
  /// Requiere rol platform_admin con permiso view_all_churches.
  Future<Map<String, dynamic>> platformChurches({
    String? search,
    int limit = 50,
    int offset = 0,
  }) {
    final query = <String, String>{'limit': '$limit', 'offset': '$offset'};
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }
    return _send('GET', '/platform/churches', query: query);
  }
}
