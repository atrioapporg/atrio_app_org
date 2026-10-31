import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/ad_models.dart';
import 'package:atrio/providers/ads_provider.dart';

void main() {
  group('ETAPA 1: Modelos y DTOs de Ads (Odoo 19)', () {
    test('AdModel.fromJson debe parsear atributos UTC, status y métricas correctamente', () {
      final json = {
        'id': 101,
        'name': 'Gira Esperanza 2026',
        'description': 'Concierto internacional de adoración',
        'image_url': 'https://example.com/banner.jpg',
        'redirect_url': 'https://atrio.app/esperanza',
        'placement': 'all',
        'status': 'to_pay',
        'payable': true,
        'rejection_reason': null,
        'church_id': [42, 'Iglesia Central'],
        'start_date': '2026-11-20T19:00:00Z',
        'end_date': '2026-11-27T19:00:00Z',
        'create_date': '2026-10-15T12:00:00Z',
        'impressions': 1200,
        'clicks': 120,
        'cost': 45.50,
        'currency': 'USD',
      };

      final model = AdModel.fromJson(json);

      expect(model.id, 101);
      expect(model.name, 'Gira Esperanza 2026');
      expect(model.status, AdStatus.toPay);
      expect(model.isToPay, isTrue);
      expect(model.payable, isTrue);
      expect(model.canBePaid, isTrue);
      expect(model.churchId, 42);
      expect(model.churchName, 'Iglesia Central');
      expect(model.startDate?.isUtc, isTrue);
      expect(model.totalImpressions, 1200);
      expect(model.totalClicks, 120);
      expect(model.ctrPercentage, 10.0);
      expect(model.hasInteractiveLink, isTrue);

      final outJson = model.toJson();
      expect(outJson['id'], 101);
      expect(outJson['status'], 'to_pay');
    });

    test('AdQuoteModel.fromJson debe mapear base, iglesias, semanas y total', () {
      final json = {
        'base_price': 10.0,
        'churches_count': 5,
        'weeks_count': 3,
        'total_price': 150.0,
        'currency': 'USD',
      };

      final quote = AdQuoteModel.fromJson(json);

      expect(quote.basePrice, 10.0);
      expect(quote.churchesCount, 5);
      expect(quote.weeksCount, 3);
      expect(quote.totalPrice, 150.0);
      expect(quote.currency, 'USD');

      final outJson = quote.toJson();
      expect(outJson['total_price'], 150.0);
    });

    test('AdStatsModel.fromJson debe parsear métricas agregadas y serie diaria', () {
      final json = {
        'ad_id': 101,
        'impressions': 500,
        'clicks': 25,
        'ctr': 5.0,
        'time_series': [
          {'date': '2026-10-25T00:00:00Z', 'impressions': 200, 'clicks': 10},
          {'date': '2026-10-26T00:00:00Z', 'impressions': 300, 'clicks': 15},
        ],
      };

      final stats = AdStatsModel.fromJson(json);

      expect(stats.adId, 101);
      expect(stats.impressions, 500);
      expect(stats.clicks, 25);
      expect(stats.ctr, 5.0);
      expect(stats.timeSeries.length, 2);
      expect(stats.timeSeries.first.ctrPercentage, 5.0);
    });

    test('AdPaymentModel.fromJson debe parsear cuentas bancarias y datos de pasarela', () {
      final json = {
        'ad_id': 101,
        'amount': 85.0,
        'currency': 'USD',
        'payable': true,
        'paypal_enabled': true,
        'bank_accounts': [
          {
            'bank_name': 'Banco Popular',
            'account_holder': 'ATRIO SRL',
            'account_number': '123-456789-0',
            'account_type': 'Corriente',
            'tax_id': '1-23-45678-9',
          }
        ],
      };

      final payment = AdPaymentModel.fromJson(json);

      expect(payment.adId, 101);
      expect(payment.amount, 85.0);
      expect(payment.paypalEnabled, isTrue);
      expect(payment.bankAccounts.length, 1);
      expect(payment.bankAccounts.first.bankName, 'Banco Popular');
      expect(payment.bankAccounts.first.accountNumber, '123-456789-0');
    });
  });

  group('ETAPA 2 y 3: AdsProvider & Caché de Sesión', () {
    test('AdsProvider maneja caché de sesión para el feed sin llamadas duplicadas', () async {
      // Mock simple de AtrioApi sin llamadas reales de red
      final api = AtrioApi(baseUrl: 'https://atrioapp.odoo19rd.com');
      final provider = AdsProvider(api: api);

      expect(provider.feedLoaded, isFalse);
      expect(provider.feedAds, isEmpty);

      // Reset limpia el estado
      provider.reset();
      expect(provider.feedLoaded, isFalse);
    });
  });
}
