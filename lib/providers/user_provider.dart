import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/data/app_config.dart';
import 'package:atrio/modelos/user_model.dart';
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
        notifyListeners();
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

      // Sincronizar flag en SharedPreferences para compatibilidad de navegación
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('user_email', _currentUser!.email);
      await prefs.setString('user_name', _currentUser!.nombre);

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
      await _api.logout();
    } catch (e) {
      debugPrint('[UserProvider] Error al revocar token en servidor: $e');
      await _api.logoutLocal();
    } finally {
      _currentUser = null;
      _errorMessage = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
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
      _currentUser = UserModel(
        id: _currentUser!.id,
        nombre: nombre,
        email: email,
        telefono: telefono.isNotEmpty ? telefono : null,
        iglesiaActual: iglesiaActual,
        fechaRegistro: _currentUser!.fechaRegistro,
        avatarIniciales: nombre.isNotEmpty
            ? nombre.trim()[0].toUpperCase()
            : 'U',
        esMiembroVerificado: _currentUser!.esMiembroVerificado,
        estadisticas: _currentUser!.estadisticas,
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
      default:
        return e.message.isNotEmpty ? e.message : 'Error en el servidor (${e.status}).';
    }
  }
}
