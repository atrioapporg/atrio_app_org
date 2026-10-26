import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/admin_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/crear_predica_screen.dart';
import 'package:atrio/utils/media_validator.dart';

class MockAdminApi extends AtrioApi {
  MockAdminApi() : super(baseUrl: 'https://test.atrio.app');
}

void main() {
  group('MediaValidator - Pruebas de Límites y Protección Antifraude / Abuso', () {
    test('Límite de imágenes: acepta <= 3 MB y rechaza estrictamente > 3 MB', () {
      // 1. Imagen válida de 2.5 MB (2,621,440 bytes)
      final bytes2_5MB = Uint8List(2 * 1024 * 1024 + 512 * 1024);
      final resultValido = MediaValidator.validateImageBytes(bytes2_5MB);
      expect(resultValido.isValid, isTrue);
      expect(resultValido.errorMessage, isNull);
      expect(resultValido.sizeInMB, closeTo(2.5, 0.05));

      // 2. Imagen exactamente en el límite de 3 MB (3,145,728 bytes)
      final bytes3MB = Uint8List(3 * 1024 * 1024);
      final resultExacto = MediaValidator.validateImageBytes(bytes3MB);
      expect(resultExacto.isValid, isTrue);
      expect(resultExacto.errorMessage, isNull);

      // 3. Imagen que supera los 3 MB (3.5 MB)
      final bytes3_5MB = Uint8List(3 * 1024 * 1024 + 512 * 1024);
      final resultExcedido = MediaValidator.validateImageBytes(bytes3_5MB);
      expect(resultExcedido.isValid, isFalse);
      expect(resultExcedido.errorMessage, contains('3.50 MB'));
      expect(resultExcedido.errorMessage, contains('límite de 3 MB'));
      expect(resultExcedido.friendlySuggestion, contains('no mayor a 3 MB'));
    });

    test('Límite de videos: rechaza < 10 segundos y > 5 minutos; acepta rango válido', () {
      // 1. Video demasiado corto (7 segundos)
      final resultCorto = MediaValidator.validateVideoDuration(
        duration: const Duration(seconds: 7),
        sizeInMB: 1.2,
      );
      expect(resultCorto.isValid, isFalse);
      expect(resultCorto.isTooShort, isTrue);
      expect(resultCorto.isTooLong, isFalse);
      expect(resultCorto.errorMessage, contains('7 segundos'));
      expect(resultCorto.errorMessage, contains('mínima requerida es de 10 segundos'));

      // 2. Video en el límite inferior válido (10 segundos)
      final resultMinimo = MediaValidator.validateVideoDuration(
        duration: const Duration(seconds: 10),
        sizeInMB: 1.8,
      );
      expect(resultMinimo.isValid, isTrue);
      expect(resultMinimo.isTooShort, isFalse);
      expect(resultMinimo.isTooLong, isFalse);

      // 3. Video de duración típica válida (27 segundos, como el de muestra Login _ Atrio.mp4)
      final resultMuestra = MediaValidator.validateVideoDuration(
        duration: const Duration(seconds: 27),
        sizeInMB: 2.66,
      );
      expect(resultMuestra.isValid, isTrue);
      expect(resultMuestra.isTooShort, isFalse);
      expect(resultMuestra.isTooLong, isFalse);

      // 4. Video en el límite superior válido (5 minutos exactos = 300 segundos)
      final resultMaximo = MediaValidator.validateVideoDuration(
        duration: const Duration(minutes: 5),
        sizeInMB: 35.0,
      );
      expect(resultMaximo.isValid, isTrue);
      expect(resultMaximo.isTooShort, isFalse);
      expect(resultMaximo.isTooLong, isFalse);

      // 5. Video excedido mayor a 5 minutos (6 minutos y 15 segundos)
      final resultLargo = MediaValidator.validateVideoDuration(
        duration: const Duration(minutes: 6, seconds: 15),
        sizeInMB: 45.0,
        channelHandle: '@AtrioIglesia',
      );
      expect(resultLargo.isValid, isFalse);
      expect(resultLargo.isTooLong, isTrue);
      expect(resultLargo.isTooShort, isFalse);
      expect(resultLargo.errorMessage, contains('6m 15s'));
      expect(resultLargo.friendlySuggestion, contains('streaming'));
      expect(resultLargo.friendlySuggestion, contains('YouTube'));
      expect(resultLargo.friendlySuggestion, contains('@AtrioIglesia'));
    });

    test('Lector de MP4 nativo extrae duración del archivo de muestra real', () {
      final sampleVideo = File(r'Z:\Antonyy\ATRIO VARIOS\Login _ Atrio.mp4');
      if (sampleVideo.existsSync()) {
        final bytes = sampleVideo.readAsBytesSync();
        final duration = MediaValidator.extractMp4Duration(bytes);

        expect(duration, isNotNull);
        expect(duration!.inSeconds, equals(27));
        expect(duration.inSeconds >= 10, isTrue);
        expect(duration.inMinutes < 5, isTrue);
      }
    });

    testWidgets('showImageSizeExceededModal despliega explicación amigable del límite de 3 MB',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => MediaValidator.showImageSizeExceededModal(
                  context,
                  sizeInMB: 4.82,
                ),
                child: const Text('Abrir Modal Imagen'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Modal Imagen'));
      await tester.pumpAndSettle();

      expect(find.text('Imagen demasiado pesada'), findsOneWidget);
      expect(find.textContaining('4.82 MB'), findsOneWidget);
      expect(find.textContaining('límite permitido de 3 MB'), findsOneWidget);
      expect(find.text('Entendido, elegiré otra'), findsOneWidget);

      await tester.tap(find.text('Entendido, elegiré otra'));
      await tester.pumpAndSettle();
      expect(find.text('Imagen demasiado pesada'), findsNothing);
    });

    testWidgets('showVideoDurationExceededModal sugiere amigablemente YouTube y canal @AtrioIglesia',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool streamingCallbackInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => MediaValidator.showVideoDurationExceededModal(
                  context,
                  duration: const Duration(minutes: 8, seconds: 40),
                  channelHandle: '@AtrioIglesia',
                  onUseYoutubeStreaming: () {
                    streamingCallbackInvoked = true;
                  },
                ),
                child: const Text('Abrir Modal Video'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Modal Video'));
      await tester.pumpAndSettle();

      expect(find.text('Video mayor a 5 minutos'), findsOneWidget);
      expect(find.text('Duración detectada: 8m 40s'), findsOneWidget);
      expect(find.textContaining('@AtrioIglesia'), findsOneWidget);
      expect(find.textContaining('YouTube Live'), findsOneWidget);
      expect(find.text('Usar enlace de YouTube'), findsOneWidget);

      await tester.tap(find.text('Usar enlace de YouTube'));
      await tester.pumpAndSettle();
      expect(streamingCallbackInvoked, isTrue);
      expect(find.text('Video mayor a 5 minutos'), findsNothing);
    });

    testWidgets('CrearPredicaScreen integra botón de subir video corto y previsualización',
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

      // Verificar que el botón de subir video corto está disponible
      expect(find.text('Subir video corto (10s-5m)'), findsOneWidget);

      // Ingresar archivo local directo (ej: archivo mp4 de 27s)
      final inputs = find.byType(TextFormField);
      await tester.ensureVisible(inputs.at(0));
      await tester.enterText(inputs.at(0), r'Z:\Antonyy\ATRIO VARIOS\Login _ Atrio.mp4');
      await tester.pumpAndSettle();

      // Verificar que el validador rechaza si faltan título o predicador
      final formState = tester.state(find.byType(Form)) as FormState;
      expect(formState.validate(), isFalse);

      // Rellenar título
      await tester.ensureVisible(inputs.at(1));
      await tester.enterText(inputs.at(1), 'Mensaje Breve de Avivamiento');
      await tester.pumpAndSettle();

      // Rellenar predicador
      await tester.ensureVisible(inputs.at(2));
      await tester.enterText(inputs.at(2), 'Pastor Andrés Gómez');
      await tester.pumpAndSettle();

      // Con el video directo válido y campos requeridos completos, la validación pasa
      expect(formState.validate(), isTrue);
    });
  });
}
