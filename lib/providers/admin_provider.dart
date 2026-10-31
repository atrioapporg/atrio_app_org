import 'package:flutter/foundation.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/admin_models.dart';
import 'package:atrio/models/event_dto.dart';
import 'package:atrio/models/sermon_dto.dart';

/// Provider para la gestión administrativa de la iglesia (Odoo 19 /admin/*)
/// Utilizado por roles church_admin y usuarios con permisos pastorales.
class AdminProvider extends ChangeNotifier {
  final AtrioApi api;
  AtrioApi get _api => api;

  List<AdminAnnouncementModel> _announcements = [];
  List<AdminGroupModel> _groups = [];
  List<AdminPrayerRequestModel> _prayerRequests = [];
  List<AdminChurchRequestModel> _churchRequests = [];
  AdminChurchStatsModel? _churchStats;
  List<AdminNotificationItemModel> _adminNotifications = [];
  int _unreadNotificationsCount = 0;
  int _inboxNotificationsCount = 0;
  List<EventDto> _adminEvents = [];
  List<SermonDto> _adminSermons = [];
  AdminAnalyticsModel? _analytics;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isPrayerRequestsWebOnly = false;
  bool _isAnalyticsWebOnly = false;

  AdminProvider({required this.api});

  List<AdminAnnouncementModel> get announcements => _announcements;
  List<AdminGroupModel> get groups => _groups;
  List<AdminPrayerRequestModel> get prayerRequests => _prayerRequests;
  List<AdminChurchRequestModel> get churchRequests => _churchRequests;
  AdminChurchStatsModel? get churchStats => _churchStats;
  List<AdminNotificationItemModel> get adminNotificationsList => _adminNotifications;
  int get unreadNotificationsCount => _unreadNotificationsCount;
  int get inboxNotificationsCount => _inboxNotificationsCount;
  List<EventDto> get adminEvents => _adminEvents;
  List<SermonDto> get adminSermons => _adminSermons;
  AdminAnalyticsModel? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPrayerRequestsWebOnly => _isPrayerRequestsWebOnly;
  bool get isAnalyticsWebOnly => _isAnalyticsWebOnly;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Restablece todo el estado administrativo en memoria a su valor virgen por defecto
  void reset() {
    _announcements = [];
    _groups = [];
    _prayerRequests = [];
    _churchRequests = [];
    _churchStats = null;
    _adminNotifications = [];
    _unreadNotificationsCount = 0;
    _inboxNotificationsCount = 0;
    _adminEvents = [];
    _adminSermons = [];
    _analytics = null;
    _isLoading = false;
    _errorMessage = null;
    _isPrayerRequestsWebOnly = false;
    _isAnalyticsWebOnly = false;
    notifyListeners();
  }

  // ===========================================================================
  // 1. AVISOS CONGREGACIONALES (/admin/announcements)
  // ===========================================================================

