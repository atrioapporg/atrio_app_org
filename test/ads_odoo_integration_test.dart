import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/modelos/ad_models.dart';

void main() {
  group('Pruebas de Modelos y Contratos Odoo 19 ERP - Módulo Publicidad', () {
    test('1. Targets de segmentación (GET /admin/ads/targets)', () {
      final rawTargets = {
        "options": [
          {"id": 61, "label": "República Dominicana", "hint": "9 iglesias", "churches": 9},
          {"id": 40, "label": "República Centroafricana", "hint": "1 iglesia", "churches": 1}
        ]
      };
      final targetList = (rawTargets['options'] as List)
          .map((e) => AdTargetModel.fromJson(e, defaultKind: 'country'))
          .toList();

      expect(targetList.length, 2);
      expect(targetList.first.id, 61);
      expect(targetList.first.label, "República Dominicana");
      expect(targetList.first.hint, "9 iglesias");
      expect(targetList.first.churches, 9);
      expect(targetList.first.name, "República Dominicana"); // retrocompatibilidad
    });

    test('2. Cotización y Alcance (POST /admin/ads/quote)', () {
      final rawQuote = {
        "quote": {
          "amount": 92.0,
          "currency": "USD",
          "weeks": 2,
          "churches": 8,
          "base": 30.0,
          "per_church": 2.0,
          "per_week": 46.0,
          "min_applied": false
        },
        "reach": {
          "churches": 8,
          "members": 27,
          "sample": ["Comunidad Atrio", "Parroquia Nuestra Señora de la Fe"]
        }
      };
      final quoteModel = AdQuoteModel.fromJson(rawQuote);

      expect(quoteModel.totalPrice, 92.0);
      expect(quoteModel.amount, 92.0);
      expect(quoteModel.currency, "USD");
      expect(quoteModel.churchesCount, 8);
      expect(quoteModel.weeksCount, 2);
      expect(quoteModel.basePrice, 30.0);
      expect(quoteModel.quote.perChurch, 2.0);
      expect(quoteModel.quote.perWeek, 46.0);
      expect(quoteModel.minApplied, false);

      expect(quoteModel.reach, isNotNull);
      expect(quoteModel.reach!.churches, 8);
      expect(quoteModel.reach!.members, 27);
      expect(quoteModel.reach!.sample.length, 2);
    });

    test('3. Campañas de Administrador de Iglesia (GET /admin/ads)', () {
      final rawAds = {
        "ads": [
          {
            "id": 2,
            "name": "Life 2026",
            "message": "Life life life",
            "write_date": "2026-09-27T07:16:10Z",
            "delivery_label": "Notificación e inicio",
            "status": "active",
            "status_label": "Activa",
            "status_color": "green",
            "budget": 480.0,
            "currency": "USD",
            "date_start": "2026-09-27T07:16:10Z",
            "duration_weeks": 12,
            "impressions": 28,
            "clicks": 0,
            "ctr": 0.0,
            "payable": false,
            "image_url": "/atrio/ad/2/image"
          }
        ]
      };
      final churchAds = (rawAds['ads'] as List)
          .map((e) => AdModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      expect(churchAds.length, 1);
      final ad = churchAds.first;
      expect(ad.id, 2);
      expect(ad.name, "Life 2026");
      expect(ad.message, "Life life life");
      expect(ad.status, AdStatus.active);
      expect(ad.statusLabel, "Activa");
      expect(ad.imageUrl, startsWith('https://'));
      expect(ad.canBePaid, false);
      expect(ad.totalImpressions, 28);
    });

    test('4. Feed de Anuncios para Miembros (GET /ads?placement=all)', () {
      final rawFeed = {
        "ads": [
          {
            "id": 4,
            "sponsored": true,
            "label": "Publicidad",
            "placement": "both",
            "title": "Prueba Publicidad",
            "message": "Prueba Publicidad",
            "image_url": "/atrio/portal/api/image/atrio.ad.campaign/4/image",
            "advertiser": "Parroquia San Pedro Nolasco",
            "cta_label": "Ver más",
            "has_link": false,
            "click_url": "/atrio/portal/api/ads/4/click",
            "published_at": "2026-10-31T06:00:00Z"
          }
        ]
      };
      final feedAds = (rawFeed['ads'] as List)
          .map((e) => AdModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      expect(feedAds.length, 1);
      final ad = feedAds.first;
      expect(ad.id, 4);
      expect(ad.name, "Prueba Publicidad");
      expect(ad.ctaLabel, "Ver más");
      expect(ad.clickUrl, "/atrio/portal/api/ads/4/click");
      expect(ad.imageUrl, startsWith('https://'));
    });

    test('5. Datos de Pasarela de Pago (GET /admin/ads/{id}/payment)', () {
      final rawPayment = {
        "payable": true,
        "payment_status": "unpaid",
        "amount": 76.0,
        "currency": "USD",
        "reference": "ATRIO-AD-40",
        "rejection_reason": null,
        "paypal_available": true,
        "transfer": {
          "bank_name": "Banco Popular",
          "account_holder": "Atrio Plataforma",
          "account_number": "798412356",
          "currency": "DOP",
          "iban": null
        }
      };
      final payment = AdPaymentModel.fromJson(rawPayment);

      expect(payment.payable, true);
      expect(payment.amount, 76.0);
      expect(payment.currency, "USD");
      expect(payment.reference, "ATRIO-AD-40");
      expect(payment.paypalAvailable, true);
      expect(payment.transfer, isNotNull);
      expect(payment.transfer!.bankName, "Banco Popular");
      expect(payment.transfer!.accountHolder, "Atrio Plataforma");
      expect(payment.transfer!.accountNumber, "798412356");
      expect(payment.bankAccounts.length, 1);
    });

    test('6. Rendimiento y Estadísticas (GET /admin/ads/{id}/stats)', () {
      final rawStats = {
        "stats": {
          "impressions": 404,
          "clicks": 54,
          "unique_clicks": 40,
          "ctr": 13.37,
          "series": {
            "labels": ["2026-09-26", "2026-09-27"],
            "impressions": [20, 35],
            "clicks": [3, 5]
          },
          "by_country": [],
          "by_church": [],
          "by_channel": [],
          "recent_clicks": []
        }
      };
      final stats = AdStatsModel.fromJson(rawStats);

      expect(stats.impressions, 404);
      expect(stats.clicks, 54);
      expect(stats.uniqueClicks, 40);
      expect(stats.ctr, 13.37);
      expect(stats.series.labels.length, 2);
      expect(stats.timeSeries.length, 2);
      expect(stats.timeSeries.first.impressions, 20);
      expect(stats.timeSeries.last.clicks, 5);
      expect(stats.timeSeries.first.dateLabel, "2026-09-26");
    });
  });
}
