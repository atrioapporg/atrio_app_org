import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/modelos/video_model.dart';
import 'package:atrio/providers/admin_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/videos_transmisiones_screen.dart';
import 'package:atrio/widgets/reproductor_streaming_modal.dart';

void main() {
  Widget buildTestApp({
    required Widget child,
    UserProvider? userProvider,
    AdminProvider? adminProvider,
  }) {
    final uProvider = userProvider ?? UserProvider();
    final aProvider = adminProvider ?? AdminProvider(api: AtrioApi(baseUrl: 'https://test.atrio.app'));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: uProvider),
        ChangeNotifierProvider<AdminProvider>.value(value: aProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: child,
      ),
    );
  }

  group('Etapa 5 - Reproductor de Streaming Embebido Tests', () {
    testWidgets('Inicializa controlador y renderiza reproductor embebido de YouTube',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final video = VideoModel(
        id: 'sermon_101',
        titulo: 'Venciendo el Desánimo en Tiempos de Crisis',
        canalOIglesia: 'Comunidad Central ATRIO',
        predicador: 'Pastor Carlos Mora',
        thumbnailUrl: 'https://img.youtube.com/vi/uE53d7_-Unc/hqdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=uE53d7_-Unc',
        categoria: 'Prédicas',
        sinopsis: 'Un mensaje reconfortante para fortalecer la fe en la adversidad.',
        esEnVivo: false,
        duracion: '45:20',
        estadisticas: '1,500 vistas',
      );

      YoutubePlayerController? capturedController;

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: ReproductorStreamingModal(
              video: video,
              autoPlay: true,
              playerBuilder: (context, controller) {
                capturedController = controller;
                return Container(
                  key: const Key('reproductor_embebido_test'),
                  child: Text('Player ID: ${controller.initialVideoId}'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificación de controlador
      expect(capturedController, isNotNull);
      expect(capturedController!.initialVideoId, equals('uE53d7_-Unc'));
      expect(capturedController!.flags.autoPlay, isTrue);
      expect(capturedController!.flags.isLive, isFalse);

      // Verificación de elementos textuales y metadatos
      expect(find.text('Venciendo el Desánimo en Tiempos de Crisis'), findsOneWidget);
      expect(find.text('Pastor Carlos Mora · Comunidad Central ATRIO'), findsOneWidget);
      expect(find.text('45:20'), findsOneWidget);
      expect(find.text('1,500 vistas'), findsOneWidget);
      expect(find.text('Un mensaje reconfortante para fortalecer la fe en la adversidad.'), findsOneWidget);

      // Botones de acción
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });

    testWidgets('Configura flag isLive y badge EN VIVO para transmisiones en vivo',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final liveVideo = VideoModel(
        id: 'live_stream_01',
        titulo: 'Culto Dominical En Vivo - Servicio Principal',
        canalOIglesia: 'Iglesia Cristiana Gracia',
        predicador: 'Pastor Andrés Gómez',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        videoUrl: 'https://youtube.com/live/dQw4w9WgXcQ',
        categoria: 'En vivo',
        sinopsis: 'Transmisión directa desde el auditorio principal.',
        esEnVivo: true,
        estadisticas: '380 viendo ahora',
      );

      YoutubePlayerController? capturedController;

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: ReproductorStreamingModal(
              video: liveVideo,
              autoPlay: true,
              playerBuilder: (context, controller) {
                capturedController = controller;
                return const Text('Live Player Active');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedController, isNotNull);
      expect(capturedController!.initialVideoId, equals('dQw4w9WgXcQ'));
      expect(capturedController!.flags.isLive, isTrue);

      // Badge EN VIVO
      expect(find.text('EN VIVO'), findsOneWidget);
      expect(find.text('380 viendo ahora'), findsOneWidget);
    });

    testWidgets('Muestra interfaz de fallback ante URLs no válidas de YouTube',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final invalidVideo = VideoModel(
        id: 'no_id',
        titulo: 'Audio Conferencia Sin Video',
        canalOIglesia: 'Capilla Esperanza',
        thumbnailUrl: '',
        videoUrl: 'https://servidor-externo.com/audio.mp3',
        categoria: 'Estudios',
        sinopsis: 'Grabación de audio comunitaria.',
      );

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: ReproductorStreamingModal(
              video: invalidVideo,
              autoPlay: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reproducción externa requerida'), findsOneWidget);
      expect(find.text('Abrir enlace original'), findsOneWidget);
    });

    testWidgets('VideosTransmisionesScreen abre ReproductorStreamingModal al pulsar un video',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 1,
          nombre: 'Hermano Juan',
          email: 'juan@atrio.org',
          iglesiaActual: 'Comunidad Central ATRIO',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'HJ',
          esMiembroVerificado: true,
          role: UserRole.member,
          permissions: const {},
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const VideosTransmisionesScreen(),
          userProvider: userProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que la pantalla de videos cargó
      expect(find.byType(VideosTransmisionesScreen), findsOneWidget);
      expect(find.text('Videos y transmisiones'), findsOneWidget);

      // Tocar en la primera tarjeta de video
      final videoTitleFinder = find.text('La fe que mueve montañas');
      expect(videoTitleFinder, findsOneWidget);

      await tester.ensureVisible(videoTitleFinder);
      await tester.pumpAndSettle();
      await tester.tap(videoTitleFinder);
      await tester.pumpAndSettle();

      // Debe haberse abierto el modal con el reproductor embebido
      expect(find.byType(ReproductorStreamingModal), findsOneWidget);
      expect(find.byKey(const Key('reproductor_youtube_embebido')), findsOneWidget);
    });
  });
}
