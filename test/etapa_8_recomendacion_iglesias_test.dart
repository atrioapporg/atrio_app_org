import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/ajustes_provider.dart';
import 'package:atrio/providers/recomendacion_iglesia_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/esperando_aprobacion_screen.dart';
import 'package:atrio/screens/exito_recomendacion_screen.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';
import 'package:atrio/widgets/modal_ayuda_maps.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // GRUPO 1: DTOs Y MODELOS DE DATOS
  // ===========================================================================
  group('Etapa 8 - Modelos y DTOs (ChurchRecommendationModel & PlaceLookupResult)', () {
    test('ChurchRecommendationModel deserializa payload completo de Odoo 19', () {
      final json = {
        'id': 87,
        'name': 'Iglesia Bautista Central',
        'address': '4a Calle 10-20, Zona 1',
        'city': 'Quetzaltenango',
        'country': 'Guatemala',
        'place_id': 'ChIJN1t_tDeuEmsRUsoyG83frY4',
        'maps_url': 'https://maps.google.com/?cid=12345',
        'latitude': 14.8347,
        'longitude': -91.5180,
        'status': 'recommended',
        'recommended_on': '2026-10-20',
        'deadline': '2026-11-19',
        'days_left': 23,
        'recommendation_count': 3,
        'recommended_by_me': true,
      };

      final model = ChurchRecommendationModel.fromJson(json);

      expect(model.id, 87);
      expect(model.name, 'Iglesia Bautista Central');
      expect(model.address, '4a Calle 10-20, Zona 1');
      expect(model.city, 'Quetzaltenango');
      expect(model.country, 'Guatemala');
      expect(model.placeId, 'ChIJN1t_tDeuEmsRUsoyG83frY4');
      expect(model.mapsUrl, 'https://maps.google.com/?cid=12345');
      expect(model.latitude, 14.8347);
      expect(model.longitude, -91.5180);
      expect(model.status, ChurchRecommendationStatus.recommended);
      expect(model.daysLeft, 23);
      expect(model.recommendationCount, 3);
      expect(model.recommendedByMe, isTrue);
      expect(model.isRecommended, isTrue);
      expect(model.statusMessage, contains('23 días'));

      final outJson = model.toJson();
      expect(outJson['place_id'], 'ChIJN1t_tDeuEmsRUsoyG83frY4');
      expect(outJson['days_left'], 23);
    });

    test('ChurchRecommendationModel maneja valores nulos y formatos de números como string', () {
      final json = {
        'id': '99',
        'name': null,
        'place_id': 'place_xyz',
        'latitude': '15.500',
        'longitude': '-90.200',
        'status': 'enrolled',
        'days_left': null,
      };

      final model = ChurchRecommendationModel.fromJson(json);

      expect(model.id, 99);
      expect(model.name, 'Iglesia'); // fallback
      expect(model.latitude, 15.5);
      expect(model.longitude, -90.2);
      expect(model.status, ChurchRecommendationStatus.enrolled);
      expect(model.isEnrolled, isTrue);
      expect(model.statusMessage, '¡Ya está en Atrio!');
    });

    test('ChurchRecommendationStatus y PlaceLookupStatus conversiones de String correctas', () {
      expect(ChurchRecommendationStatus.fromString('recommended'), ChurchRecommendationStatus.recommended);
      expect(ChurchRecommendationStatus.fromString('enrolled'), ChurchRecommendationStatus.enrolled);
      expect(ChurchRecommendationStatus.fromString('expired'), ChurchRecommendationStatus.expired);
      expect(ChurchRecommendationStatus.fromString('discarded'), ChurchRecommendationStatus.discarded);
      expect(ChurchRecommendationStatus.fromString('desconocido'), ChurchRecommendationStatus.unknown);

      expect(PlaceLookupStatus.fromString('not_found'), PlaceLookupStatus.notFound);
      expect(PlaceLookupStatus.fromString('recommended'), PlaceLookupStatus.recommended);
      expect(PlaceLookupStatus.fromString('in_atrio'), PlaceLookupStatus.inAtrio);
      expect(PlaceLookupStatus.fromString('pending_activation'), PlaceLookupStatus.pendingActivation);
      expect(PlaceLookupStatus.fromString('declined'), PlaceLookupStatus.declined);
      expect(PlaceLookupStatus.fromString('unavailable'), PlaceLookupStatus.unavailable);
    });

    test('PlaceLookupResult interpreta correctamente permisos de acción para la UI', () {
      // 1. Not found -> Recomendar disponible
      final notFound = PlaceLookupResult.fromJson({'status': 'not_found'});
      expect(notFound.canRecommend, isTrue);
      expect(notFound.canJoinRecommendation, isFalse);
      expect(notFound.canRequestMembership, isFalse);

      // 2. Recommended por otra persona -> Sumarme disponible
      final recommendedByOther = PlaceLookupResult.fromJson({
        'status': 'recommended',
        'recommendation': {
          'id': 1,
          'name': 'Betel',
          'place_id': 'p1',
          'recommended_by_me': false,
        },
      });
      expect(recommendedByOther.canJoinRecommendation, isTrue);
      expect(recommendedByOther.isAlreadyRecommendedByMe, isFalse);

      // 3. Recommended por el usuario actual -> Ya recomendada
      final recommendedByMe = PlaceLookupResult.fromJson({
        'status': 'recommended',
        'recommendation': {
          'id': 1,
          'name': 'Betel',
          'place_id': 'p1',
          'recommended_by_me': true,
        },
      });
      expect(recommendedByMe.isAlreadyRecommendedByMe, isTrue);
      expect(recommendedByMe.canJoinRecommendation, isFalse);

      // 4. In Atrio / Pending Activation -> Solicitar ingreso
      final inAtrio = PlaceLookupResult.fromJson({
        'status': 'in_atrio',
        'church': {'id': 50, 'name': 'Catedral Atrio'},
      });
      expect(inAtrio.canRequestMembership, isTrue);
      expect(inAtrio.canRecommend, isFalse);

      // 5. Declined / Unavailable -> Bloqueado
      final declined = PlaceLookupResult.fromJson({'status': 'declined'});
      expect(declined.isDeclined, isTrue);
      expect(declined.canRecommend, isFalse);

      final unavailable = PlaceLookupResult.fromJson({'status': 'unavailable'});
      expect(unavailable.isUnavailable, isTrue);
      expect(unavailable.canRecommend, isFalse);
    });
  });

  // ===========================================================================
  // GRUPO 2: CLIENTE HTTP ATRIO API (ENDPOINTS Y ZERO PAYLOAD GEO)
  // ===========================================================================
  group('Etapa 8 - AtrioApi Cliente HTTP y Manejo de Errores Odoo 19', () {
    test('getChurchByPlace envía place_id como query param y parsea respuesta 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/atrio/portal/api/churches/by-place');
        expect(request.url.queryParameters['place_id'], 'ChIJ_TEST_PLACE');
        expect(request.headers['Authorization'], 'Bearer test_token');

        final responseBody = {
          'status': 'recommended',
          'church': null,
          'recommendation': {
            'id': 12,
            'name': 'Iglesia de Dios Central',
            'place_id': 'ChIJ_TEST_PLACE',
            'status': 'recommended',
            'days_left': 28,
            'recommended_by_me': false,
          },
        };

        return http.Response(jsonEncode(responseBody), 200, headers: {'content-type': 'application/json'});
      });

      final api = AtrioApi(
        baseUrl: 'https://atrioapp.odoo19rd.com',
        token: 'test_token',
        client: mockClient,
      );

      final result = await api.getChurchByPlace('ChIJ_TEST_PLACE');
      expect(result.status, PlaceLookupStatus.recommended);
      expect(result.recommendation?.name, 'Iglesia de Dios Central');
      expect(result.recommendation?.daysLeft, 28);
    });

    test('recommendChurch envía Zero Payload Geo (solo place_id y contacto) vía POST', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/atrio/portal/api/churches/recommend');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['place_id'], 'ChIJ_TEST_PLACE');
        expect(body['contact_name'], 'Pastor David');
        expect(body['contact_phone'], '+502 12345678');
        // REGLA CRÍTICA: La app NO envía nombre, latitud ni longitud
        expect(body.containsKey('name'), isFalse);
        expect(body.containsKey('latitude'), isFalse);
        expect(body.containsKey('longitude'), isFalse);

        return http.Response(
          jsonEncode({
            'success': true,
            'status': 'pending',
            'recommendation': {
              'id': 45,
              'name': 'Iglesia Enriquecida por Odoo',
              'place_id': 'ChIJ_TEST_PLACE',
              'status': 'recommended',
              'days_left': 30,
              'recommended_by_me': true,
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = AtrioApi(
        baseUrl: 'https://atrioapp.odoo19rd.com',
        token: 'test_token',
        client: mockClient,
      );

      final response = await api.recommendChurch(
        placeId: 'ChIJ_TEST_PLACE',
        contactName: 'Pastor David',
        contactPhone: '+502 12345678',
      );

      expect(response['success'], isTrue);
      final rec = ChurchRecommendationModel.fromJson(response['recommendation']);
      expect(rec.name, 'Iglesia Enriquecida por Odoo');
      expect(rec.recommendedByMe, isTrue);
    });

    test('AtrioApi clasifica errores de backend Odoo 19 (400, 403, 409, 503)', () async {
      void testErrorResponse({
        required int statusCode,
        required String code,
        required String message,
        required void Function(AtrioApiException e) verify,
      }) async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'code': code, 'error': message}),
            statusCode,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = AtrioApi(
          baseUrl: 'https://atrioapp.odoo19rd.com',
          client: mockClient,
        );

        try {
          await api.recommendChurch(placeId: 'bad_place');
          fail('Debería haber lanzado AtrioApiException');
        } on AtrioApiException catch (e) {
          expect(e.status, statusCode);
          expect(e.code, code);
          verify(e);
        }
      }

      // 409 church_in_atrio
      testErrorResponse(
        statusCode: 409,
        code: 'church_in_atrio',
        message: 'Esta iglesia ya está en Atrio',
        verify: (e) {
          expect(e.isConflict, isTrue);
          expect(e.isChurchInAtrio, isTrue);
        },
      );

      // 409 church_declined
      testErrorResponse(
        statusCode: 409,
        code: 'church_declined',
        message: 'Atrio ya contactó a esta iglesia y por ahora no se sumará',
        verify: (e) => expect(e.isChurchDeclined, isTrue),
      );

      // 503 maps_not_configured
      testErrorResponse(
        statusCode: 503,
        code: 'maps_not_configured',
        message: 'El servicio de Google Maps no está disponible en este momento',
        verify: (e) => expect(e.isMapsNotConfigured, isTrue),
      );
    });

    test('submitMapsHelp envía solicitud de soporte para iglesias que no están en Maps', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/atrio/portal/api/churches/maps-help');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Iglesia Remanente');
        expect(body['city'], 'Antigua Guatemala');
        expect(body['country_id'], 90);
        expect(body['message'], 'Estamos ubicados en calle 5');

        return http.Response(
          jsonEncode({'success': true, 'id': 77, 'state': 'new'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = AtrioApi(baseUrl: 'https://atrioapp.odoo19rd.com', client: mockClient);
      final res = await api.submitMapsHelp(
        name: 'Iglesia Remanente',
        city: 'Antigua Guatemala',
        countryId: 90,
        message: 'Estamos ubicados en calle 5',
      );

      expect(res['success'], isTrue);
      expect(res['id'], 77);
    });
  });

  // ===========================================================================
  // GRUPO 3: GESTIÓN DE ESTADO (RecomendacionIglesiaProvider)
  // ===========================================================================
  group('Etapa 8 - RecomendacionIglesiaProvider State Management', () {
    test('Provider valida selección obligatoria antes de enviar recomendación', () async {
      final api = AtrioApi(baseUrl: 'https://atrioapp.odoo19rd.com');
      final provider = RecomendacionIglesiaProvider(api: api);

      expect(provider.hasSelectedPlace, isFalse);
      expect(
        () => provider.submitRecommendation(),
        throwsA(isA<AtrioApiException>().having(
          (e) => e.code,
          'code',
          'missing_fields',
        )),
      );
    });

    test('Provider maneja flujo completo de recomendación exitosa y actualiza lookupResult', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/churches/recommend')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'recommendation': {
                'id': 100,
                'name': 'Iglesia La Esperanza',
                'place_id': 'place_123',
                'status': 'recommended',
                'days_left': 30,
                'recommended_by_me': true,
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final api = AtrioApi(baseUrl: 'https://atrioapp.odoo19rd.com', client: mockClient);
      final provider = RecomendacionIglesiaProvider(api: api);

      // Inyectar selección simulada
      provider.setCustomSelectionForTesting(
        placeId: 'place_123',
        placeName: 'Iglesia La Esperanza',
        placeAddress: 'Av. Siempre Viva 742',
      );

      expect(provider.hasSelectedPlace, isTrue);

      final rec = await provider.submitRecommendation(
        contactName: 'Pastor Pedro',
        contactPhone: '+123456789',
      );

      expect(rec.id, 100);
      expect(rec.name, 'Iglesia La Esperanza');
      expect(provider.currentLookupStatus, PlaceLookupStatus.recommended);
      expect(provider.lastRecommendation?.recommendedByMe, isTrue);

      // Limpieza de selección
      provider.clearSelection();
      expect(provider.hasSelectedPlace, isFalse);
      expect(provider.placeLookupResult, isNull);
    });

    test('Provider gestiona correctamente envío de formulario de ayuda Maps', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'id': 99, 'state': 'new'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = AtrioApi(baseUrl: 'https://atrioapp.odoo19rd.com', client: mockClient);
      final provider = RecomendacionIglesiaProvider(api: api);

      final ok = await provider.submitMapsHelp(
        name: 'Misión Bíblica',
        city: 'Cobán',
        message: 'No aparecemos en el mapa de Google',
      );

      expect(ok, isTrue);
      expect(provider.mapsHelpSubmitted, isTrue);
      expect(provider.lastHelpTicketId, 99);

      provider.resetMapsHelpStatus();
      expect(provider.mapsHelpSubmitted, isFalse);
    });
  });

  // ===========================================================================
  // GRUPO 4: PRUEBAS DE WIDGETS Y PANTALLAS UI/UX
  // ===========================================================================
  group('Etapa 8 - Widgets y Pantallas UI/UX (ExitoRecomendacionScreen, ModalAyudaMaps)', () {
    testWidgets('ExitoRecomendacionScreen renderiza datos de la iglesia, badge de 30 días y botón de inicio', (tester) async {
      const rec = ChurchRecommendationModel(
        id: 1,
        name: 'Iglesia Vida Nueva',
        address: 'Boulevard Los Próceres 12-40, Zona 10',
        city: 'Guatemala',
        country: 'Guatemala',
        placeId: 'place_vn',
        status: ChurchRecommendationStatus.recommended,
        rawStatus: 'recommended',
        daysLeft: 30,
        recommendedByMe: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            InicioAtrioScreen.routeName: (_) => const Scaffold(body: Text('Pantalla de Inicio')),
          },
          home: const ExitoRecomendacionScreen(recommendation: rec),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('¡Gracias por recomendar tu iglesia!'), findsOneWidget);
      expect(find.textContaining('Iglesia Vida Nueva'), findsOneWidget);
      expect(find.text('Boulevard Los Próceres 12-40, Zona 10'), findsOneWidget);
      expect(find.textContaining('quedan 30 días'), findsOneWidget);
      expect(find.text('Ir al Inicio'), findsOneWidget);

      // Probar tap en botón Ir al inicio
      await tester.tap(find.text('Ir al Inicio'));
      await tester.pumpAndSettle();

      expect(find.text('Pantalla de Inicio'), findsOneWidget);
    });

    testWidgets('ModalAyudaMaps valida campo obligatorio y responde a envío exitoso', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'id': 55}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = AtrioApi(baseUrl: 'https://atrioapp.odoo19rd.com', client: mockClient);
      final recProvider = RecomendacionIglesiaProvider(api: api);
      final ajustesProvider = AjustesProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RecomendacionIglesiaProvider>.value(value: recProvider),
            ChangeNotifierProvider<AjustesProvider>.value(value: ajustesProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ModalAyudaMaps(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('¿Tu iglesia no aparece en Maps?'), findsOneWidget);
      final botonEnvio = find.text('Enviar solicitud de ayuda');
      expect(botonEnvio, findsOneWidget);

      // Ingresar nombre de la congregación (primer campo del formulario)
      final primerCampo = find.byType(TextFormField).first;
      await tester.enterText(primerCampo, 'Iglesia Bethel');
      await tester.pumpAndSettle();

      // Enviar formulario asegurando visibilidad
      await tester.ensureVisible(botonEnvio);
      await tester.pumpAndSettle();
      await tester.tap(botonEnvio);
      await tester.pumpAndSettle();

      expect(recProvider.mapsHelpSubmitted, isTrue);
    });

    testWidgets('EsperandoAprobacionScreen muestra banner de 30 días si el usuario tiene recomendación activa', (tester) async {
      final userProvider = UserProvider(api: AtrioApi(baseUrl: 'https://test.atrioapp.org'));
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 10,
          nombre: 'Andrés',
          email: 'andres@correo.com',
          iglesiaActual: 'Comunidad Cristiana El Encuentro',
          fechaRegistro: '2026-10-27',
          avatarIniciales: 'A',
          esMiembroVerificado: false,
          churchRecommendation: const ChurchRecommendationModel(
            id: 88,
            name: 'Comunidad Cristiana El Encuentro',
            placeId: 'place_ee',
            status: ChurchRecommendationStatus.recommended,
            rawStatus: 'recommended',
            daysLeft: 27,
            recommendedByMe: true,
          ),
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(
            home: EsperandoAprobacionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Iglesia en Proceso de Incorporación'), findsOneWidget);
      expect(find.text('Comunidad Cristiana El Encuentro'), findsOneWidget);
      expect(find.textContaining('Atrio tiene un plazo de 27 días'), findsOneWidget);
    });
  });
}
