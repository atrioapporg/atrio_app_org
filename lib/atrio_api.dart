import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:atrio/servicios/token_storage_service.dart';

/// Excepción personalizada para capturar y clasificar los errores devueltos por la API de Odoo.
/// Permite reaccionar adecuadamente a códigos HTTP y strings de error normalizados (ej: 'invalid_credentials').
class AtrioApiException implements Exception {
  final int status;
  final String code;
  final String message;

  AtrioApiException(this.status, this.code, this.message);

  bool get isUnauthorized => status == 401;
  bool get isForbidden => status == 403;
  bool get isNotFound => status == 404;
  bool get isConflict => status == 409;
  bool get isServerError => status >= 500;

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

  AtrioApi({
    required this.baseUrl,
    this.database,
    this.token,
    this.refreshToken,
    this.storageService,
    this.onSessionExpired,
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
  Map<String, String> _buildHeaders(String path) {
    final isPublicAuth = path == '/auth/login' || path == '/auth/refresh';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (database != null && database!.isNotEmpty)
        'X-Odoo-Database': database!,
      if (!isPublicAuth && token != null && token!.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

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

  /// Método interno de transporte HTTP con soporte de reintento automático por expiración de token (401).
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool retryAuth = true,
  }) async {
    await _ensureStorageLoaded();

    final uri = Uri.parse('$baseUrl/atrio/portal/api$path')
        .replace(queryParameters: query);

    final request = http.Request(method, uri)
      ..headers.addAll(_buildHeaders(path));
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await request.send();
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

    // Si el servidor responde con un código de error (400-599), disparamos la excepción tipada.
    if (response.statusCode >= 400) {
      final code = data['code'] as String? ?? 'error_${response.statusCode}';
      final message =
          data['error'] as String? ??
          'Error en la petición (${response.statusCode})';
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
  Future<Map<String, dynamic>> donateWithPaypal({
    required String name,
    required String email,
    required double amount,
    String? notes,
    bool publicConsent = false,
    String? location,
  }) => _send(
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

  /// Donación vía Transferencia bancaria adjuntando comprobante en Base64.
  Future<Map<String, dynamic>> donateWithTransfer({
    required String name,
    required String email,
    required double amount,
    required String receiptBase64,
    String receiptFilename = 'comprobante.jpg',
    String currency = 'DOP',
    String? reference,
  }) => _send(
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
}
