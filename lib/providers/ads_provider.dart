import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../atrio_api.dart';
import '../modelos/ad_models.dart';
import '../servicios/ads_service.dart';

/// Provider centralizado para la gestión del módulo de Publicidad y Anuncios (Ads) en ATRIO.
/// Maneja la caché de sesión para el feed de miembros, el registro de clics interactivos,
/// el cálculo reactivo de cotizaciones y el flujo administrativo de campañas para iglesias.
class AdsProvider extends ChangeNotifier {
  final AdsService _adsService;

  AdsProvider({required AtrioApi api}) : _adsService = AdsService(api: api);

  // ===========================================================================
  // 1. ESTADO DEL FEED DE ANUNCIOS (MIEMBROS)
  // ===========================================================================
  List<AdModel> _feedAds = [];
  bool _feedLoaded = false;
  bool _isFeedLoading = false;
  String? _feedError;

  List<AdModel> get feedAds => _feedAds;
  bool get feedLoaded => _feedLoaded;
  bool get isFeedLoading => _isFeedLoading;
  String? get feedError => _feedError;

  /// Carga los anuncios activos para la iglesia del usuario con caché de sesión.
  /// Si ya se cargaron y [forceRefresh] es false, omite la llamada de red para
  /// no generar impresiones duplicadas ni saturar el servidor en cada redibujado.
  Future<void> loadFeedAds({
    String placement = 'all',
    bool forceRefresh = false,
  }) async {
    if (_feedLoaded && !forceRefresh) return;
    if (_isFeedLoading) return;

    _isFeedLoading = true;
    _feedError = null;
    notifyListeners();

    try {
      final ads = await _adsService.getFeedAds(placement: placement);
      _feedAds = ads;
      _feedLoaded = true;
    } on AtrioApiException catch (e) {
      _feedError = e.message;
      debugPrint('[AdsProvider] Error al obtener anuncios del feed: $e');
    } catch (e) {
      _feedError = e.toString();
      debugPrint('[AdsProvider] Error inesperado en feed ads: $e');
    } finally {
      _isFeedLoading = false;
      notifyListeners();
    }
  }

