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
  // 3. MODERACIÓN DE PETICIONES DE ORACIÓN (/admin/prayer-requests)
  // ===========================================================================

  /// Consulta peticiones de oración para moderación pastoral.
  /// Si el endpoint no existe en el backend Odoo (clasificado como punto pendiente),
  /// activa el fallback informativo hacia la consola web (/atrio/manage).
  Future<void> loadPrayerRequests({String status = 'pending'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.adminPrayerRequests(status: status);
      _isPrayerRequestsWebOnly = false;
      final rawList = res['prayer_requests'] ?? res['items'] ?? res['requests'] ?? [];
      if (rawList is List) {
        _prayerRequests = rawList
            .map((e) => AdminPrayerRequestModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } on AtrioApiException catch (e) {
      if (e.status == 404 || e.code == 'not_found' || e.code == 'endpoint_not_found') {
        _isPrayerRequestsWebOnly = true;
        _errorMessage =
            'La moderación de solicitudes pastorales se gestiona actualmente desde la consola web (/atrio/manage).';
        debugPrint(
          'ℹ️ [AdminProvider] Endpoint /admin/prayer-requests pendiente en Odoo. Activando vista informativa de consola web: $e',
        );
      } else {
        _errorMessage = _traducirErrorOdoo(e);
        debugPrint('[AdminProvider] Error al cargar peticiones: $e');
      }
    } catch (e) {
      _errorMessage = 'Error al consultar peticiones: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Modera una petición de oración (approve o reject).
  Future<bool> moderatePrayerRequest({
    required int requestId,
    required bool approve,
    String? reason,
  }) async {
    final action = approve ? 'approve' : 'reject';
    try {
      await _api.adminModeratePrayerRequest(
        requestId: requestId,
        action: action,
        reason: reason,
      );

      // Actualizar el estado en la lista local reactivamente
      final index = _prayerRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        final current = _prayerRequests[index];
        _prayerRequests[index] = AdminPrayerRequestModel(
          id: current.id,
          title: current.title,
          description: current.description,
          applicantName: current.applicantName,
          applicantEmail: current.applicantEmail,
          state: approve ? 'approved' : 'rejected',
          isAnonymous: current.isAnonymous,
          createDate: current.createDate,
          moderationReason: reason,
          moderationDate: DateTime.now().toIso8601String(),
        );
        notifyListeners();
      }
      return true;
    } on AtrioApiException catch (e) {
      if (e.status == 404 || e.code == 'not_found') {
        _errorMessage =
            'Esta función de moderación se debe responder desde la consola web (/atrio/manage).';
      } else {
        _errorMessage = _traducirErrorOdoo(e);
      }
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado al moderar petición: $e';
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // 4. ESTADÍSTICAS Y ANALÍTICA DE COMUNIDAD (/admin/analytics)
  // ===========================================================================

  /// Carga métricas y estadísticas consolidadas de la iglesia.
  /// Si el endpoint no existe en la API de Odoo (punto pendiente de especificación),
  /// activa el fallback transparente hacia las métricas reales disponibles (anuncios).
  Future<void> loadAnalytics({String period = 'month'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.adminAnalytics(period: period);
      _isAnalyticsWebOnly = false;
      _analytics = AdminAnalyticsModel.fromJson(res);
    } on AtrioApiException catch (e) {
      if (e.status == 404 || e.code == 'not_found' || e.code == 'endpoint_not_found') {
        _isAnalyticsWebOnly = true;
        debugPrint(
          'ℹ️ [AdminProvider] Endpoint /admin/analytics pendiente en Odoo. Activando fallback de anuncios: $e',
        );

        // Fallback resiliente: consultar estadísticas de anuncios propios de la iglesia
        try {
          final adsRes = await _api.myChurchAds();
          final rawAds = adsRes['ads'] ?? adsRes['items'] ?? [];
          final int adsCount = rawAds is List ? rawAds.length : 0;
          _analytics = AdminAnalyticsModel(
            period: period,
            rawMetrics: {'church_ads_count': adsCount},
          );
        } catch (_) {
          _analytics = AdminAnalyticsModel(period: period);
        }

        _errorMessage =
            'Las estadísticas comunitarias consolidadas se consultan en el portal web. En la app puedes consultar el rendimiento de tus anuncios.';
      } else {
        _errorMessage = _traducirErrorOdoo(e);
        debugPrint('[AdminProvider] Error al cargar analítica: $e');
      }
    } catch (e) {
      _errorMessage = 'Error al cargar analítica: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
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
