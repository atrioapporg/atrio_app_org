import 'package:flutter/foundation.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/admin_models.dart';

/// Provider para la gestión administrativa de la iglesia (Odoo 19 /admin/*)
/// Utilizado por roles church_admin y usuarios con permisos pastorales.
class AdminProvider extends ChangeNotifier {
  final AtrioApi api;
  AtrioApi get _api => api;

  List<AdminAnnouncementModel> _announcements = [];
  List<AdminGroupModel> _groups = [];
  List<AdminPrayerRequestModel> _prayerRequests = [];
  AdminAnalyticsModel? _analytics;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isPrayerRequestsWebOnly = false;
  bool _isAnalyticsWebOnly = false;

  AdminProvider({required this.api});

  List<AdminAnnouncementModel> get announcements => _announcements;
  List<AdminGroupModel> get groups => _groups;
  List<AdminPrayerRequestModel> get prayerRequests => _prayerRequests;
  AdminAnalyticsModel? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPrayerRequestsWebOnly => _isPrayerRequestsWebOnly;
  bool get isAnalyticsWebOnly => _isAnalyticsWebOnly;

  void clearError() {
    _errorMessage = null;
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
  // TRADUCCIÓN DE ERRORES ODOO 19
  // ===========================================================================

  String _traducirErrorOdoo(AtrioApiException e) {
    if (e.code == 'read_only' || (e.isForbidden && e.message.toLowerCase().contains('read only'))) {
      return 'Acción denegada: cuenta en modo solo lectura.';
    }
    if (e.code == 'validation_error') {
      return 'Error de validación de permisos en la iglesia.';
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