  /// Registra el clic en el servidor Odoo y abre el enlace de destino de forma segura.
  /// Cumple la regla estricta: Se invoca `POST /ads/{ad_id}/click` antes de abrir
  /// la URL en el navegador externo con [LaunchMode.externalApplication].
  /// Si el servidor devuelve redirect_url null, no se abre ningún enlace.
  Future<bool> handleAdClick(BuildContext context, AdModel ad) async {
    String? targetUrl;

    try {
      // 1. Registro obligatorio del clic en el backend antes de la navegación
      final serverRedirect = await _adsService.registerClick(ad.id);
      if (serverRedirect != null && serverRedirect.trim().isNotEmpty) {
        targetUrl = serverRedirect.trim();
      } else {
        targetUrl = ad.linkUrl ?? ad.redirectUrl;
      }
    } catch (e) {
      debugPrint('[AdsProvider] No se pudo registrar el clic en el servidor: $e');
      targetUrl = ad.linkUrl ?? ad.redirectUrl;
    }

    if (targetUrl == null || targetUrl.trim().isEmpty) {
      // El anuncio no tiene URL de destino configurada en Odoo
      return false;
    }

    // 2. Apertura externa segura en navegador del sistema
    try {
      final uri = Uri.parse(targetUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e) {
      debugPrint('[AdsProvider] Error al abrir enlace publicitario: $e');
      return false;
    }
  }

  // ===========================================================================
  // 2. ESTADO ADMINISTRATIVO DE CAMPAÑAS (IGLESIAS - PERMISO: manage_ads)
  // ===========================================================================
  List<AdModel> _churchAds = [];
  bool _isAdminLoading = false;
  String? _adminError;
  AdStatus? _statusFilter;

  List<AdModel> get churchAds {
    if (_statusFilter == null) return _churchAds;
    return _churchAds.where((a) => a.status == _statusFilter).toList();
  }

  List<AdModel> get allChurchAds => _churchAds;
  bool get isAdminLoading => _isAdminLoading;
  String? get adminError => _adminError;
  AdStatus? get statusFilter => _statusFilter;

  void setStatusFilter(AdStatus? filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void clearAdminError() {
    _adminError = null;
    notifyListeners();
  }

  /// Carga todas las campañas creadas por la iglesia del administrador.
  Future<void> loadChurchAds({bool force = false}) async {
    if (_isAdminLoading) return;
    _isAdminLoading = true;
    _adminError = null;
    notifyListeners();

    try {
      final ads = await _adsService.getMyChurchAds();
      _churchAds = ads;
    } on AtrioApiException catch (e) {
      _adminError = e.message;
      debugPrint('[AdsProvider] Error cargando campañas de la iglesia: $e');
    } catch (e) {
      _adminError = e.toString();
      debugPrint('[AdsProvider] Error inesperado en loadChurchAds: $e');
    } finally {
      _isAdminLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 3. COTIZACIÓN REACTIVA DE CAMPAÑA
  // ===========================================================================
  AdQuoteModel? _currentQuote;
  bool _isQuoting = false;
  String? _quoteError;

  AdQuoteModel? get currentQuote => _currentQuote;
  bool get isQuoting => _isQuoting;
  String? get quoteError => _quoteError;

  void clearQuote() {
    _currentQuote = null;
    _quoteError = null;
    notifyListeners();
  }

  /// Calcula la cotización de la campaña en vivo comunicándose con Odoo 19 ERP.
  Future<AdQuoteModel?> calculateQuote({
    String delivery = 'both',
    int durationWeeks = 2,
    String targetScope = 'location',
    List<int> countryIds = const [],
    List<int> stateIds = const [],
    List<String> cities = const [],
    List<int> churchIds = const [],
    // Compatibilidad:
    int? targetChurchesCount,
    int? weeks,
    List<int>? targetChurchIds,
    List<int>? targetCountryIds,
    String? placement,
  }) async {
    _isQuoting = true;
    _quoteError = null;
    notifyListeners();

    try {
      final quote = await _adsService.quoteAd(
        delivery: delivery,
        durationWeeks: durationWeeks,
        targetScope: targetScope,
        countryIds: countryIds,
        stateIds: stateIds,
        cities: cities,
        churchIds: churchIds,
        targetChurchesCount: targetChurchesCount,
        weeks: weeks,
        targetChurchIds: targetChurchIds,
        targetCountryIds: targetCountryIds,
        placement: placement,
      );
      _currentQuote = quote;
      return quote;
    } on AtrioApiException catch (e) {
      _quoteError = e.message;
      debugPrint('[AdsProvider] Error en cotización Odoo: $e');
      return null;
    } catch (e) {
      _quoteError = e.toString();
      debugPrint('[AdsProvider] Error inesperado en calculateQuote: $e');
      return null;
    } finally {
      _isQuoting = false;
      notifyListeners();
    }
  }

  /// Crea y envía una nueva campaña a revisión en Atrio.
  Future<AdModel?> createCampaign({
    required String name,
    required String imageBase64,
    String? message,
    String? linkUrl,
    String? ctaLabel,
    String delivery = 'both',
    String targetScope = 'location',
    List<int> countryIds = const [],
    List<int> stateIds = const [],
    List<String> cities = const [],
    List<int> churchIds = const [],
    int durationWeeks = 2,
    DateTime? dateStart,
    // Compatibilidad previa:
    String? description,
    String? redirectUrl,
    String placement = 'all',
    int weeks = 1,
    List<int>? targetChurchIds,
    List<int>? targetCountryIds,
  }) async {
    _isAdminLoading = true;
    _adminError = null;
    notifyListeners();

    try {
      final created = await _adsService.createAd(
        name: name,
        imageBase64: imageBase64,
        message: message,
        linkUrl: linkUrl,
        ctaLabel: ctaLabel,
        delivery: delivery,
        targetScope: targetScope,
        countryIds: countryIds,
        stateIds: stateIds,
        cities: cities,
        churchIds: churchIds,
        durationWeeks: durationWeeks,
        dateStart: dateStart,
        description: description,
        redirectUrl: redirectUrl,
        placement: placement,
        weeks: weeks,
        targetChurchIds: targetChurchIds,
        targetCountryIds: targetCountryIds,
      );
      _churchAds.insert(0, created);
      return created;
    } on AtrioApiException catch (e) {
      _adminError = e.message;
      debugPrint('[AdsProvider] Error al crear campaña: $e');
      return null;
    } catch (e) {
      _adminError = e.toString();
      debugPrint('[AdsProvider] Error inesperado al crear campaña: $e');
      return null;
    } finally {
      _isAdminLoading = false;
      notifyListeners();
    }
  }

  /// Cancela o retira una solicitud de anuncio en revisión.
  Future<bool> cancelCampaign(int adId) async {
    _isAdminLoading = true;
    _adminError = null;
    notifyListeners();

    try {
      final ok = await _adsService.cancelAd(adId);
      if (ok) {
        _churchAds.removeWhere((a) => a.id == adId);
      }
      return ok;
    } on AtrioApiException catch (e) {
      _adminError = e.message;
      debugPrint('[AdsProvider] Error cancelando campaña: $e');
      return false;
    } catch (e) {
      _adminError = e.toString();
      return false;
    } finally {
      _isAdminLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 4. PASARELA DE PAGOS (PAYPAL Y TRANSFERENCIA BANCARIA)
  // ===========================================================================
  AdPaymentModel? _currentPayment;
  bool _isPaymentLoading = false;
  String? _paymentError;

  AdPaymentModel? get currentPayment => _currentPayment;
  bool get isPaymentLoading => _isPaymentLoading;
  String? get paymentError => _paymentError;

  /// Obtiene los detalles de pago (monto y cuenta bancaria de transferencia) para una campaña aprobada.
  Future<AdPaymentModel?> loadPaymentDetails(int adId) async {
    _isPaymentLoading = true;
    _paymentError = null;
    notifyListeners();

    try {
      final details = await _adsService.getPaymentDetails(adId);
      _currentPayment = details;
      return details;
    } on AtrioApiException catch (e) {
      _paymentError = e.message;
      debugPrint('[AdsProvider] Error obteniendo datos de pago: $e');
      return null;
    } catch (e) {
      _paymentError = e.toString();
      return null;
    } finally {
      _isPaymentLoading = false;
      notifyListeners();
    }
  }

  /// Inicia el flujo de PayPal obteniendo la URL externa de checkout y abriéndola en el navegador.
  /// Siguiendo la recomendación técnica de Odoo 19: al regresar a la app, se refrescan las campañas.
  Future<bool> processPaypalPayment(int adId) async {
    _isPaymentLoading = true;
    _paymentError = null;
    notifyListeners();

    try {
      final checkoutUrl = await _adsService.payWithPaypal(adId);
      final uri = Uri.parse(checkoutUrl);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      // Tras lanzar PayPal, programamos un refresco de campañas
      unawaited(loadChurchAds(force: true));
      return launched;
    } on AtrioApiException catch (e) {
      _paymentError = e.message;
      debugPrint('[AdsProvider] Error iniciando PayPal: $e');
      return false;
    } catch (e) {
      _paymentError = e.toString();
      return false;
    } finally {
      _isPaymentLoading = false;
      notifyListeners();
    }
  }

  /// Envía el comprobante de transferencia bancaria en Base64 con su referencia.
  Future<bool> submitTransferPayment(
    int adId, {
    required String receiptBase64,
    required String receiptFilename,
    String? reference,
  }) async {
    _isPaymentLoading = true;
    _paymentError = null;
    notifyListeners();

    try {
      final success = await _adsService.payWithTransfer(
        adId,
        receiptBase64: receiptBase64,
        receiptFilename: receiptFilename,
        reference: reference,
      );
      if (success) {
        // Actualizamos localmente el estado de la campaña a payment_review
        final index = _churchAds.indexWhere((a) => a.id == adId);
        if (index != -1) {
          _churchAds[index] = _churchAds[index].copyWith(
            status: AdStatus.paymentReview,
            statusLabel: 'Comprobante en revisión',
          );
        }
      }
      return success;
    } on AtrioApiException catch (e) {
      _paymentError = e.message;
      debugPrint('[AdsProvider] Error enviando comprobante de transferencia: $e');
      return false;
    } catch (e) {
      _paymentError = e.toString();
      return false;
    } finally {
      _isPaymentLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 5. RENDIMIENTO Y ESTADÍSTICAS
  // ===========================================================================
  AdStatsModel? _currentStats;
  bool _isStatsLoading = false;
  String? _statsError;

  AdStatsModel? get currentStats => _currentStats;
  bool get isStatsLoading => _isStatsLoading;
  String? get statsError => _statsError;

  /// Carga las métricas y series temporales de un anuncio desde Odoo 19.
  Future<AdStatsModel?> loadStats(int adId) async {
    _isStatsLoading = true;
    _statsError = null;
    notifyListeners();

    try {
      final stats = await _adsService.getStats(adId);
      _currentStats = stats;
      return stats;
    } on AtrioApiException catch (e) {
      _statsError = e.message;
      debugPrint('[AdsProvider] Error cargando estadísticas: $e');
      return null;
    } catch (e) {
      _statsError = e.toString();
      return null;
    } finally {
      _isStatsLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 6. TARGETS Y AUDIENCIAS
  // ===========================================================================
  /// Consulta opciones de segmentación: [kind] = 'country', 'state', 'city', 'church'.
  Future<List<AdTargetModel>> searchTargets({
    required String kind,
    String q = '',
    List<int> countryIds = const [],
  }) async {
    try {
      return await _adsService.getTargets(
        kind: kind,
        q: q,
        countryIds: countryIds,
      );
    } catch (e) {
      debugPrint('[AdsProvider] Error buscando targets: $e');
      return [];
    }
  }

  /// Limpia todo el estado en memoria al cerrar sesión
  void reset() {
    _feedAds = [];
    _feedLoaded = false;
    _isFeedLoading = false;
    _feedError = null;

    _churchAds = [];
    _isAdminLoading = false;
    _adminError = null;
    _statusFilter = null;

    _currentQuote = null;
    _isQuoting = false;
    _quoteError = null;

    _currentPayment = null;
    _isPaymentLoading = false;
    _paymentError = null;

    _currentStats = null;
    _isStatsLoading = false;
    _statsError = null;

    notifyListeners();
  }
}
