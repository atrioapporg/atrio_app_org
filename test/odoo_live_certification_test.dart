import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/ad_models.dart';
import 'package:atrio/modelos/moderation_models.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/servicios/ads_service.dart';
import 'package:atrio/servicios/moderation_service.dart';

/// Permite llamadas HTTP reales hacia el servidor en vivo de Odoo durante las pruebas.
class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  HttpOverrides.global = _RealHttpOverrides();

  const String baseUrl = 'https://atrioapp.odoo19rd.com';

  // Credenciales provistas para la certificación
  const String superAdminUser = 'leningrado777@gmail.com';
  const String superAdminPass = 'leningrado777@gmail';

  const String churchAdminUser = 'admin.atrio@demo.app';
  const String churchAdminPass = 'admin';

  const String memberUser = 'leningrado777@demo.app';
  const String memberPass = '123456';

  late AtrioApi superAdminApi;
  late AtrioApi churchAdminApi;
  late AtrioApi memberApi;

  late ModerationService superAdminModService;
  late AdsService memberAdsService;
  late AdsService churchAdsService;

  setUpAll(() {
    superAdminApi = AtrioApi(baseUrl: baseUrl, enableLogging: false);
    churchAdminApi = AtrioApi(baseUrl: baseUrl, enableLogging: false);
    memberApi = AtrioApi(baseUrl: baseUrl, enableLogging: false);

    superAdminModService = ModerationService(api: superAdminApi);
    memberAdsService = AdsService(api: memberApi);
    churchAdsService = AdsService(api: churchAdminApi);
  });

  // ===========================================================================
  // BATERÍA 1: AUTENTICACIÓN Y ROLES EN ODOO 19
  // ===========================================================================
  group('Batería 1: Autenticación, Sesión y Roles (Odoo 19 Backend)', () {
    test(
      '1.1 Login de Superadmin y verificación de rol platform_admin',
      () async {
        final res = await superAdminApi.login(superAdminUser, superAdminPass);
        expect(res, isNotNull);
        expect(superAdminApi.token, isNotNull);
        expect(superAdminApi.token!.isNotEmpty, isTrue);

        final meData = await superAdminApi.me();
        final user = UserModel.fromOdooJson(meData);

        expect(user.email.toLowerCase(), equals(superAdminUser.toLowerCase()));
        expect(
          user.isPlatformAdmin,
          isTrue,
          reason: 'El usuario debe poseer el rol platform_admin en Odoo',
        );
        superAdminApi.isReadOnly = user.isReadOnly;
      },
    );

    test(
      '1.2 Login de Admin de Iglesia y verificación de rol church_admin',
      () async {
        final res = await churchAdminApi.login(
          churchAdminUser,
          churchAdminPass,
        );
        expect(res, isNotNull);
        expect(churchAdminApi.token, isNotNull);

        final meData = await churchAdminApi.me();
        final user = UserModel.fromOdooJson(meData);

        expect(
          user.isChurchAdmin,
          isTrue,
          reason: 'El usuario admin.atrio@demo.app debe tener rol church_admin',
        );
        churchAdminApi.defaultChurchId = user.iglesiaId;
        churchAdminApi.isReadOnly = user.isReadOnly;
      },
    );

    test(
      '1.3 Login de Miembro de Iglesia y verificación de rol member/user',
      () async {
        final res = await memberApi.login(memberUser, memberPass);
        expect(res, isNotNull);
        expect(memberApi.token, isNotNull);

        final meData = await memberApi.me();
        final user = UserModel.fromOdooJson(meData);

        expect(user.isPlatformAdmin, isFalse);
        expect(user.isChurchAdmin, isFalse);
        memberApi.defaultChurchId = user.iglesiaId;
        memberApi.isReadOnly = user.isReadOnly;
      },
    );
  });

  // ===========================================================================
  // BATERÍA 2: MODERACIÓN DE PLATAFORMA (SUPER ADMIN)
  // ===========================================================================
  group(
    'Batería 2: Módulo de Moderación de Plataforma (/platform/moderation)',
    () {
      test('2.1 GET /platform/moderation/summary devuelve contadores y mapea a ModerationSummaryModel', () async {
        final summary = await superAdminModService.getSummary();
        expect(summary, isA<ModerationSummaryModel>());
        expect(summary.post, isNotNull);
        expect(summary.event, isNotNull);
        expect(summary.notification, isNotNull);
        expect(summary.totalFlagged, greaterThanOrEqualTo(0));
        expect(summary.totalBanned, greaterThanOrEqualTo(0));
      });

      test('2.2 GET /platform/moderation/content lista elementos marcados/bloqueados', () async {
        final content = await superAdminModService.getContent(
          type: 'post',
          status: 'flagged',
          limit: 10,
          offset: 0,
        );

        expect(content.total, greaterThanOrEqualTo(0));
        expect(content.items, isA<List<ModeratedItemModel>>());

        if (content.items.isNotEmpty) {
          final first = content.items.first;
          expect(first.id, greaterThan(0));
          expect(first.type, equals('post'));
        }
      });

      test('2.3 GET /platform/moderation/words lista el catálogo de palabras restringidas', () async {
        final words = await superAdminModService.getWords();
        expect(words, isA<List<ModerationWordModel>>());
      });

      test(
        '2.4 Ciclo CRUD completo de palabra restringida (POST, PATCH, DELETE)',
        () async {
          final uniqueWord =
              'cert_test_${DateTime.now().millisecondsSinceEpoch}';

          // 1. Crear palabra
          final createdWord = await superAdminModService.createWord(
            word: uniqueWord,
            mode: 'flag',
            wholeWord: true,
            note: 'Palabra de prueba generada por suite de certificación',
          );

          expect(createdWord, isNotNull);
          expect(createdWord.word, equals(uniqueWord));
          expect(createdWord.mode, equals('flag'));
          expect(createdWord.isFlag, isTrue);

          final wordId = createdWord.id;

          // 2. Editar palabra (pausar con active: false)
          final updatedWord = await superAdminModService.updateWord(
            wordId,
            active: false,
            note: 'Palabra pausada en suite de certificación',
          );

          expect(updatedWord, isNotNull);
          expect(updatedWord.active, isFalse);

          // 3. Eliminar palabra
          final deleted = await superAdminModService.deleteWord(wordId);
          expect(
            deleted,
            isTrue,
            reason: 'DELETE /words/{id} debe responder { success: true }',
          );
        },
      );

      test('2.5 POST /platform/moderation/rescan ejecuta la auditoría global de contenido', () async {
        final flaggedCount = await superAdminModService.rescanAll();
        expect(flaggedCount, greaterThanOrEqualTo(0));
      });

      test('2.6 Blindaje de Seguridad: Church Admin no puede acceder a /platform/moderation', () async {
        expect(
          () => churchAdminApi.moderationSummary(),
          throwsA(
            predicate(
              (e) =>
                  e is AtrioApiException &&
                  (e.statusCode == 403 || e.code == 'not_platform_admin'),
            ),
          ),
          reason:
              'Un administrador de iglesia debe recibir 403 not_platform_admin',
        );
      });

      test('2.7 Blindaje de Seguridad: Miembro no puede acceder a /platform/moderation/words', () async {
        expect(
          () => memberApi.moderationWords(),
          throwsA(
            predicate(
              (e) =>
                  e is AtrioApiException &&
                  (e.statusCode == 403 || e.code == 'not_platform_admin'),
            ),
          ),
          reason: 'Un miembro normal debe recibir 403 not_platform_admin',
        );
      });
    },
  );

  // ===========================================================================
  // BATERÍA 3: MÓDULO DE PUBLICIDAD Y ANUNCIOS (ADS)
  // ===========================================================================
  group('Batería 3: Módulo de Publicidad y Anuncios (Ads)', () {
    test(
      '3.1 GET /ads feed permite a los miembros obtener anuncios sin errores',
      () async {
        final ads = await memberAdsService.getFeedAds(placement: 'all');
        expect(ads, isA<List<AdModel>>());
      },
    );

    test('3.2 POST /admin/ads/quote permite cotizar campañas a administradores de iglesia', () async {
      final quote = await churchAdsService.quoteAd(
        targetChurchesCount: 1,
        weeks: 2,
      );
      expect(quote, isA<AdQuoteModel>());
      expect(quote.totalPrice, greaterThan(0));
      expect(quote.weeksCount, greaterThanOrEqualTo(1));
      expect(quote.churchesCount, greaterThanOrEqualTo(1));
    });

    test(
      '3.3 GET /admin/ads lista campañas de la congregación del administrador',
      () async {
        final myCampaigns = await churchAdsService.getMyChurchAds();
        expect(myCampaigns, isA<List<AdModel>>());
      },
    );

    test(
      '3.4 Blindaje de Seguridad: Miembro no puede acceder a /admin/ads',
      () async {
        expect(
          () => memberAdsService.getMyChurchAds(),
          throwsA(isA<AtrioApiException>()),
          reason: 'Un miembro sin manage_ads debe ser rechazado al consultar /admin/ads',
        );
      },
    );
  });

  // ===========================================================================
  // BATERÍA 4: REGLA DE SOLO LECTURA Y EXCEPCIONES EN ATRIO_API
  // ===========================================================================
  group('Batería 4: Comportamiento de AtrioApi ante isReadOnly', () {
    test('4.1 AtrioApi con isReadOnly=true bloquea mutaciones normales pero permite /platform/moderation', () async {
      final testApi = AtrioApi(baseUrl: baseUrl, enableLogging: false);
      testApi.token = superAdminApi.token;
      testApi.isReadOnly = true;

      // 1. Debe bloquear mutación normal en congregación
      expect(
        () => testApi.adminCreateEvent({'name': 'Evento Test'}),
        throwsA(
          predicate(
            (e) =>
                e is AtrioApiException &&
                e.statusCode == 403 &&
                e.message.contains('Modo de solo lectura activo'),
          ),
        ),
      );

      // 2. Debe permitir mutación a /platform/moderation/rescan
      final rescanResult = await testApi.moderationRescan();
      expect(rescanResult.containsKey('flagged'), isTrue);
    });
  });
}
