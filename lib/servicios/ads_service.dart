import 'dart:async';
import 'package:flutter/foundation.dart';
import '../atrio_api.dart';
import '../modelos/ad_models.dart';

/// Servicio de red especializado en el ciclo de vida y consumo del módulo
/// de Publicidad y Gestión de Anuncios (Ads) en Odoo 19 ERP para ATRIO.
class AdsService {
  final AtrioApi api;

  AdsService({required this.api});

  // ===========================================================================
  // MÓDULO DE MIEMBROS: VISUALIZACIÓN Y CLICS
  // ===========================================================================

  /// Obtiene los anuncios activos correspondientes a la iglesia del usuario autenticado.
  /// Parámetro [placement]: 'all', 'post' o 'notification'.
  /// Endpoint: `GET /ads?placement={placement}`
  Future<List<AdModel>> getFeedAds({String placement = 'all'}) async {
    try {
      final res = await api.ads(placement: placement);
      final rawList = res['ads'] ?? res['items'] ?? res['data'] ?? [];
      if (rawList is List) {
        return rawList
            .map((e) => AdModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[AdsService] Error inesperado en getFeedAds: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Registra un clic en el anuncio antes de redirigir al enlace de destino.
  /// Endpoint: `POST /ads/{ad_id}/click`
  /// Retorna la URL de redirección `redirect_url` provista por Odoo 19 (o null si no tiene destino).
  Future<String?> registerClick(int adId) async {
    try {
      final res = await api.clickAd(adId);
      final redirectUrl = res['redirect_url']?.toString() ??
          res['action_url']?.toString() ??
          res['url']?.toString();
      return redirectUrl;
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[AdsService] Error inesperado en registerClick: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  // ===========================================================================
  // MÓDULO DE ADMINISTRACIÓN DE ANUNCIOS (IGLESIAS - PERMISO: manage_ads)
  // ===========================================================================

  /// Retorna las campañas de anuncios creadas por la iglesia del administrador.
  /// Endpoint: `GET /admin/ads`
  Future<List<AdModel>> getMyChurchAds() async {
    try {
      final res = await api.myChurchAds();
      final rawList = res['ads'] ?? res['items'] ?? res['data'] ?? [];
      if (rawList is List) {
        return rawList
            .map((e) => AdModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[AdsService] Error inesperado en getMyChurchAds: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Consulta las opciones de segmentación disponibles para pautar anuncios.
  /// [kind]: 'church', 'denomination', 'country'.
  /// Endpoint: `GET /admin/ads/targets`
  Future<List<AdTargetModel>> getTargets({
    required String kind,
    String q = '',
    List<int> countryIds = const [],
  }) async {
    try {
      final res = await api.adTargets(kind, q: q, countryIds: countryIds);
      final rawList = res['targets'] ?? res['items'] ?? res['data'] ?? [];
      if (rawList is List) {
        return rawList
            .map((e) => AdTargetModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[AdsService] Error inesperado en getTargets: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Cotiza el costo de una campaña publicitaria en tiempo real según la segmentación.
  /// Endpoint: `POST /admin/ads/quote`
  Future<AdQuoteModel> quoteAd({
    required int targetChurchesCount,
    required int weeks,
    List<int>? targetChurchIds,
    List<int>? targetCountryIds,
    String? placement,
  }) async {
    try {
      final body = <String, dynamic>{
        'churches_count': targetChurchesCount,
        'weeks': weeks,
        if (targetChurchIds != null && targetChurchIds.isNotEmpty)
          'church_ids': targetChurchIds,
        if (targetCountryIds != null && targetCountryIds.isNotEmpty)
          'country_ids': targetCountryIds,
        'placement': ?placement,
      };

      final res = await api.quoteAd(body);
      return AdQuoteModel.fromJson(res);
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[AdsService] Error inesperado en quoteAd: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Envía un nuevo anuncio publicitario a revisión de Atrio.
  /// Endpoint: `POST /admin/ads`
  Future<AdModel> createAd({
    required String name,
    required String imageBase64,
    String? description,
    String? redirectUrl,
    String placement = 'all',
    int weeks = 1,
    List<int>? targetChurchIds,
    List<int>? targetCountryIds,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name.trim(),
        'image': imageBase64,
        'placement': placement,
        'weeks': weeks,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (redirectUrl != null && redirectUrl.trim().isNotEmpty)
          'redirect_url': redirectUrl.trim(),
        if (targetChurchIds != null && targetChurchIds.isNotEmpty)
          'target_church_ids': targetChurchIds,
        if (targetCountryIds != null && targetCountryIds.isNotEmpty)
          'target_country_ids': targetCountryIds,
      };

      final res = await api.submitAd(body);
      final rawAd = res['ad'] ?? res['item'] ?? res;
      if (rawAd is Map<String, dynamic>) {
        return AdModel.fromJson(rawAd);
      } else if (rawAd is Map) {
        return AdModel.fromJson(Map<String, dynamic>.from(rawAd));
      }
      throw AtrioApiException(500, 'invalid_response', 'Estructura de respuesta no válida al crear anuncio');
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[AdsService] Error inesperado en createAd: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Cancela o retira una solicitud de anuncio aún no revisada.
  /// Endpoint: `DELETE /admin/ads/{id}`
  Future<bool> cancelAd(int adId) async {
    try {
      await api.cancelAd(adId);
      return true;
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[AdsService] Error inesperado en cancelAd: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Consulta la pasarela y datos de pago de una campaña aprobada (`to_pay`).
  /// Endpoint: `GET /admin/ads/{id}/payment`
  Future<AdPaymentModel> getPaymentDetails(int adId) async {
    try {
      final res = await api.adPayment(adId);
      return AdPaymentModel.fromJson(res);
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[AdsService] Error inesperado en getPaymentDetails: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Inicia el flujo de pago con PayPal.
  /// Endpoint: `POST /admin/ads/{id}/pay/paypal`
  /// Retorna la URL de checkout (`checkout_url`) para abrir externamente.
  Future<String> payWithPaypal(int adId) async {
    try {
      final res = await api.payAdWithPaypal(adId);
      final checkoutUrl = res['checkout_url']?.toString() ??
          res['approval_url']?.toString() ??
          res['url']?.toString();
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw AtrioApiException(500, 'paypal_error', 'No se recibió la URL de pago de PayPal');
      }
      return checkoutUrl;
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[AdsService] Error inesperado en payWithPaypal: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Registra el pago por transferencia bancaria adjuntando comprobante en Base64.
  /// Endpoint: `POST /admin/ads/{id}/pay/transfer`
  Future<bool> payWithTransfer(
    int adId, {
    required String receiptBase64,
    String receiptFilename = 'comprobante.jpg',
    String? reference,
  }) async {
    try {
      await api.payAdWithTransfer(
        adId,
        receiptBase64,
        receiptFilename: receiptFilename,
        reference: reference,
      );
      return true;
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[AdsService] Error inesperado en payWithTransfer: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Obtiene las estadísticas de rendimiento (impresiones, clics, CTR e historial) de un anuncio.
  /// Endpoint: `GET /admin/ads/{id}/stats`
  Future<AdStatsModel> getStats(int adId) async {
    try {
      final res = await api.adStats(adId);
      return AdStatsModel.fromJson(res);
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[AdsService] Error inesperado en getStats: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }
}
