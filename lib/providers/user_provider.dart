import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/data/app_config.dart';
import 'package:atrio/data/atrio_database_helper.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/servicios/device_notification_service.dart';
import 'package:atrio/servicios/token_storage_service.dart';

/// Provider central para la gestión del usuario autenticado,
/// persistencia de sesión segura y comunicación con la API de Odoo.
class UserProvider extends ChangeNotifier {
  final AtrioApi _api;
  final TokenStorageService _storageService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserProvider({AtrioApi? api, TokenStorageService? storageService})
      : _storageService = storageService ?? TokenStorageService(),
        _api = api ??
            AtrioApi(
              baseUrl: AppConfig.odooBaseUrl,
              database: AppConfig.odooDatabase.isNotEmpty ? AppConfig.odooDatabase : null,
              storageService: storageService ?? TokenStorageService(),
            ) {
    // Configurar callback cuando la sesión expire definitivamente
    _api.onSessionExpired = () {
      _currentUser = null;
      _errorMessage = 'Tu sesión ha expirado. Por favor, ingresa de nuevo.';
      notifyListeners();
    };

    // Auto-restaurar sesión desde almacenamiento seguro
    _iniciarSesionPersistente();
  }

  Future<void> _iniciarSesionPersistente() async {
    try {
      await _api.initFromStorage();
      if (_api.isAuthenticated && _currentUser == null) {
        final meData = await _api.me();
        _currentUser = UserModel.fromOdooJson(meData);
        _api.defaultChurchId = _currentUser?.iglesiaId;
        _api.isReadOnly = _currentUser?.isReadOnly ?? false;
        notifyListeners();
        // Sincronizar token del dispositivo con Odoo en segundo plano
        DeviceNotificationService.instance.registerDeviceWithBackend(_api);
      }
    } catch (e) {
      debugPrint('[UserProvider] Restauración pasiva de sesión: $e');
    }
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _api.isAuthenticated && _currentUser != null;

  /// Acceso al cliente HTTP de Odoo con cabeceras y token configurados.
  AtrioApi get api => _api;

  /// Acceso al servicio de tokens para consultas o depuración.
  TokenStorageService get storageService => _storageService;

  // ===========================================================================
  // RBAC & PERMISOS GRANULARES (ETAPA 1)
  // ===========================================================================

  UserRole get role => _currentUser?.role ?? UserRole.user;
  Set<String> get permissions => _currentUser?.permissions ?? const {};
  bool get isReadOnly => _currentUser?.isReadOnly ?? false;
  bool get isChurchAdmin => _currentUser?.isChurchAdmin ?? false;
  bool get isPlatformAdmin => _currentUser?.isPlatformAdmin ?? false;
  bool get isMember => _currentUser?.isMember ?? false;
  bool get canWrite => _currentUser?.canWrite ?? false;

  /// Indica si el usuario tiene una iglesia activa asignada en Odoo.
  bool get hasChurchAssigned =>
      _currentUser?.iglesiaId != null && _currentUser!.iglesiaId! > 0;

  /// Valida si el usuario está plenamente habilitado para realizar donaciones y ofrendas.
  /// No permitido para:
  /// - Modo invitado (no autenticado).
  /// - Modo solo lectura (auditoría / platform_admin con read_only activo).
  /// - Rol 'user' (usuario recién registrado pendiente de asignación o aprobación de membresía).
  /// - Usuarios sin congregación asignada activa.
  bool get canDonate =>
      isAuthenticated &&
      !isReadOnly &&
      (role == UserRole.member || role == UserRole.churchAdmin) &&
      hasChurchAssigned;

  /// Valida si el usuario actual tiene un permiso específico.
  bool hasPermission(String permission) =>
      _currentUser?.hasPermission(permission) ?? false;

  /// Valida si el usuario cuenta con al menos uno de los permisos indicados.
  bool hasAnyPermission(Iterable<String> perms) =>
      perms.any((p) => hasPermission(p));

  /// Valida si el usuario cuenta con todos los permisos indicados.
  bool hasAllPermissions(Iterable<String> perms) =>
      perms.every((p) => hasPermission(p));

  /// Asigna directamente el usuario actual para pruebas unitarias y de widgets.
  @visibleForTesting
  void setCurrentUserForTesting(UserModel? user) {
    _currentUser = user;
    _api.defaultChurchId = user?.iglesiaId;
    _api.isReadOnly = user?.isReadOnly ?? false;
    notifyListeners();
  }

  /// Refresca el perfil del usuario actual consultando GET /me a Odoo.
  Future<void> refreshUserProfile() async {
    if (!_api.isAuthenticated) return;
    try {
      final meData = await _api.me();
      _currentUser = UserModel.fromOdooJson(meData);
      _api.defaultChurchId = _currentUser?.iglesiaId;
      _api.isReadOnly = _currentUser?.isReadOnly ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('[UserProvider] Error al refrescar perfil: $e');
    }
  }

  // ===========================================================================
  // FLUJO DE AUTENTICACIÓN CON ODOO (ETAPA 2)
  // ===========================================================================

  /// Inicia sesión enviando usuario/correo y contraseña a Odoo (POST /auth/login).
  /// Guarda tokens de forma segura y puebla el modelo de usuario actual.
  Future<bool> login(
    String email,
    String password, {
    String deviceName = 'Flutter App',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.login(
        email.trim(),
        password,
        deviceName: deviceName,
      );

      // Crear el modelo de usuario a partir del payload completo de Odoo
      _currentUser = UserModel.fromOdooJson(data);
      _api.defaultChurchId = _currentUser?.iglesiaId;
      _api.isReadOnly = _currentUser?.isReadOnly ?? false;

      // Sincronizar flag en SharedPreferences para compatibilidad de navegación
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('user_email', _currentUser!.email);
      await prefs.setString('user_name', _currentUser!.nombre);

      // Registrar dispositivo en Odoo para recibir notificaciones push
      DeviceNotificationService.instance.registerDeviceWithBackend(_api);

      _isLoading = false;
      notifyListeners();
      return true;
    } on AtrioApiException catch (e) {
      _isLoading = false;
      _errorMessage = _traducirErrorOdoo(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error de conexión: Por favor verifica tu conexión a internet.';
      notifyListeners();
      return false;
    }
  }

  /// Intenta restaurar la sesión previa desde el almacenamiento seguro de tokens.
  /// Si hay token, consulta /me para refrescar el perfil del usuario.
  Future<bool> tryAutoLogin() async {
    try {
      await _api.initFromStorage();
      if (!_api.isAuthenticated) {
        return false;
      }

      // El token existe en el almacenamiento seguro, obtenemos el perfil del servidor
      final meData = await _api.me();
      _currentUser = UserModel.fromOdooJson(meData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Sincronizar token del dispositivo con Odoo
      DeviceNotificationService.instance.registerDeviceWithBackend(_api);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[UserProvider] No se pudo restaurar la sesión automáticamente: $e');
      await logout();
      return false;
    }
  }

  /// Cierra sesión en Odoo (POST /auth/logout), elimina los tokens seguros y limpia el estado local.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Desregistrar dispositivo de Odoo para no recibir alertas de otra cuenta
      await DeviceNotificationService.instance.unregisterDeviceFromBackend(_api);
      await _api.logout();
    } catch (e) {
      debugPrint('[UserProvider] Error al revocar token en servidor: $e');
      await _api.logoutLocal();
    } finally {
      _currentUser = null;
      _api.defaultChurchId = null;
      _api.isReadOnly = false;
      _errorMessage = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('user_email');
        await prefs.remove('user_name');
        await AtrioDatabaseHelper.instance.eliminarUsuarioYDatos();
      } catch (e) {
        debugPrint('[UserProvider] Error limpiando datos locales en logout: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ejecuta la prueba de renovación de tokens de la Etapa 3:
  /// Corrompe el access token en memoria, envía una petición a Odoo,
  /// Odoo devuelve 401, se activa el refresh token automático y se recupera la sesión con 200.
  Future<Map<String, dynamic>> testRefreshTokenFlow() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.testRefreshTokenFlow();
      if (res['datos'] != null) {
        _currentUser = UserModel.fromOdooJson(res['datos'] as Map<String, dynamic>);
      }
      _isLoading = false;
      notifyListeners();
      return res;
    } on AtrioApiException catch (e) {
      _isLoading = false;
      _errorMessage = _traducirErrorOdoo(e);
      notifyListeners();
      rethrow;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error ejecutando prueba de refresh: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Limpia la sesión únicamente en memoria local (compatibilidad).
  void clearSession() {
    _currentUser = null;
    _api.logoutLocal();
    notifyListeners();
  }

  // ===========================================================================
  // MÉTODOS EXISTENTES Y COMPATIBILIDAD
  // ===========================================================================

  /// Función para simular una petición a la API (o leer el archivo falso)
  Future<void> loadFakeUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 1500));
      final String jsonString = await rootBundle.loadString(
        'assets/json/perfil.json',
      );
      final Map<String, dynamic> jsonMap =
          jsonDecode(jsonString) as Map<String, dynamic>;
      _currentUser = UserModel.fromJson(jsonMap);
    } catch (error) {
      _errorMessage = 'Error al cargar datos de perfil: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Método para actualizar los datos locales en memoria
  void updateUserProfile({
    required String nombre,
    required String email,
    required String telefono,
    required String iglesiaActual,
  }) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        nombre: nombre,
        email: email,
        telefono: telefono.isNotEmpty ? telefono : null,
        iglesiaActual: iglesiaActual,
        avatarIniciales: nombre.isNotEmpty
            ? nombre.trim()[0].toUpperCase()
            : 'U',
      );
      notifyListeners();
    }
  }

  /// Traduce los códigos de error estándar de Odoo a mensajes claros y amigables.
  String _traducirErrorOdoo(AtrioApiException e) {
    switch (e.code) {
      case 'invalid_credentials':
      case 'wrong_password':
        return 'Usuario o contraseña incorrectos. Verifica tus credenciales.';
      case 'missing_fields':
        return 'Por favor completa todos los campos requeridos.';
      case 'invalid_email':
        return 'El formato del correo electrónico no es válido.';
      case 'invalid_token':
      case 'invalid_refresh_token':
      case 'unauthorized':
        return 'Tu sesión ha caducado. Vuelve a iniciar sesión.';
      case 'forbidden':
      case 'not_church_admin':
        return 'No tienes permisos suficientes para realizar esta acción.';
      case 'no_church':
        return 'Tu usuario no tiene una iglesia asociada en el sistema.';
      case 'membership_pending':
        return 'Tu solicitud de membresía aún está pendiente de aprobación.';
      case 'subscription_required':
        return 'Esta función requiere una suscripción activa de tu iglesia.';
      case 'validation_error':
        return e.message.isNotEmpty
            ? e.message
            : 'Error de validación en los datos enviados.';
      case 'content_unavailable':
        return 'Este contenido ya no está disponible.';
      case 'read_only':
        return 'Acción no permitida: Modo de solo lectura activo.';
      case 'church_required':
        return 'Se requiere especificar una iglesia para esta operación.';
      default:
        return e.message.isNotEmpty ? e.message : 'Error en el servidor (${e.status}).';
    }
  }
}