  /// Carga los avisos congregacionales de la iglesia activa.
  Future<void> loadAnnouncements({int limit = 20, int offset = 0}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.adminAnnouncements(limit: limit, offset: offset);
      final rawList = res['announcements'] ?? res['items'] ?? res['data'] ?? [];
      if (rawList is List) {
        _announcements = rawList
            .map((e) => AdminAnnouncementModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      debugPrint('[AdminProvider] Error al cargar avisos: $e');
    } catch (e) {
      _errorMessage = 'Error inesperado al cargar avisos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Publica un nuevo aviso congregacional con segmentación opcional de grupos.
  Future<bool> createAnnouncement({
    required String title,
    required String content,
    List<int>? targetGroupIds,
    bool pinned = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.adminCreateAnnouncement(
        title: title,
        content: content,
        targetGroupIds: targetGroupIds,
        pinned: pinned,
      );

      final rawItem = res['announcement'] ?? res['data'] ?? res;
      if (rawItem is Map) {
        final newAnnouncement =
            AdminAnnouncementModel.fromJson(Map<String, dynamic>.from(rawItem));
        _announcements.insert(0, newAnnouncement);
      } else {
        await loadAnnouncements();
      }

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
      _errorMessage = 'Error al publicar aviso: $e';
      notifyListeners();
      return false;
    }
  }

  /// Elimina un aviso congregacional existente.
  Future<bool> deleteAnnouncement(int announcementId) async {
    try {
      await _api.adminDeleteAnnouncement(announcementId);
      _announcements.removeWhere((a) => a.id == announcementId);
      notifyListeners();
      return true;
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // 2. SEGMENTACIÓN Y AUDIENCIAS (/admin/groups)
  // ===========================================================================

  /// Carga los grupos de audiencia de la iglesia.
  Future<void> loadGroups() async {
    try {
      final res = await _api.adminGroups();
      final rawList = res['groups'] ?? res['items'] ?? res['data'] ?? [];
      if (rawList is List) {
        _groups = rawList
            .map((e) => AdminGroupModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        notifyListeners();
      }
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      debugPrint('[AdminProvider] Error al cargar grupos: $e');
      notifyListeners();
    }
  }

  // ===========================================================================
  // 3. GESTIÓN Y MODERACIÓN DE SOLICITUDES PASTORALES (/admin/requests)
  // ===========================================================================

  /// Carga todas las solicitudes pastorales de la congregación desde Odoo 19.
  /// [status]: 'nueva', 'en_progreso', 'respondida', 'rechazada' o null para todas.
  /// [type]: 'oracion', 'ayuda', 'consejeria' o null para todas.
  Future<void> loadChurchRequests({
    String? status,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.adminRequests(
        status: status,
        type: type,
        limit: limit,
        offset: offset,
      );
      _isPrayerRequestsWebOnly = false;
      final rawList = res['requests'] ?? res['items'] ?? res['data'] ?? [];
      if (rawList is List) {
        _churchRequests = rawList
            .map((e) => AdminChurchRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        // Mapeo retrocompatible para vistas legadas
        _prayerRequests = _churchRequests.map((c) {
          return AdminPrayerRequestModel(
            id: c.id,
            title: c.title,
            description: c.message,
            applicantName: c.requesterName,
            applicantEmail: c.requester?.email ?? '',
            state: c.state,
            createDate: c.createdAt,
            moderationReason: c.rejectionReason,
            moderationDate: c.updatedAt,
          );
        }).toList();
      }
    } on AtrioApiException catch (e) {
      if (e.status == 404 || e.code == 'not_found' || e.code == 'endpoint_not_found') {
        _isPrayerRequestsWebOnly = true;
        _errorMessage =
            'La moderación de solicitudes pastorales se gestiona actualmente desde la consola web (/atrio/manage).';
      } else {
        _errorMessage = _traducirErrorOdoo(e);
        debugPrint('[AdminProvider] Error al cargar solicitudes: $e');
      }
    } catch (e) {
      _errorMessage = 'Error al consultar solicitudes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alias de compatibilidad para cargar peticiones de oración
  Future<void> loadPrayerRequests({String status = 'pending'}) async {
    final mappedStatus = status == 'pending' ? 'nueva' : status;
    return loadChurchRequests(status: mappedStatus == 'all' ? null : mappedStatus);
  }

  /// Responde formalmente a una solicitud pastoral con mensaje (PUT /admin/requests/{id} con action: answer).
  Future<bool> answerChurchRequest({
    required int requestId,
    required String response,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.adminUpdateRequest(
        requestId: requestId,
        action: 'answer',
        response: response,
      );

      // Actualización reactiva local
      final idx = _churchRequests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        _churchRequests[idx] = _churchRequests[idx].copyWith(
          state: 'respondida',
          response: response,
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
      }
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
      _errorMessage = 'Error al responder solicitud: $e';
      notifyListeners();
      return false;
    }
  }

  /// Aprueba una solicitud pastoral (PUT /admin/requests/{id} con action: approve).
  Future<bool> approveChurchRequest({required int requestId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.adminUpdateRequest(
        requestId: requestId,
        action: 'approve',
      );

      final idx = _churchRequests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        _churchRequests[idx] = _churchRequests[idx].copyWith(
          state: 'respondida',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
      }
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
      _errorMessage = 'Error al aprobar solicitud: $e';
      notifyListeners();
      return false;
    }
  }

  /// Rechaza una solicitud pastoral con justificación (PUT /admin/requests/{id} con action: reject).
  Future<bool> rejectChurchRequest({
    required int requestId,
    required String reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.adminUpdateRequest(
        requestId: requestId,
        action: 'reject',
        reason: reason,
      );

      final idx = _churchRequests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        _churchRequests[idx] = _churchRequests[idx].copyWith(
          state: 'rechazada',
          rejectionReason: reason,
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
      }
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
      _errorMessage = 'Error al rechazar solicitud: $e';
      notifyListeners();
      return false;
    }
  }

  /// Modera una petición de oración (approve o reject) - compatibilidad
  Future<bool> moderatePrayerRequest({
    required int requestId,
    required bool approve,
    String? reason,
  }) async {
    if (approve) {
      return approveChurchRequest(requestId: requestId);
    } else {
      return rejectChurchRequest(requestId: requestId, reason: reason ?? 'Rechazada por moderador');
    }
  }

  // ===========================================================================
  // 4. ESTADÍSTICAS Y MÉTRICAS OFICIALES DE LA IGLESIA (/admin/stats)
  // ===========================================================================

  /// Carga estadísticas y métricas oficiales de la iglesia en Odoo 19.
  Future<void> loadChurchStats({String period = 'month'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.adminStats(period: period);
      _isAnalyticsWebOnly = false;
      _churchStats = AdminChurchStatsModel.fromJson(res);

      // Compatibilidad con modelo analítico previo
      _analytics = AdminAnalyticsModel(
        totalMembers: _churchStats?.activeMembers ?? 0,
        newMembersThisMonth: _churchStats?.newMembers ?? 0,
        prayerRequestsCount: _churchRequests.length,
        totalOfferingsAmount: _churchStats?.offeringsTotal ?? 0.0,
        eventRegistrationsCount: _churchStats?.eventRegistrations ?? 0,
        period: period,
        rawMetrics: res,
      );
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      debugPrint('[AdminProvider] Error al cargar stats: $e');
    } catch (e) {
      _errorMessage = 'Error al cargar estadísticas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alias de compatibilidad para métricas
  Future<void> loadAnalytics({String period = 'month'}) async {
    return loadChurchStats(period: period);
  }

  // ===========================================================================
  // 4.1. BUZÓN DE NOTIFICACIONES ADMINISTRATIVAS (/admin/notifications)
  // ===========================================================================

  /// Carga notificaciones institucionales de la iglesia.
  Future<void> loadAdminNotifications({
    String view = 'inbox',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await _api.adminNotifications(
        view: view,
        limit: limit,
        offset: offset,
      );
      _unreadNotificationsCount = res['unread_count'] as int? ?? 0;
      _inboxNotificationsCount = res['inbox_count'] as int? ?? 0;
      final rawList = res['notifications'] ?? res['items'] ?? [];
      if (rawList is List) {
        _adminNotifications = rawList
            .map((e) => AdminNotificationItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AdminProvider] Error no bloqueante al cargar notificaciones admin: $e');
    }
  }

  // ===========================================================================
  // 5. GESTIÓN ADMINISTRATIVA DE EVENTOS (/admin/events)
  // ===========================================================================

  /// Carga todos los eventos administrables de la congregación activa.
  Future<void> loadAdminEvents({int limit = 50, int offset = 0}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.adminEvents(limit: limit, offset: offset);
      final rawList = res['events'] ?? res['items'] ?? res['data'] ?? [];
      if (rawList is List) {
        _adminEvents = rawList
            .map((e) => EventDto.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      debugPrint('[AdminProvider] Error al cargar eventos admin: $e');
    } catch (e) {
      _errorMessage = 'Error inesperado al cargar eventos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea un nuevo evento en Odoo 19 con soporte para streaming y modalidad.
  Future<bool> createEvent(EventDto event) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.adminCreateEvent(event.toJson());
      final rawItem = res['event'] ?? res['data'] ?? res;
      if (rawItem is Map) {
        final newEvent = EventDto.fromJson(Map<String, dynamic>.from(rawItem));
        _adminEvents.insert(0, newEvent);
      } else {
        await loadAdminEvents();
      }
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
      _errorMessage = 'Error al publicar evento: $e';
      notifyListeners();
      return false;
    }
  }

  /// Actualiza un evento existente en Odoo 19.
  Future<bool> updateEvent(EventDto event) async {
    if (event.id == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.adminUpdateEvent(event.id!, event.toJson());
      final rawItem = res['event'] ?? res['data'] ?? res;
      final updatedEvent = rawItem is Map
          ? EventDto.fromJson(Map<String, dynamic>.from(rawItem))
          : event;

      final index = _adminEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _adminEvents[index] = updatedEvent;
      } else {
        _adminEvents.insert(0, updatedEvent);
      }
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
      _errorMessage = 'Error al actualizar evento: $e';
      notifyListeners();
      return false;
    }
  }

  /// Elimina un evento en Odoo 19.
  Future<bool> deleteEvent(int eventId) async {
    try {
      await _api.adminDeleteEvent(eventId);
      _adminEvents.removeWhere((e) => e.id == eventId);
      notifyListeners();
      return true;
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // 6. GESTIÓN ADMINISTRATIVA DE PRÉDICAS Y LIVES (/admin/posts)
  // ===========================================================================

  /// Carga todas las prédicas y transmisiones en vivo administrables de la iglesia.
  Future<void> loadAdminSermons({int limit = 50, int offset = 0}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.adminPosts(limit: limit, offset: offset);
      final rawList = res['posts'] ?? res['items'] ?? res['data'] ?? [];
      if (rawList is List) {
        _adminSermons = rawList
            .map((e) => SermonDto.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      debugPrint('[AdminProvider] Error al cargar prédicas admin: $e');
    } catch (e) {
      _errorMessage = 'Error inesperado al cargar prédicas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Publica una nueva prédica o transmisión en vivo en Odoo 19.
  Future<bool> createSermon(SermonDto sermon) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.adminCreatePost(sermon.toJson());
      final rawItem = res['post'] ?? res['sermon'] ?? res['data'] ?? res;
      if (rawItem is Map) {
        final newSermon = SermonDto.fromJson(Map<String, dynamic>.from(rawItem));
        _adminSermons.insert(0, newSermon);
      } else {
        await loadAdminSermons();
      }
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
      _errorMessage = 'Error al publicar prédica o stream: $e';
      notifyListeners();
      return false;
    }
  }

  /// Actualiza una prédica o transmisión en Odoo 19.
  Future<bool> updateSermon(SermonDto sermon) async {
    if (sermon.id == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.adminUpdatePost(sermon.id!, sermon.toJson());
      final rawItem = res['post'] ?? res['sermon'] ?? res['data'] ?? res;
      final updatedSermon = rawItem is Map
          ? SermonDto.fromJson(Map<String, dynamic>.from(rawItem))
          : sermon;

      final index = _adminSermons.indexWhere((s) => s.id == sermon.id);
      if (index != -1) {
        _adminSermons[index] = updatedSermon;
      } else {
        _adminSermons.insert(0, updatedSermon);
      }
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
      _errorMessage = 'Error al actualizar prédica: $e';
      notifyListeners();
      return false;
    }
  }

  /// Elimina una prédica o transmisión de la iglesia en Odoo 19.
  Future<bool> deleteSermon(int sermonId) async {
    try {
      await _api.adminDeletePost(sermonId);
      _adminSermons.removeWhere((s) => s.id == sermonId);
      notifyListeners();
      return true;
    } on AtrioApiException catch (e) {
      _errorMessage = _traducirErrorOdoo(e);
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // TRADUCCIÓN DE ERRORES ODOO 19
  // ===========================================================================

  String _traducirErrorOdoo(AtrioApiException e) {
    if (e.code == 'read_only' || (e.isForbidden && e.message.toLowerCase().contains('read only'))) {
      return 'Acción denegada: cuenta en modo solo lectura.';
    }
    if (e.code == 'validation_error') {
      return 'Error de validación de permisos en la iglesia.';
    }
    if (e.code == 'required_fields') {
      return 'Por favor completa todos los campos requeridos para la publicación.';
    }
    if (e.code == 'church_required' || (e.status == 400 && e.message.toLowerCase().contains('church'))) {
      return 'Se requiere tener una iglesia asignada para esta acción pastoral.';
    }
    if (e.code == 'access_denied' || e.isForbidden) {
      return 'Permisos insuficientes: se requiere rol de Administrador de Iglesia.';
    }
    return e.message;
  }
}
