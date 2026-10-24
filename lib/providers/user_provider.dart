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
  Map<String, dynamic>? _rawMeData;
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
      _rawMeData = null;
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
        try {
          final meData = await _api.me();
          _rawMeData = meData;
          _currentUser = UserModel.fromOdooJson(meData);
        } catch (meError) {
          debugPrint(
            'ℹ️ [UserProvider] /me no disponible en restauración: $meError. Cargando desde SQLite...',
          );
          final localData = await AtrioDatabaseHelper.instance.getUsuario();
          if (localData != null &&
              ((localData['email'] as String?)?.isNotEmpty == true ||
                  (localData['nombre'] as String?)?.isNotEmpty == true)) {
            final String name = (localData['nombre'] as String?) ?? 'Usuario';
            _currentUser = UserModel(
              id: 0,
              nombre: name,
              email: (localData['email'] as String?) ?? '',
              telefono: localData['celular'] as String?,
              iglesiaActual: (localData['iglesia_nombre'] as String?) ??
                  'Sin iglesia seleccionada',
              fechaRegistro: (localData['creado_en'] as String?) ?? '',
              avatarIniciales: name.trim().isNotEmpty
                  ? name.trim()[0].toUpperCase()
                  : 'U',
              esMiembroVerificado: false,
              role: UserRole.user,
              permissions: const {
                'view_content',
                'manage_profile',
                'donate',
              },
              isReadOnly: false,
            );
          }
        }
        if (_currentUser != null) {
          _api.defaultChurchId = _currentUser?.iglesiaId;
          _api.isReadOnly = _currentUser?.isReadOnly ?? false;
          notifyListeners();
          // Sincronizar token del dispositivo con Odoo en segundo plano
          DeviceNotificationService.instance.registerDeviceWithBackend(_api);
        }
      }
    } catch (e) {
      debugPrint('[UserProvider] Restauración pasiva de sesión: $e');
    }
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _currentUser != null && (_api.isAuthenticated || _api.token != null);

  /// Acceso al cliente HTTP de Odoo con cabeceras y token configurados.
  AtrioApi get api => _api;

  /// Acceso al servicio de tokens para consultas o depuración.
  TokenStorageService get storageService => _storageService;

  // ===========================================================================
  // MÁQUINA DE ESTADOS & MEMBRESÍA ODOO 19 (ETAPA 1)
  // ===========================================================================

  /// Payload JSON original recibido en la última llamada a /me o login.
  Map<String, dynamic>? get rawMeData => _rawMeData;

  /// Estado actual del flujo de navegación (máquina de estados de ATRIO).
  AppStage get currentStage {
    if (_currentUser == null) return AppStage.welcome;
    if (_rawMeData != null && _rawMeData!.isNotEmpty) {
      return resolveStage(_rawMeData);
    }
    return resolveStage({
      'role': _currentUser!.role.toOdooString(),
      'membership_status': _currentUser!.membershipStatus,
      'church': {
        'id': _currentUser!.iglesiaId,
        'has_active_subscription': _currentUser!.hasActiveSubscription,
      },
    });
  }

  /// Estado de membresía en Odoo 19 ('none', 'membership_pending', 'change_pending', etc.)
  String get membershipStatus => _currentUser?.membershipStatus ?? 'none';

  /// ID de la congregación a la que se solicitó ingreso
  int? get requestedChurchId => _currentUser?.requestedChurchId;

  /// Datos informativos de la congregación solicitada
  Map<String, dynamic>? get requestedChurchData =>
      _currentUser?.requestedChurchData;

  /// Indica si la iglesia del usuario tiene suscripción activa en ATRIO
  bool get hasActiveSubscription =>
      _currentUser?.hasActiveSubscription ?? false;

  /// Indica si el usuario está en espera de aprobación pastoral
  bool get isWaitingApproval => currentStage == AppStage.waitingApproval;

  /// Indica si la iglesia creada está pendiente de activación por el equipo de ATRIO
  bool get isChurchPendingActivation =>
      currentStage == AppStage.churchPendingActivation;

  /// Indica si el usuario debe elegir congregación o dar de alta su propia iglesia
  bool get isChooseChurch => currentStage == AppStage.chooseChurch;

  /// Verifica y refresca el estado actual del usuario con el servidor
  Future<AppStage> checkCurrentStage() async {
    if (!_api.isAuthenticated) return AppStage.welcome;
    await refreshUserProfile();
    return currentStage;
  }

  // ===========================================================================
  // RBAC & PERMISOS GRANULARES
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

  /// Valida si el usuario está plenamente habilitado para realizar ofrendas congregacionales locales.
  /// Requiere membresía activa e iglesia asignada en Odoo.
  bool get canDonate =>
      isAuthenticated &&
      !isReadOnly &&
      (role == UserRole.member || role == UserRole.churchAdmin) &&
      hasChurchAssigned;

  /// Indica si el usuario o visitante puede realizar donaciones generales a la plataforma ATRIO.
  /// Conforme a Odoo 19 (Pablo Oliveros Págs. 2 y 6), está permitido tanto para miembros como para invitados.
  /// Bloqueado exclusivamente para cuentas de auditoría en modo solo lectura (Super Admin: isReadOnly == true).
  bool get canDonateToPlatform => !isReadOnly;

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
  void setCurrentUserForTesting(
    UserModel? user, {
    Map<String, dynamic>? rawMeData,
  }) {
    _currentUser = user;
    _rawMeData = rawMeData;
    _api.defaultChurchId = user?.iglesiaId;
    _api.isReadOnly = user?.isReadOnly ?? false;
    notifyListeners();
  }

  /// Refresca el perfil del usuario actual consultando GET /me a Odoo.
  Future<void> refreshUserProfile() async {
    if (!_api.isAuthenticated) return;
    try {
      final meData = await _api.me();
      _rawMeData = meData;
      final prevRequestedChurch = _currentUser?.requestedChurchData;
      final prevRequestedId = _currentUser?.requestedChurchId;
      final prevIglesia = _currentUser?.iglesiaActual;

      _currentUser = UserModel.fromOdooJson(meData);

      // Si la membresía sigue en revisión pero el servidor no adjuntó requested_church con nombre:
      if (_currentUser != null &&
          _currentUser!.isMembershipPending &&
          (_currentUser!.requestedChurchData == null ||
              _currentUser!.requestedChurchData!['name'] == null)) {
        if (prevRequestedChurch != null) {
          _currentUser = _currentUser!.copyWith(
            requestedChurchData: prevRequestedChurch,
            requestedChurchId: prevRequestedId ?? _currentUser!.requestedChurchId,
            iglesiaActual: prevRequestedChurch['name'] as String? ??
                prevIglesia ??
                _currentUser!.iglesiaActual,
          );
        }
      }

      _api.defaultChurchId = _currentUser?.iglesiaId;
      _api.isReadOnly = _currentUser?.isReadOnly ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('[UserProvider] Error al refrescar perfil: $e');
    }
  }

  /// Registra la solicitud de ingreso a una congregación (POST /membership/request)
  /// y actualiza inmediatamente el modelo de usuario y la persistencia local.
  Future<void> solicitarMembresia(
    int churchId, {
    required String churchName,
    String? logoUrl,
  }) async {
    // 1. Persistir localmente en SQLite para disponibilidad offline
    try {
      await AtrioDatabaseHelper.instance.guardarIglesiaNombre(churchName);
    } catch (e) {
      debugPrint('[UserProvider] Error guardando iglesia en SQLite: $e');
    }

    final churchData = <String, dynamic>{
      'id': churchId,
      'name': churchName,
      if (logoUrl != null && logoUrl.isNotEmpty) 'logo_url': logoUrl,
    };

    // 2. Actualizar estado reactivo en memoria de inmediato
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        membershipStatus: 'membership_pending',
        requestedChurchId: churchId,
        requestedChurchData: churchData,
        iglesiaActual: churchName,
      );
    }

    if (_rawMeData != null) {
      _rawMeData!['membership_status'] = 'membership_pending';
      _rawMeData!['requested_church_id'] = churchId;
      _rawMeData!['requested_church'] = churchData;
    } else {
      _rawMeData = {
        'membership_status': 'membership_pending',
        'requested_church_id': churchId,
        'requested_church': churchData,
      };
    }

    notifyListeners();

    // 3. Enviar solicitud formal a la API de Odoo
    if (_api.isAuthenticated) {
      try {
        await _api.requestMembership(churchId);
      } catch (e) {
        debugPrint('[UserProvider] Error enviando requestMembership a Odoo: $e');
      }

      try {
        await refreshUserProfile();
        // Si el endpoint /me de Odoo no retornó el nombre en requested_church:
        if (_currentUser != null &&
            (_currentUser!.requestedChurchData == null ||
                _currentUser!.requestedChurchData!['name'] == null)) {
          _currentUser = _currentUser!.copyWith(
            requestedChurchData: churchData,
            iglesiaActual: churchName,
            membershipStatus: 'membership_pending',
            requestedChurchId: churchId,
          );
          notifyListeners();
        }
      } catch (e) {
        debugPrint('[UserProvider] Error refrescando tras solicitar membresía: $e');
      }
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

      _rawMeData = data;
      // Crear el modelo de usuario a partir del payload completo de Odoo
      _currentUser = UserModel.fromOdooJson(data);
      _api.defaultChurchId = _currentUser?.iglesiaId;
      _api.isReadOnly = _currentUser?.isReadOnly ?? false;

      // Sincronizar flag en SharedPreferences para compatibilidad de navegación
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('user_email', _currentUser!.email);
        await prefs.setString('user_name', _currentUser!.nombre);
      } catch (e) {
        debugPrint('[UserProvider] Advertencia guardando en SharedPreferences: $e');
      }

      // Registrar dispositivo en Odoo para recibir notificaciones push (no bloqueante)
      try {
        await DeviceNotificationService.instance.registerDeviceWithBackend(_api);
      } catch (e) {
        debugPrint('[UserProvider] Error no bloqueante al registrar dispositivo: $e');
      }

      return true;
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      return false;
    } catch (e) {
      _errorMessage = 'Error de conexión: Por favor verifica tu conexión a internet.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia sesión mediante un proveedor social (Google o Apple).
  /// Envía credenciales a Odoo vía AtrioApi, persiste tokens en almacenamiento seguro (flutter_secure_storage),
  /// puebla el UserModel en el estado global reactivo de UserProvider y sincroniza SharedPreferences y SQLite.
  Future<bool> loginWithSocial({
    required String provider,
    required String email,
    required String nombre,
    String? idToken,
    String? accessToken,
    String? serverAuthCode,
    String? iglesiaActual,
    String deviceName = 'Flutter App',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.loginWithSocial(
        provider: provider,
        email: email,
        name: nombre,
        idToken: idToken,
        accessToken: accessToken,
        serverAuthCode: serverAuthCode,
        deviceName: deviceName,
      );

      _rawMeData = data;
      UserModel user;
      try {
        user = UserModel.fromOdooJson(data);
      } catch (e) {
        debugPrint(
          '⚠️ [UserProvider] Parser de OdooJson adaptado a fallback social: $e',
        );
        user = UserModel(
          id: (data['id'] ?? data['user']?['id'] ?? 9999) as int,
          nombre: nombre,
          email: email,
          iglesiaActual: iglesiaActual ?? 'Sin iglesia seleccionada',
          fechaRegistro: DateTime.now().toIso8601String().split('T').first,
          avatarIniciales: nombre.trim().isNotEmpty
              ? nombre.trim()[0].toUpperCase()
              : 'U',
          esMiembroVerificado: false,
          role: UserRole.user,
          permissions: const {
            'view_content',
            'register_events',
            'create_offerings',
            'create_requests',
            'manage_profile',
            'donate',
          },
          isReadOnly: false,
        );
      }

      // Si tenemos una iglesia previa local o SQLite y el backend no devolvió iglesia
      if ((user.iglesiaActual.isEmpty ||
              user.iglesiaActual == 'Sin iglesia seleccionada' ||
              user.iglesiaActual == 'Iglesia Atrio') &&
          iglesiaActual != null &&
          iglesiaActual.isNotEmpty &&
          iglesiaActual != 'Sin iglesia seleccionada') {
        user = user.copyWith(iglesiaActual: iglesiaActual);
      }

      _currentUser = user;
      _api.defaultChurchId = _currentUser?.iglesiaId;
      _api.isReadOnly = _currentUser?.isReadOnly ?? false;

      // Sincronizar SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('user_email', _currentUser!.email);
        await prefs.setString('user_name', _currentUser!.nombre);
        await prefs.setString('userEmail', _currentUser!.email);
        await prefs.setString('userName', _currentUser!.nombre);
        await prefs.setString('auth_provider', provider);
      } catch (e) {
        debugPrint(
          '⚠️ [UserProvider] Advertencia guardando en SharedPreferences: $e',
        );
      }

      // Sincronizar SQLite (atrio.db)
      try {
        await AtrioDatabaseHelper.instance.guardarUsuario(<String, dynamic>{
          'nombre': _currentUser!.nombre,
          'email': _currentUser!.email,
          'celular': _currentUser!.telefono ?? '',
          'iglesia_nombre': _currentUser!.iglesiaActual,
          'creado_en': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('⚠️ [UserProvider] Advertencia guardando en SQLite: $e');
      }

      // Sincronizar token del dispositivo con Odoo (no bloqueante)
      try {
        await DeviceNotificationService.instance.registerDeviceWithBackend(_api);
      } catch (e) {
        debugPrint(
          'ℹ️ [UserProvider] Error no bloqueante al registrar dispositivo: $e',
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión con $provider: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Inicia sesión o registra usuario mediante Google Sign-In oficial (POST /auth/google).
  /// Guarda tokens en almacenamiento seguro y puebla UserModel y rawMeData.
  /// Devuelve el payload completo (que incluye data['created'] == true si es usuario nuevo) o null si falla.
  Future<Map<String, dynamic>?> loginWithGoogle({
    required String idToken,
    String deviceName = 'Flutter App',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.loginWithGoogle(
        idToken: idToken,
        deviceName: deviceName,
      );

      _rawMeData = data;
      _currentUser = UserModel.fromOdooJson(data);
      _api.defaultChurchId = _currentUser?.iglesiaId;
      _api.isReadOnly = _currentUser?.isReadOnly ?? false;

      // Sincronizar SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('user_email', _currentUser!.email);
        await prefs.setString('user_name', _currentUser!.nombre);
        await prefs.setString('userEmail', _currentUser!.email);
        await prefs.setString('userName', _currentUser!.nombre);
        await prefs.setString('auth_provider', 'google');
      } catch (e) {
        debugPrint('[UserProvider] Advertencia guardando en SharedPreferences: $e');
      }

      // Sincronizar SQLite (atrio.db)
      try {
        await AtrioDatabaseHelper.instance.guardarUsuario(<String, dynamic>{
          'nombre': _currentUser!.nombre,
          'email': _currentUser!.email,
          'celular': _currentUser!.telefono ?? '',
          'iglesia_nombre': _currentUser!.iglesiaActual,
          'creado_en': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('[UserProvider] Advertencia guardando en SQLite: $e');
      }

      // Sincronizar token del dispositivo con Odoo (no bloqueante)
      try {
        await DeviceNotificationService.instance.registerDeviceWithBackend(_api);
      } catch (e) {
        debugPrint('[UserProvider] Error no bloqueante al registrar dispositivo: $e');
      }

      _isLoading = false;
      notifyListeners();
      return data;
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión con Google: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Registra una nueva iglesia en Odoo para el usuario actual (POST /me/church).
  /// Transiciona el rol del usuario a 'church_admin' con church.has_active_subscription == false.
  Future<Map<String, dynamic>> createMyChurch(Map<String, dynamic> churchData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.createMyChurch(churchData);
      _rawMeData = data;
      _currentUser = UserModel.fromOdooJson(data);
      _api.defaultChurchId = _currentUser?.iglesiaId;
      _api.isReadOnly = _currentUser?.isReadOnly ?? false;
      _isLoading = false;
      notifyListeners();
      return data;
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = 'Error registrando congregación: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
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
      try {
        final meData = await _api.me();
        _rawMeData = meData;
        _currentUser = UserModel.fromOdooJson(meData);
      } catch (e) {
        debugPrint(
          'ℹ️ [UserProvider] /me no disponible en tryAutoLogin: $e. Restaurando desde SQLite...',
        );
        final localData = await AtrioDatabaseHelper.instance.getUsuario();
        if (localData != null &&
            ((localData['email'] as String?)?.isNotEmpty == true ||
                (localData['nombre'] as String?)?.isNotEmpty == true)) {
          final String name = (localData['nombre'] as String?) ?? 'Usuario';
          _currentUser = UserModel(
            id: 0,
            nombre: name,
            email: (localData['email'] as String?) ?? '',
            telefono: localData['celular'] as String?,
            iglesiaActual: (localData['iglesia_nombre'] as String?) ??
                'Sin iglesia seleccionada',
            fechaRegistro: (localData['creado_en'] as String?) ?? '',
            avatarIniciales: name.trim().isNotEmpty
                ? name.trim()[0].toUpperCase()
                : 'U',
            esMiembroVerificado: false,
            role: UserRole.user,
            permissions: const {
              'view_content',
              'manage_profile',
              'donate',
            },
            isReadOnly: false,
          );
        }
      }

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
      _rawMeData = null;
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
    _rawMeData = null;
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
    } else {
      _currentUser = UserModel(
        id: 0,
        nombre: nombre,
        email: email,
        telefono: telefono.isNotEmpty ? telefono : null,
        iglesiaActual: iglesiaActual,
        fechaRegistro: DateTime.now().toIso8601String().split('T').first,
        avatarIniciales: nombre.isNotEmpty
            ? nombre.trim()[0].toUpperCase()
            : 'U',
        esMiembroVerificado: false,
        role: UserRole.user,
        permissions: const {'view_content', 'manage_profile', 'donate'},
        isReadOnly: false,
      );
    }
    notifyListeners();
  }

  /// Traduce los códigos de error estándar de Odoo a mensajes claros y amigables.
  String _traducirErrorOdoo(AtrioApiException e) {
    // Si el servidor retorna HTTP 401 o códigos típicos de autenticación fallida
    if (e.status == 401 ||
        e.code == 'invalid_credentials' ||
        e.code == 'wrong_password' ||
        e.code == 'access_denied' ||
        e.code.toLowerCase().contains('credential') ||
        e.code.toLowerCase().contains('auth')) {
      return 'Usuario o contraseña incorrectos. Verifica tus credenciales.';
    }

    switch (e.code) {
      case 'missing_fields':
        return 'Por favor completa todos los campos requeridos.';
      case 'invalid_email':
        return 'El formato del correo electrónico no es válido.';
      case 'email_taken':
        return 'Ese correo ya tiene una cuenta registrada. Inicia sesión o recupera tu contraseña.';
      case 'weak_password':
        return 'La contraseña debe tener un mínimo de 8 caracteres.';
      case 'church_not_found':
        return 'La iglesia seleccionada ya no está disponible. Por favor elige otra.';
      case 'already_member':
        return 'Ya perteneces a una congregación activa.';
      case 'account_exists':
        return 'Ya tienes una cuenta registrada con este correo. Ingresa con tu contraseña.';
      case 'email_not_verified':
        return 'Tu cuenta de Google no tiene el correo electrónico verificado.';
      case 'invalid_google_token':
        return 'El token de Google no es válido o ha expirado. Por favor reintenta.';
      case 'signup_disabled':
        return 'El registro de nuevas cuentas no está disponible en este momento.';
      case 'google_disabled':
        return 'El inicio de sesión con Google está temporalmente desactivado.';
      case 'church_deactivated':
        return 'Esta congregación ha sido desactivada por administración. Contacta a soporte.';
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
        return 'Tu solicitud de membresía aún está pendiente de aprobación pastoral.';
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
      case 'server_error':
        return 'Error en el servidor. Por favor inténtalo más tarde.';
      default:
        if (e.status == 400) {
          return e.message.isNotEmpty
              ? e.message
              : 'Solicitud incorrecta o datos inválidos (400).';
        }
        return e.message.isNotEmpty ? e.message : 'Error en el servidor (${e.status}).';
    }
  }
}
