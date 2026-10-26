import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/admin_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/crear_evento_screen.dart';
import 'package:atrio/screens/crear_predica_screen.dart';

class MockAdminApi extends AtrioApi {
  MockAdminApi() : super(baseUrl: 'https://test.atrio.app');

  Map<String, dynamic>? lastCreatedEvent;
  Map<String, dynamic>? lastCreatedPost;

  @override
  Future<Map<String, dynamic>> adminCreateEvent(
    Map<String, dynamic> eventData, {
    int? churchId,
  }) async {
    lastCreatedEvent = eventData;
    return {'event': eventData, 'status': 'success'};
  }

  @override
  Future<Map<String, dynamic>> adminCreatePost(
    Map<String, dynamic> postData, {
    int? churchId,
  }) async {
    lastCreatedPost = postData;
    return {'post': postData, 'status': 'success'};
  }
}

void main() {
  Widget buildTestApp({
    required Widget child,
    required UserProvider userProvider,
    required AdminProvider adminProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: child,
      ),
    );
  }

  group('Etapa 4 - Formularios Responsivos Tests', () {
    late MockAdminApi mockApi;
    late AdminProvider adminProvider;
    late UserProvider userProvider;

    setUp(() {
      mockApi = MockAdminApi();
      adminProvider = AdminProvider(api: mockApi);
      userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 1,
          nombre: 'Pastor Andrés',
          email: 'pastor@atrio.org',
          iglesiaActual: 'Comunidad Central ATRIO',
          iglesiaId: 5,
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'PA',
          esMiembroVerificado: true,
          role: UserRole.churchAdmin,
          permissions: const {
            AppPermissions.manageEvents,
            AppPermissions.managePosts,
          },
          isReadOnly: false,
        ),
      );
    });

    testWidgets('CrearEventoScreen renderiza y valida campos requeridos',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          child: const CrearEventoScreen(),
          userProvider: userProvider,
          adminProvider: adminProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Evento'), findsOneWidget);
      expect(find.text('Título del Evento *'), findsOneWidget);
      expect(find.text('Publicar Evento'), findsOneWidget);

      // Intentar publicar con campos vacíos
      await tester.ensureVisible(find.text('Publicar Evento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicar Evento'));
      await tester.pumpAndSettle();

      expect(
        find.text('Por favor ingresa un título para el evento'),
        findsOneWidget,
      );
      expect(
        find.text('Por favor completa todos los campos requeridos marcados con asterisco (*).'),
        findsOneWidget,
      );

      // Rellenar campos válidos
      final inputs = find.byType(TextFormField);
      await tester.ensureVisible(inputs.at(0));
      await tester.enterText(inputs.at(0), 'Conferencia de Avivamiento 2026');
      await tester.ensureVisible(inputs.last);
      await tester.enterText(
        inputs.last,
        'Tiempo de edificación y oración comunitaria.',
      );
      await tester.pumpAndSettle();

      // Cambiar modalidad a Virtual
      await tester.ensureVisible(find.text('Virtual'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Virtual'));
      await tester.pumpAndSettle();

      // Ahora el campo de streaming debe aparecer
      expect(
        find.text('Enlace de Transmisión (YouTube Live / Stream) *'),
        findsOneWidget,
      );

      // Ingresar URL de YouTube
      final streamInput = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText?.contains('youtube.com/live') == true,
      );
      expect(streamInput, findsOneWidget);
      await tester.ensureVisible(streamInput);
      await tester.enterText(streamInput, 'https://youtube.com/live/uE53d7_-Unc');
      await tester.pumpAndSettle();

      // Publicar evento
      await tester.ensureVisible(find.text('Publicar Evento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicar Evento'));
      await tester.pump();

      expect(mockApi.lastCreatedEvent, isNotNull);
      expect(
        mockApi.lastCreatedEvent!['name'],
        equals('Conferencia de Avivamiento 2026'),
      );
      expect(
        mockApi.lastCreatedEvent!['title'],
        equals('Conferencia de Avivamiento 2026'),
      );
      expect(mockApi.lastCreatedEvent!['date'], isNotNull);
      expect(mockApi.lastCreatedEvent!['date_begin'], isNotNull);
      expect(mockApi.lastCreatedEvent!['time'], isA<double>());
      expect(mockApi.lastCreatedEvent!['time_label'], isNotNull);
      expect(mockApi.lastCreatedEvent!['modalidad'], equals('virtual'));
      expect(
        mockApi.lastCreatedEvent!['stream_url'],
        equals('https://youtube.com/live/uE53d7_-Unc'),
      );
    });

    testWidgets(
        'CrearPredicaScreen detecta YouTube en tiempo real y permite publicar en vivo',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          child: const CrearPredicaScreen(),
          userProvider: userProvider,
          adminProvider: adminProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Transmitir en Vivo'), findsWidgets);
      expect(find.text('Culto en Vivo'), findsOneWidget);

      // Inicialmente no hay ID detectado
      expect(find.text('Video de YouTube Reconocido'), findsNothing);

      // Escribir URL de YouTube
      final urlInput = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText?.contains('youtube.com/live') == true,
      );
      await tester.ensureVisible(urlInput);
      await tester.enterText(urlInput, 'https://youtu.be/uE53d7_-Unc');
      await tester.pumpAndSettle();

      // Verificar que el badge reactivo detectó el ID en tiempo real
      expect(find.text('Video de YouTube Reconocido'), findsOneWidget);
      expect(find.text('ID: uE53d7_-Unc'), findsOneWidget);

      // Rellenar título y predicador
      final inputs = find.byType(TextFormField);
      await tester.ensureVisible(inputs.at(1));
      await tester.enterText(inputs.at(1), 'Culto Dominical: Fe Inquebrantable');
      await tester.ensureVisible(inputs.at(2));
      await tester.enterText(inputs.at(2), 'Pastor Andrés Gómez');
      await tester.pumpAndSettle();

      // Publicar
      await tester.ensureVisible(find.text('Publicar Transmisión en Vivo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicar Transmisión en Vivo'));
      await tester.pump();

      expect(mockApi.lastCreatedPost, isNotNull);
      expect(
        mockApi.lastCreatedPost!['title'],
        equals('Culto Dominical: Fe Inquebrantable'),
      );
      expect(mockApi.lastCreatedPost!['is_live'], isTrue);
      expect(mockApi.lastCreatedPost!['video_url'], equals('https://youtu.be/uE53d7_-Unc'));
      expect(mockApi.lastCreatedPost!['platform'], equals('youtube'));
    });
  });
}
