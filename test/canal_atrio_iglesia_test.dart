import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/modelos/video_model.dart';
import 'package:atrio/providers/admin_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/crear_predica_screen.dart';
import 'package:atrio/screens/videos_transmisiones_screen.dart';
import 'package:atrio/utils/youtube_helper.dart';
import 'package:atrio/widgets/reproductor_streaming_modal.dart';

class MockAdminApi extends AtrioApi {
  MockAdminApi() : super(baseUrl: 'https://test.atrio.app');

  Map<String, dynamic>? lastCreatedPost;

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
  group('Pruebas de Integración y Compatibilidad: Canal @AtrioIglesia', () {
    test('YoutubeHelper extrae handle, ID y valida URL del canal oficial @AtrioIglesia', () {
      const urlHandle = 'https://www.youtube.com/@AtrioIglesia';
      const urlHandleLive = 'https://www.youtube.com/@AtrioIglesia/live';
      const urlChannelId = 'https://www.youtube.com/channel/UCuW2ZM9B8MEm5FiKBQENjTw';
      const urlChannelLive = 'https://www.youtube.com/channel/UCuW2ZM9B8MEm5FiKBQENjTw/live';
      const directHandle = '@AtrioIglesia';
      const directChannelId = 'UCuW2ZM9B8MEm5FiKBQENjTw';
      const sampleVideoPath = r'Z:\Antonyy\ATRIO VARIOS\Login _ Atrio.mp4';

      // Validación de Handles
      expect(YoutubeHelper.extractChannelHandle(urlHandle), equals('@AtrioIglesia'));
      expect(YoutubeHelper.extractChannelHandle(urlHandleLive), equals('@AtrioIglesia'));
      expect(YoutubeHelper.extractChannelHandle(directHandle), equals('@AtrioIglesia'));

      // Validación de Channel IDs
      expect(YoutubeHelper.extractChannelId(urlChannelId), equals('UCuW2ZM9B8MEm5FiKBQENjTw'));
      expect(YoutubeHelper.extractChannelId(urlChannelLive), equals('UCuW2ZM9B8MEm5FiKBQENjTw'));
      expect(YoutubeHelper.extractChannelId(directChannelId), equals('UCuW2ZM9B8MEm5FiKBQENjTw'));

      // Flags de detección
      expect(YoutubeHelper.isChannelUrl(urlHandle), isTrue);
      expect(YoutubeHelper.isChannelUrl(urlChannelId), isTrue);
      expect(YoutubeHelper.isChannelLiveUrl(urlHandleLive), isTrue);
      expect(YoutubeHelper.isChannelLiveUrl(urlChannelLive), isTrue);
      expect(YoutubeHelper.isChannelLiveUrl(urlHandle), isFalse);

      // Validación general
      expect(YoutubeHelper.isValidYoutubeUrlOrId(urlHandle), isTrue);
      expect(YoutubeHelper.isValidYoutubeUrlOrId(urlHandleLive), isTrue);
      expect(YoutubeHelper.isValidYoutubeUrlOrId(urlChannelId), isTrue);
      expect(YoutubeHelper.isValidYoutubeUrlOrId(urlChannelLive), isTrue);

      // Detección de archivo local MP4 de ejemplo
      expect(YoutubeHelper.isDirectVideoFile(sampleVideoPath), isTrue);
    });

    testWidgets('CrearPredicaScreen detecta @AtrioIglesia/live reactivamente sin rechazo',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockApi = MockAdminApi();
      final adminProvider = AdminProvider(api: mockApi);
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 1,
          nombre: 'Pastor Atrio',
          email: 'atrioapporg@gmail.com',
          iglesiaActual: 'Atrio Iglesia',
          iglesiaId: 10,
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'PA',
          esMiembroVerificado: true,
          role: UserRole.churchAdmin,
          permissions: const {
            AppPermissions.managePosts,
          },
          isReadOnly: false,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('es'),
            home: CrearPredicaScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ingresar URL del canal oficial de Atrio
      final inputs = find.byType(TextFormField);
      await tester.ensureVisible(inputs.at(0));
      await tester.enterText(inputs.at(0), 'https://www.youtube.com/@AtrioIglesia/live');
      await tester.pumpAndSettle();

      // Verificar que se detecta el canal oficial y la transmisión de canal
      expect(find.text('Transmisión Oficial de Canal'), findsOneWidget);
      expect(find.text('Canal: @AtrioIglesia'), findsOneWidget);
    });

    testWidgets('ReproductorStreamingModal renderiza vista temática para @AtrioIglesia/live',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final videoAtrio = VideoModel(
        id: 'live_atrio',
        titulo: 'Servicio Principal Atrio',
        canalOIglesia: 'Atrio Iglesia (@AtrioIglesia)',
        videoUrl: 'https://www.youtube.com/@AtrioIglesia/live',
        categoria: 'En vivo',
        esEnVivo: true,
        sinopsis: 'Culto congregacional en directo.',
        thumbnailUrl: 'https://img.youtube.com/vi/uE53d7_-Unc/maxresdefault.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: ReproductorStreamingModal(video: videoAtrio),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que muestra los detalles del canal oficial
      expect(find.text('Transmisión Oficial en Directo'), findsOneWidget);
      expect(find.text('Canal @AtrioIglesia · YouTube'), findsOneWidget);
      expect(find.text('Ver en vivo en YouTube'), findsOneWidget);
      expect(find.text('Servicio Principal Atrio'), findsOneWidget);
    });

    testWidgets('VideosTransmisionesScreen expone el canal @AtrioIglesia como destacado',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockApi = MockAdminApi();
      final adminProvider = AdminProvider(api: mockApi);
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 1,
          nombre: 'Miembro Atrio',
          email: 'miembro@atrio.org',
          iglesiaActual: 'Atrio Iglesia',
          iglesiaId: 10,
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'MA',
          esMiembroVerificado: true,
          role: UserRole.member,
          permissions: const {},
          isReadOnly: false,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('es'),
            home: VideosTransmisionesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que el banner destacado muestra Atrio Iglesia
      expect(find.text('Atrio Iglesia (@AtrioIglesia)'), findsWidgets);
      expect(find.text('Culto Dominical en Vivo'), findsOneWidget);

      // Pulsar sobre la transmisión destacada abre el modal temático de @AtrioIglesia
      await tester.tap(find.text('Culto Dominical en Vivo').first);
      await tester.pumpAndSettle();

      expect(find.byType(ReproductorStreamingModal), findsOneWidget);
      expect(find.text('Transmisión Oficial en Directo'), findsOneWidget);
      expect(find.text('Canal @AtrioIglesia · YouTube'), findsOneWidget);
    });
  });
}
