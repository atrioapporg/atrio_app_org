// ignore_for_file: depend_on_referenced_packages
import 'package:atrio/servicios/radio_player_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      return '.';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  group('RadioPlayerService - Resiliencia y Singleton AudioPlayer', () {
    test(
      'Mantiene una única instancia compartida de AudioPlayer y permite recuperación ante error de handler',
      () async {
        final originalPlatform = JustAudioPlatform.instance;

        await RadioPlayerService.initBackgroundAudio();

        final player1 = RadioPlayerService.instance.player;
        final player2 = RadioPlayerService.instance.player;

        expect(player1, same(player2));

        // Verificar recuperación de emergencia ante fallo de handler
        final recoveredPlayer =
            await RadioPlayerService.instance.recoverFromHandlerError();
        expect(recoveredPlayer, isNotNull);
        expect(RadioPlayerService.isBackgroundInitialized, isFalse);
        expect(JustAudioPlatform.instance, same(originalPlatform));
        expect(RadioPlayerService.instance.player, same(recoveredPlayer));
      },
    );
  });
}
