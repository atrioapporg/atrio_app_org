import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/data/app_config.dart';
import 'package:atrio/data/atrio_database_helper.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/servicios/auth_service.dart';
import 'package:atrio/servicios/device_notification_service.dart';
import 'package:atrio/servicios/token_storage_service.dart';

/// Evento reactivo que se dispara inmediatamente cuando el estatus de la iglesia
/// o membresía del usuario es aprobado o cambia de estado en Odoo 19.
class ChurchStatusChangeEvent {
  final String previousStatus;
  final String newStatus;
  final bool isApprovedNow;
  final String churchName;
  final DateTime timestamp;

  ChurchStatusChangeEvent({
    required this.previousStatus,
    required this.newStatus,
    required this.isApprovedNow,
    required this.churchName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Provider central para la gestión del usuario autenticado,
/// persistencia de sesión segura y comunicación con la API de Odoo.
class UserProvider extends ChangeNotifier {
  final AtrioApi _api;
  final TokenStorageService _storageService;

  UserModel? _currentUser;
  Map<String, dynamic>? _rawMeData;
  bool _isLoading = false;
  String? _errorMessage;

  final StreamController<ChurchStatusChangeEvent> _churchStatusChangeController =
      StreamController<ChurchStatusChangeEvent>.broadcast();

  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  /// Llave de navegación global opcional para redirigir limpiamente a `InicioSesionScreen`
  /// cuando ocurre un error fatal de renovación de sesión.
  GlobalKey<NavigatorState>? navigatorKey;

  /// Flujo reactivo que emite eventos inmediatamente cuando la iglesia del usuario
  /// es aprobada o cambia de estatus en Odoo 19.
  Stream<ChurchStatusChangeEvent> get onChurchStatusChanged =>
      _churchStatusChangeController.stream;

  /// Flujo reactivo que emite cuando la sesión expira definitivamente tras agotar el refresh_token.
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  UserProvider({
    AtrioApi? api,
    TokenStorageService? storageService,
    this.navigatorKey,
  })  : _storageService = storageService ?? TokenStorageService(),
        _api = api ??
            AtrioApi(
              baseUrl: AppConfig.odooBaseUrl,
              database: AppConfig.odooDatabase.isNotEmpty ? AppConfig.odooDatabase : null,
              storageService: storageService ?? TokenStorageService(),
            ) {
    // Configurar callback cuando la sesión expire definitivamente (error fatal en /auth/refresh)
    _api.onSessionExpired = _handleFatalSessionExpiration;

    // Auto-restaurar sesión desde almacenamiento seguro
    _iniciarSesionPersistente();
  }

  /// Invalida la sesión local y redirige limpiamente a `InicioSesionScreen`
  /// únicamente cuando el endpoint de renovación devuelve un error fatal.
  void _handleFatalSessionExpiration() {
    _currentUser = null;
    _rawMeData = null;
    _api.defaultChurchId = null;
    _api.isReadOnly = false;
    _errorMessage = 'Tu sesión ha expirado. Por favor, ingresa de nuevo.';
    notifyListeners();

    if (!_sessionExpiredController.isClosed) {
      _sessionExpiredController.add(null);
    }

    // Limpiar banderas de sesión local en segundo plano para evitar falsos positivos al reiniciar
    Future<void>(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('cached_user_profile');
      } catch (e) {
        debugPrint('[UserProvider] Error limpiando preferencias tras expirar sesión: $e');
      }
    });

    // Redirigir limpiamente a InicioSesionScreen si hay un Navigator activo
    final nav = navigatorKey?.currentState;
    if (nav != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final activeNav = navigatorKey?.currentState;
        if (activeNav != null) {
          activeNav.pushNamedAndRemoveUntil(
            'inicio_sesion_screen',
            (route) => false,
          );
        }
      });
    }
  }

  Future<void> _iniciarSesionPersistente() async {
    try {
      await _api.initFromStorage();
      if (_api.isAuthenticated && _currentUser == null) {
        try {
          final meData = await _api.me();
          _rawMeData = meData;
          _currentUser = UserModel.fromOdooJson(meData);
          await _persistCurrentUserLocally();
        } catch (meError) {
          if (meError is AtrioApiException && meError.isUnauthorized) {
            debugPrint(
              '🔒 [UserProvider] Sesión inválida en restauración inicial ($meError). Omitiendo caché local.',
            );
            return;
          }
          debugPrint(
            'ℹ️ [UserProvider] /me no disponible en restauración: $meError. Cargando desde almacenamiento local...',
          );
          _currentUser = await _restaurarUsuarioLocal();
        }
        if (_currentUser != null && _api.isAuthenticated) {
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

  /// Persiste el modelo de usuario actual en SharedPreferences y SQLite para soporte offline.
  Future<void> _persistCurrentUserLocally() async {
    if (_currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_user_profile',
        jsonEncode(_currentUser!.toJson()),
      );
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('user_email', _currentUser!.email);
      await prefs.setString('user_name', _currentUser!.nombre);
      await prefs.setString('userEmail', _currentUser!.email);
      await prefs.setString('userName', _currentUser!.nombre);
      await prefs.setString('membership_status', _currentUser!.membershipStatus);
      if (_currentUser!.iglesiaId != null) {
        await prefs.setInt('user_church_id', _currentUser!.iglesiaId!);
      }
      if (_currentUser!.iglesiaActual.isNotEmpty) {
        await prefs.setString('user_church_name', _currentUser!.iglesiaActual);
      }
    } catch (e) {
      debugPrint('[UserProvider] Advertencia guardando perfil en SharedPreferences: $e');
    }

    try {
      await AtrioDatabaseHelper.instance.guardarUsuario(<String, dynamic>{
        'nombre': _currentUser!.nombre,
        'email': _currentUser!.email,
        'celular': _currentUser!.telefono ?? '',
        'iglesia_nombre': _currentUser!.iglesiaActual,
        'creado_en': _currentUser!.fechaRegistro.isNotEmpty
            ? _currentUser!.fechaRegistro
            : DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[UserProvider] Advertencia guardando en SQLite: $e');
    }
  }

  /// Restaura de forma robusta el UserModel cuando el dispositivo está offline (modo avión)
  /// utilizando la caché JSON de SharedPreferences y la base de datos local SQLite (atrio.db).
  Future<UserModel?> _restaurarUsuarioLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Intentar restaurar desde el JSON completo cacheado en SharedPreferences
      final cachedJsonStr = prefs.getString('cached_user_profile');
      if (cachedJsonStr != null && cachedJsonStr.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJsonStr) as Map<String, dynamic>;
          final user = UserModel.fromJson(decoded);
          debugPrint(
            '✅ [UserProvider] Usuario restaurado desde cached_user_profile: ${user.nombre} (${user.iglesiaActual}, ${user.membershipStatus})',
          );
          return user;
        } catch (e) {
          debugPrint('⚠️ [UserProvider] Error parseando cached_user_profile: $e');
        }
      }

      // 2. Fallback: Reconstruir desde SQLite (atrio.db) + SharedPreferences
      final localData = await AtrioDatabaseHelper.instance.getUsuario();
      if (localData != null &&
          ((localData['email'] as String?)?.isNotEmpty == true ||
              (localData['nombre'] as String?)?.isNotEmpty == true)) {
        final String name = (localData['nombre'] as String?) ?? 'Usuario';
        final String iglesiaNombre =
            (localData['iglesia_nombre'] as String?)?.trim() ?? '';
        final bool tieneIglesiaValida = iglesiaNombre.isNotEmpty &&
            !UserModel.isDefaultOrDemoChurchName(iglesiaNombre);

        // Consultar estatus de membresía persistido en SharedPreferences si existe
        final String savedStatus = prefs.getString('membership_status') ??
            (tieneIglesiaValida ? 'approved' : 'none');
        final int? savedChurchId = prefs.getInt('user_church_id') ??
            (tieneIglesiaValida ? 1 : null);
        final bool esPendiente = savedStatus == 'membership_pending' ||
            savedStatus == 'pending';
        final bool esAprobado = tieneIglesiaValida && !esPendiente;

        return UserModel(
          id: localData['id'] as int? ?? 1,
          nombre: name,
          email: (localData['email'] as String?) ?? '',
          telefono: localData['celular'] as String?,
          iglesiaActual:
              tieneIglesiaValida ? iglesiaNombre : 'Sin iglesia seleccionada',
          iglesiaId: savedChurchId,
          fechaRegistro: (localData['creado_en'] as String?) ?? '',
          avatarIniciales: name.trim().isNotEmpty
              ? name.trim()[0].toUpperCase()
              : 'U',
          esMiembroVerificado: esAprobado,
          role: esAprobado ? UserRole.member : UserRole.user,
          membershipStatus: savedStatus,
          requestedChurchId: esPendiente ? savedChurchId : null,
          permissions: const {
            'view_content',
            'manage_profile',
            'donate',
          },
          isReadOnly: false,
        );
      }
    } catch (e) {
      debugPrint('[UserProvider] Error restaurando usuario localmente: $e');
    }
    return null;
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

  /// Información de la recomendación de iglesia activa del usuario (Odoo 19)
  ChurchRecommendationModel? get currentRecommendation =>
      _currentUser?.churchRecommendation;

  /// Indica si el usuario tiene una recomendación de iglesia en proceso de gestión
  bool get hasActiveRecommendation =>
      _currentUser?.hasActiveRecommendation ?? false;

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

  /// Estatus canónico de la congregación/membresía del usuario en Odoo ('none', 'membership_pending', 'change_pending', 'approved', etc.)
  String get churchStatus => _currentUser?.churchStatus ?? membershipStatus;

  /// Indica si la solicitud de membresía inicial a una congregación está en proceso de revisión/aprobación.
  /// No aplica si el usuario se encuentra en proceso de cambio/traslado (isChangePending).
  bool get isMembershipPending =>
      !isChangePending &&
      (isWaitingApproval ||
          _currentUser?.isMembershipPending == true ||
          membershipStatus == 'membership_pending' ||
          membershipStatus == 'pending' ||
          churchStatus == 'membership_pending' ||
          churchStatus == 'pending');

  /// Indica si el usuario tiene una solicitud de cambio/traslado de iglesia en proceso.
  bool get isChangePending =>
      _currentUser?.isChangePending == true ||
      membershipStatus == 'change_pending' ||
      (hasChurchAssigned &&
          isMember &&
          requestedChurchId != null &&
          requestedChurchId! > 0 &&
          requestedChurchId != _currentUser?.iglesiaId);

  /// Valida reactivamente si la congregación del usuario se encuentra debidamente asignada y aprobada por el backend.
  /// Retorna false si el usuario es invitado, no tiene congregación o su membresía inicial sigue pendiente de aprobación.
  /// Un traslado en curso (isChangePending) mantiene la membresía activa actual.
  bool get isChurchApproved =>
      isAuthenticated &&
      hasChurchAssigned &&
      (isMember || membershipStatus == 'approved') &&
      !isMembershipPending &&
      (_currentUser?.isChurchApproved ?? false);

  /// Valida de forma estricta si el usuario ya posee una congregación seleccionada o vinculada
  /// en su perfil (asignada formalmente, pendiente de aprobación o guardada),
  /// independientemente del estatus en el backend ('pending', 'approved', etc.).
  bool get hasSelectedOrLinkedChurch {
    if (_currentUser != null && _currentUser!.hasSelectedOrLinkedChurch) {
      return true;
    }
    if (hasChurchAssigned) return true;
    if (requestedChurchId != null && requestedChurchId! > 0) return true;
    if (requestedChurchData != null && requestedChurchData!.isNotEmpty) return true;
    if (isMembershipPending || isChangePending) return true;
    if (membershipStatus.isNotEmpty &&
        membershipStatus != 'none' &&
        membershipStatus != 'draft') {
      return true;
    }
    return false;
  }

  /// Referencia a la congregación seleccionada o vinculada por el usuario (o null si es nuevo).
  String? get selectedChurch => _currentUser?.selectedChurch;

  /// Verifica de forma exhaustiva (incluyendo persistencia local SQLite y SharedPreferences)
  /// si el usuario ya posee una congregación seleccionada previamente legítima (no demo/default).
  Future<bool> verificarIglesiaPrevia() async {
    if (hasSelectedOrLinkedChurch) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final iglesiaGuardada = prefs.getString('iglesia_guardada');
      if (iglesiaGuardada != null &&
          iglesiaGuardada.trim().isNotEmpty &&
          !UserModel.isDefaultOrDemoChurchName(iglesiaGuardada)) {
        return true;
      }

      final localUser = await AtrioDatabaseHelper.instance.getUsuario();
      if (localUser != null) {
        final iglesiaNombre = (localUser['iglesia_nombre'] as String?)?.trim();
        if (iglesiaNombre != null &&
            iglesiaNombre.isNotEmpty &&
            !UserModel.isDefaultOrDemoChurchName(iglesiaNombre)) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('[UserProvider] Error verificando iglesia previa: $e');
    }
    return false;
  }

  /// Valida si el usuario está plenamente habilitado para acceder y enviar solicitudes o peticiones pastorales.
  /// Requiere sesión activa, no operar en modo de solo lectura y contar con congregación aprobada.
  bool get canSubmitSolicitud =>
      isAuthenticated &&
      !isReadOnly &&
      isChurchApproved;

  /// Estatus de verificación institucional (KYC) de la iglesia del usuario.
  ChurchKycStatus get churchKycStatus =>
      _currentUser?.churchKycStatus ?? ChurchKycStatus.pendingKyc;

  /// Indica si la congregación del usuario tiene su verificación KYC aprobada para recaudar ofrendas.
  /// Mientras no concluya la revisión legal y técnica (KYC) de las iglesias candidatas,
  /// se mantiene deshabilitado (`false`) conforme a la Sección 2 del Manual de Compliance.
  bool get isChurchKycApproved => false;

  /// Valida si el usuario está plenamente habilitado para realizar ofrendas congregacionales locales.
  /// Requiere membresía activa, iglesia asignada y verificación institucional KYC aprobada en Odoo.
  bool get canDonate =>
      isAuthenticated &&
      !isReadOnly &&
      (role == UserRole.member || role == UserRole.churchAdmin) &&
      hasChurchAssigned &&
      isChurchKycApproved;

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
    bool emitStatusEvent = false,
  }) {
    final prevApproved = _currentUser?.isChurchApproved ?? false;
    final prevStatus = _currentUser?.membershipStatus ?? 'none';
    _currentUser = user;
    _rawMeData = rawMeData;
    _api.defaultChurchId = user?.iglesiaId;
    _api.isReadOnly = user?.isReadOnly ?? false;
    notifyListeners();

    if (emitStatusEvent && user != null) {
      final isApprovedNow = (!prevApproved && user.isChurchApproved);
      _churchStatusChangeController.add(
        ChurchStatusChangeEvent(
          previousStatus: prevStatus,
          newStatus: user.membershipStatus,
          isApprovedNow: isApprovedNow,
          churchName: user.iglesiaActual,
        ),
      );
    }
  }

  /// Emite manualmente una notificación de cambio de estado de congregación (ej. tras push notification).
  void notifyChurchStatusChanged({
    required String status,
    required String churchName,
    bool isApproved = false,
  }) {
    final event = ChurchStatusChangeEvent(
      previousStatus: _currentUser?.membershipStatus ?? 'none',
      newStatus: status,
      isApprovedNow: isApproved,
      churchName: churchName,
    );
    _churchStatusChangeController.add(event);
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
      final prevStatus = _currentUser?.membershipStatus ?? 'none';
      final prevApproved = _currentUser?.isChurchApproved ?? false;

      _currentUser = UserModel.fromOdooJson(meData);

      // Preservar la iglesia solicitada / previa si Odoo todavía no la vinculó o devolvió null en /me
      if (_currentUser != null && !_currentUser!.hasChurchAssigned) {
        if (prevRequestedChurch != null && prevRequestedChurch.isNotEmpty) {
          final String preservedName = prevRequestedChurch['name'] as String? ??
              prevIglesia ??
              _currentUser!.iglesiaActual;
          _currentUser = _currentUser!.copyWith(
            requestedChurchData: prevRequestedChurch,
            requestedChurchId: prevRequestedId ?? _currentUser!.requestedChurchId,
            iglesiaActual: preservedName,
            membershipStatus: _currentUser!.isMembershipPending
                ? _currentUser!.membershipStatus
                : 'membership_pending',
          );
        } else if (prevIglesia != null &&
            prevIglesia.isNotEmpty &&
            prevIglesia != 'Sin iglesia seleccionada' &&
            prevIglesia != 'Iglesia Atrio') {
          _currentUser = _currentUser!.copyWith(
            iglesiaActual: prevIglesia,
            membershipStatus: _currentUser!.isMembershipPending
                ? _currentUser!.membershipStatus
                : (prevStatus.isNotEmpty && prevStatus != 'none'
                    ? prevStatus
                    : 'approved'),
          );
        }
      } else if (_currentUser != null && _currentUser!.hasChurchAssigned) {
        // Preservar la solicitud de cambio de congregación si Odoo todavía no la devolvió
        if ((_currentUser!.requestedChurchId == null ||
                _currentUser!.requestedChurchId == 0) &&
            prevRequestedId != null &&
            prevRequestedId > 0 &&
            prevRequestedId != _currentUser!.iglesiaId) {
          _currentUser = _currentUser!.copyWith(
            requestedChurchId: prevRequestedId,
            requestedChurchData: prevRequestedChurch,
            membershipStatus: _currentUser!.membershipStatus == 'none' ||
                    _currentUser!.membershipStatus == 'approved'
                ? 'change_pending'
                : _currentUser!.membershipStatus,
          );
        }
      }

      if (_currentUser != null &&
          _currentUser!.requestedChurchData != null &&
          _rawMeData != null &&
          (_rawMeData!['requested_church'] == null ||
              _rawMeData!['church'] == null)) {
        _rawMeData!['requested_church'] = _currentUser!.requestedChurchData;
        _rawMeData!['requested_church_id'] = _currentUser!.requestedChurchId;
        _rawMeData!['membership_status'] = _currentUser!.membershipStatus;
        if (!_currentUser!.hasChurchAssigned) {
          _rawMeData!['iglesia_actual'] = _currentUser!.iglesiaActual;
        }
      }

      _api.defaultChurchId = _currentUser?.iglesiaId;
      _api.isReadOnly = _currentUser?.isReadOnly ?? false;
      await _persistCurrentUserLocally();
      notifyListeners();

      // Detección automática y emisión inmediata si cambió de estado o fue aprobada
      final newStatus = _currentUser?.membershipStatus ?? 'none';
      final newApproved = _currentUser?.isChurchApproved ?? false;
      if ((prevStatus != newStatus || prevApproved != newApproved) && _currentUser != null) {
        final isApprovedNow = (!prevApproved && newApproved) ||
            (prevStatus == 'membership_pending' &&
                (newStatus == 'approved' || newApproved));
        final event = ChurchStatusChangeEvent(
          previousStatus: prevStatus,
          newStatus: newStatus,
          isApprovedNow: isApprovedNow,
          churchName: _currentUser!.iglesiaActual,
        );
        _churchStatusChangeController.add(event);
      }
    } catch (e) {
      debugPrint('[UserProvider] Error al refrescar perfil: $e');
      if (e is AtrioApiException && e.isUnauthorized) {
        return;
      }
      if ((_currentUser == null || !_currentUser!.hasChurchAssigned) &&
          _api.isAuthenticated) {
        final restored = await _restaurarUsuarioLocal();
        if (restored != null) {
          _currentUser = restored;
          notifyListeners();
        }
      }
    }
  }

  /// Registra la solicitud de ingreso a una congregación (POST /membership/request)
  /// y actualiza inmediatamente el modelo de usuario y la persistencia local.
  /// Soporta tanto ID numérico de Odoo [churchId] como identificador de Google Maps [placeId],
  /// nombre de la iglesia [churchName], denominación de fe [denominacion] y logotipo [logoUrl].
  Future<void> solicitarMembresia({
    int? churchId,
    String? placeId,
    required String churchName,
    String? denominacion,
    String? logoUrl,
  }) async {
    int? effectiveChurchId = churchId;

    // Detectar si el usuario ya es miembro activo de una congregación (proceso de cambio / traslado)
    final bool isAlreadyMember = hasChurchAssigned &&
        (isMember ||
            isChurchApproved ||
            _currentUser?.membershipStatus == 'approved');

    final String nextStatus =
        isAlreadyMember ? 'change_pending' : 'membership_pending';

    // 1. Persistir localmente en SQLite y SharedPreferences para disponibilidad inmediata
    // Solo sobreescribir la iglesia activa local si el usuario NO es ya un miembro activo
    try {
      if (!isAlreadyMember) {
        await AtrioDatabaseHelper.instance.guardarIglesiaNombre(churchName);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('iglesia_guardada', churchName);
      }
      if (denominacion != null && denominacion.trim().isNotEmpty) {
        await AtrioDatabaseHelper.instance.guardarFeReligiosa(denominacion.trim());
      }
    } catch (e) {
      debugPrint('[UserProvider] Error guardando iglesia/denominación local: $e');
    }

    final churchData = <String, dynamic>{
      if (effectiveChurchId != null && effectiveChurchId > 0)
        'id': effectiveChurchId,
      'name': churchName,
      if (placeId != null && placeId.isNotEmpty) 'place_id': placeId,
      if (denominacion != null && denominacion.isNotEmpty)
        'denominacion': denominacion,
      if (logoUrl != null && logoUrl.isNotEmpty) 'logo_url': logoUrl,
    };

    // 2. Actualizar estado reactivo en memoria de inmediato (Optimistic UI)
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        membershipStatus: nextStatus,
        requestedChurchId: (effectiveChurchId != null && effectiveChurchId > 0)
            ? effectiveChurchId
            : 0,
        requestedChurchData: churchData,
        iglesiaActual: isAlreadyMember
            ? _currentUser!.iglesiaActual
            : churchName,
      );
    }

    if (_rawMeData != null) {
      _rawMeData!['membership_status'] = nextStatus;
      if (effectiveChurchId != null && effectiveChurchId > 0) {
        _rawMeData!['requested_church_id'] = effectiveChurchId;
      }
      _rawMeData!['requested_church'] = churchData;
      if (!isAlreadyMember) {
        _rawMeData!['iglesia_actual'] = churchName;
      }
    } else {
      _rawMeData = {
        'membership_status': nextStatus,
        if (effectiveChurchId != null && effectiveChurchId > 0)
          'requested_church_id': effectiveChurchId,
        'requested_church': churchData,
        if (!isAlreadyMember) 'iglesia_actual': churchName,
      };
    }

    notifyListeners();

    // 3. Enviar solicitud formal al backend de Odoo 19
    if (_api.isAuthenticated) {
      // Si tenemos placeId pero no ID de Odoo, consultar si ya está dada de alta en Atrio
      if ((effectiveChurchId == null || effectiveChurchId <= 0) &&
          placeId != null &&
          placeId.isNotEmpty) {
        try {
          final lookup = await _api.getChurchByPlace(placeId);
          if (lookup.church != null && lookup.church!['id'] != null) {
            effectiveChurchId = int.tryParse(lookup.church!['id'].toString());
            if (effectiveChurchId != null && effectiveChurchId > 0) {
              churchData['id'] = effectiveChurchId;
              if (_currentUser != null) {
                _currentUser = _currentUser!.copyWith(
                  requestedChurchId: effectiveChurchId,
                  requestedChurchData: churchData,
                );
              }
              if (_rawMeData != null) {
                _rawMeData!['requested_church_id'] = effectiveChurchId;
                _rawMeData!['requested_church'] = churchData;
              }
            }
          }
        } catch (e) {
          debugPrint('ℹ️ [UserProvider] getChurchByPlace ($placeId): $e');
        }
      }

      // Enviar /membership/request a Odoo con ID de iglesia, place_id y denominación
      bool solicitudAceptada = false;
      try {
        await _api.requestMembership(
          churchId: effectiveChurchId,
          placeId: placeId,
          churchName: churchName,
          denomination: denominacion,
        );
        solicitudAceptada = true;
        debugPrint(
          '✅ [UserProvider] Solicitud de membresía enviada a Odoo para "$churchName" (placeId=$placeId, churchId=$effectiveChurchId)',
        );
      } catch (e) {
        debugPrint('⚠️ [UserProvider] Error en requestMembership: $e');
      }

      // Si no fue aceptada directamente vía /membership/request y tenemos placeId, vincular vía recomendación
      if (!solicitudAceptada && placeId != null && placeId.isNotEmpty) {
        try {
          await _api.recommendChurch(placeId: placeId);
          debugPrint(
            '✅ [UserProvider] recommendChurch exitoso para vincular "$churchName" (placeId=$placeId)',
          );
        } catch (e) {
          debugPrint('ℹ️ [UserProvider] Error en recommendChurch: $e');
        }
      }

      // Sincronizar denominación de fe en perfil de Odoo
      if (denominacion != null && denominacion.isNotEmpty) {
        try {
          await _api.updateMe({
            'fe_religiosa': denominacion,
            'religion': denominacion,
            'denomination': denominacion,
          });
          debugPrint(
            '✅ [UserProvider] Denominación de fe "$denominacion" sincronizada en Odoo',
          );
        } catch (e) {
          debugPrint('ℹ️ [UserProvider] updateMe denominación: $e');
        }
      }

      // Refrescar perfil protegiendo los datos solicitados
      try {
        await refreshUserProfile();
        if (_currentUser != null &&
            (_currentUser!.requestedChurchData == null ||
                _currentUser!.requestedChurchData!['name'] == null)) {
          _currentUser = _currentUser!.copyWith(
            requestedChurchData: churchData,
            iglesiaActual: churchName,
            membershipStatus: 'membership_pending',
            requestedChurchId: (effectiveChurchId != null && effectiveChurchId > 0)
                ? effectiveChurchId
                : 0,
          );
          notifyListeners();
        }
      } catch (e) {
        debugPrint('[UserProvider] Error refrescando tras solicitar membresía: $e');
      }
    }
  }

  /// Cancela formalmente la solicitud de cambio de congregación (traslado eclesial).
  /// Restaura al usuario como miembro activo ('approved') en su iglesia actual,
  /// limpiando la congregación solicitada en memoria reactiva, SQLite y SharedPreferences,
  /// y notificando al backend Odoo 19.
  Future<bool> cancelarSolicitudCambioIglesia() async {
    final user = _currentUser;
    if (user == null) return false;

    // Solo procede si efectivamente hay una solicitud de cambio pendiente
    if (!user.isChangePending && user.membershipStatus != 'change_pending') {
      return false;
    }

    // 1. Rollback reactivo inmediato (Optimistic UI)
    // En Odoo 19 (atrio_web_manager 19.0.8), membership_status vuelve a 'member' o 'church_admin'
    final String restoredStatus =
        user.isChurchAdmin ? 'church_admin' : 'member';
    _currentUser = user.copyWith(
      membershipStatus: restoredStatus,
      clearRequestedChurch: true,
    );

    if (_rawMeData != null) {
      _rawMeData!['membership_status'] = restoredStatus;
      _rawMeData!['requested_church_id'] = null;
      _rawMeData!['requested_church'] = null;
    }

    notifyListeners();

    // 2. Persistir localmente en SQLite y SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('requested_church_id');
      await prefs.remove('requested_church_data');
      await prefs.setString('membership_status', restoredStatus);
      if (user.iglesiaActual.isNotEmpty &&
          user.iglesiaActual != 'Sin iglesia seleccionada') {
        await prefs.setString('iglesia_guardada', user.iglesiaActual);
        await AtrioDatabaseHelper.instance
            .guardarIglesiaNombre(user.iglesiaActual);
      }
    } catch (e) {
      debugPrint('[UserProvider] Error al persistir cancelación de cambio: $e');
    }

    // 3. Notificar la cancelación al backend de Odoo 19
    if (_api.isAuthenticated) {
      try {
        await _api.cancelMembershipRequest();
        debugPrint('✅ [UserProvider] Solicitud de cambio cancelada en Odoo con éxito');
      } catch (e) {
        debugPrint('⚠️ [UserProvider] Error cancelando cambio en Odoo: $e');
      }

      // Sincronizar perfil protegiendo el estado restaurado
      try {
        await refreshUserProfile();
        if (_currentUser != null && _currentUser!.isChangePending) {
          _currentUser = _currentUser!.copyWith(
            membershipStatus: restoredStatus,
            clearRequestedChurch: true,
          );
          notifyListeners();
        }
      } catch (e) {
        debugPrint('ℹ️ [UserProvider] Error refrescando tras cancelar cambio: $e');
      }
    }

    return true;
  }

  /// Cancela la solicitud inicial de membresía para usuarios que aún no tenían congregación asignada.
  Future<bool> cancelarSolicitudMembresia() async {
    final user = _currentUser;
    if (user == null) return false;

    // Si ya era miembro y solo estaba cambiando, delegar al flujo de cambio
    if (user.isChangePending) {
      return await cancelarSolicitudCambioIglesia();
    }

    _currentUser = user.copyWith(
      membershipStatus: 'none',
      clearRequestedChurch: true,
      iglesiaActual: 'Sin iglesia seleccionada',
      iglesiaId: 0,
    );

    if (_rawMeData != null) {
      _rawMeData!['membership_status'] = 'none';
      _rawMeData!['requested_church_id'] = null;
      _rawMeData!['requested_church'] = null;
      _rawMeData!['iglesia_actual'] = 'Sin iglesia seleccionada';
    }

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('requested_church_id');
      await prefs.remove('requested_church_data');
      await prefs.setString('membership_status', 'none');
      await prefs.remove('iglesia_guardada');
      await AtrioDatabaseHelper.instance
          .guardarIglesiaNombre('Sin iglesia seleccionada');
    } catch (e) {
      debugPrint('[UserProvider] Error persistiendo cancelación de membresía: $e');
    }

    if (_api.isAuthenticated) {
      try {
        await _api.cancelMembershipRequest();
        debugPrint('✅ [UserProvider] Solicitud de membresía inicial cancelada en Odoo');
      } catch (e) {
        debugPrint('⚠️ [UserProvider] Error cancelando membresía en Odoo: $e');
      }

      try {
        await refreshUserProfile();
      } catch (e) {
        debugPrint('ℹ️ [UserProvider] Error refrescando tras cancelar membresía: $e');
      }
    }

    return true;
  }

  /// Cancela una petición pastoral o de oración en Odoo (`POST /requests/{id}/cancel`)
  /// y actualiza la caché local SQLite a `cancelada` únicamente si la operación es válida.
  Future<({bool ok, String? errorCode, String? message})> cancelarPeticionPastoral(
    int requestId, {
    int? localId,
  }) async {
    if (_api.isAuthenticated && requestId > 0) {
      try {
        await _api.cancelRequest(requestId);
        debugPrint('✅ [UserProvider] Petición $requestId cancelada en Odoo');
      } on AtrioApiException catch (e) {
        debugPrint('⚠️ [UserProvider] Error API al cancelar petición $requestId: $e');
        return (ok: false, errorCode: e.code, message: e.message);
      } catch (e) {
        debugPrint('⚠️ [UserProvider] Error al cancelar petición $requestId en Odoo: $e');
        return (ok: false, errorCode: null, message: e.toString());
      }
    }

    // Actualizar estado en SQLite local con el estado canónico 'cancelada'
    try {
      await AtrioDatabaseHelper.instance
          .actualizarEstadoSolicitudLocal(localId ?? requestId, 'cancelada');
    } catch (e) {
      debugPrint('[UserProvider] Error actualizando SQLite local: $e');
    }

    return (ok: true, errorCode: null, message: null);
  }

  // ===========================================================================
  // FLUJO DE AUTENTICACIÓN CON ODOO (ETAPA 2)
  // ===========================================================================

  /// Registra un nuevo usuario en Odoo (POST /register).
  /// No inyecta ninguna iglesia demo o genérica por defecto.
  /// Si el registro es exitoso, el usuario nuevo no tendrá iglesia asignada
  /// y deberá pasar obligatoriamente por SeleccionarIglesiaScreen.
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    int? churchId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'name': nombre.trim(),
        'email': email.trim(),
        'password': password,
        if (telefono != null && telefono.trim().isNotEmpty)
          'phone': telefono.trim(),
        if (churchId != null && churchId > 0)
          'church_id': churchId,
      };

      final res = await _api.registerMember(payload);
      return res;
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      rethrow;
    } catch (e) {
      _errorMessage = 'Error en el registro: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      await _persistCurrentUserLocally();

      // Si el usuario no tiene iglesia seleccionada o vinculada legítima, limpiar cualquier
      // iglesia residual o demo en almacenamiento local (SharedPreferences y SQLite).
      if (!(_currentUser?.hasSelectedOrLinkedChurch ?? false)) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('iglesia_guardada');
          await AtrioDatabaseHelper.instance.guardarIglesiaNombre('Sin iglesia seleccionada');
        } catch (e) {
          debugPrint('[UserProvider] Advertencia limpiando iglesia previa residual: $e');
        }
      }

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
      await _persistCurrentUserLocally();

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
      debugPrint('[UserProvider] Error no controlado en loginWithSocial: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('TimeoutException')) {
        _errorMessage = 'Error de conexión con el servidor. Verifica tu conexión a internet.';
      } else {
        _errorMessage = 'Error al iniciar sesión con $provider. Intenta nuevamente.';
      }
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
      await _persistCurrentUserLocally();

      // Si el usuario nuevo o sin iglesia no tiene asignación legítima, limpiar residuos locales
      if (!(_currentUser?.hasSelectedOrLinkedChurch ?? false)) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('iglesia_guardada');
          await AtrioDatabaseHelper.instance.guardarIglesiaNombre('Sin iglesia seleccionada');
        } catch (e) {
          debugPrint('[UserProvider] Advertencia limpiando iglesia previa residual: $e');
        }
      }

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
      debugPrint('[UserProvider] Error no controlado en loginWithGoogle: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('TimeoutException')) {
        _errorMessage = 'Error de conexión con el servidor. Verifica tu conexión a internet.';
      } else {
        _errorMessage = 'Error al iniciar sesión con Google. Intenta nuevamente.';
      }
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
        await _persistCurrentUserLocally();
      } catch (e) {
        if (e is AtrioApiException && e.isUnauthorized) {
          return false;
        }
        debugPrint(
          'ℹ️ [UserProvider] /me no disponible en tryAutoLogin: $e. Restaurando desde almacenamiento local...',
        );
        _currentUser = await _restaurarUsuarioLocal();
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
      // Revocar sesión de Google para evitar autorelogueo en logout
      await AuthService.revokeGoogleSession();

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
        await prefs.remove('userEmail');
        await prefs.remove('userName');
        await prefs.remove('cached_user_profile');
        await prefs.remove('membership_status');
        await prefs.remove('user_church_id');
        await prefs.remove('user_church_name');
        await prefs.remove('iglesia_guardada');
        await AtrioDatabaseHelper.instance.eliminarUsuarioYDatos();
      } catch (e) {
        debugPrint('[UserProvider] Error limpiando datos locales en logout: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Flujo integral de eliminación definitiva de cuenta y datos personales:
  /// - ETAPA 3: Envía la solicitud formal al backend de Odoo 19 para supresión de registros y disparo de correo.
  /// - ETAPA 2: Revoca la sesión OAuth de Google Sign-In de forma estricta (disconnect() + signOut()).
  /// - ETAPA 1: Limpieza exhaustiva de FlutterSecureStorage (clearAll), SharedPreferences (clear) y SQLite (purgarBaseDeDatosCompleta).
  /// - Reseteo en memoria a estado virgen absoluto.
  Future<bool> eliminarCuentaDefinitiva({String? razon}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = _currentUser;
    final int? userId = user?.id;
    final String? email = user?.email;

    try {
      // ETAPA 3: Integración y notificación al Backend de Odoo 19
      if (userId != null && email != null) {
        try {
          // Desregistrar notificaciones push antes de suprimir la cuenta
          await DeviceNotificationService.instance.unregisterDeviceFromBackend(_api);
          await _api.deleteAccount(
            userId: userId,
            email: email,
            reason: razon,
          );
          debugPrint('✅ [UserProvider] Solicitud de eliminación formal aceptada por backend Odoo.');
        } catch (e) {
          debugPrint('⚠️ [UserProvider] Advertencia al contactar Odoo para eliminación: $e');
          // Continuamos para garantizar que la app móvil cumpla con la purga local estricta
        }
      }

      // ETAPA 2: Revocación de Sesión OAuth (Google Sign-In)
      await AuthService.revokeGoogleSession();

      // ETAPA 1: Limpieza Exhaustiva de Almacenamiento Local
      // 1. FlutterSecureStorage
      await _api.clearAllStorage();

      // 2. SharedPreferences (Wipe total: estado virgen)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (e) {
        debugPrint('⚠️ [UserProvider] Error limpiando SharedPreferences: $e');
      }

      // 3. Purga y restablecimiento de SQLite a estado de fábrica
      try {
        await AtrioDatabaseHelper.instance.purgarBaseDeDatosCompleta();
      } catch (e) {
        debugPrint('⚠️ [UserProvider] Error purgando SQLite: $e');
      }

      // 4. Limpieza del estado reactivo en memoria
      _rawMeData = null;
      _currentUser = null;
      _api.defaultChurchId = null;
      _api.isReadOnly = false;
      _errorMessage = null;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('💥 [UserProvider] Excepción crítica eliminando cuenta: $e');
      _errorMessage = 'Error eliminando la cuenta: $e';
      _isLoading = false;
      notifyListeners();
      return false;
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

  @override
  void dispose() {
    _churchStatusChangeController.close();
    _sessionExpiredController.close();
    super.dispose();
  }
}
