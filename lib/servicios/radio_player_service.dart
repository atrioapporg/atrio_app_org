import 'package:atrio/modelos/emisora_model.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class RadioPlayerService {
  RadioPlayerService._();
  static final RadioPlayerService instance = RadioPlayerService._();

  AudioPlayer? _player;
  AudioPlayer get player => _player ??= AudioPlayer();

  Future<void> reproducirEmisora(EmisoraModel emisora) async {
    final activePlayer = player;
    try {
      final mediaItem = MediaItem(
        id: emisora.id,
        album: emisora.dial,
        title: emisora.nombre,
        artUri: Uri.tryParse(emisora.logoUrl),
      );

      final audioSource = AudioSource.uri(
        Uri.parse(emisora.streamUrl),
        tag: mediaItem,
      );

      await activePlayer.setAudioSource(audioSource);
      await activePlayer.play();
    } catch (e) {
      if (emisora.streamUrlFallback.isNotEmpty) {
        final fallbackSource = AudioSource.uri(
          Uri.parse(emisora.streamUrlFallback),
          tag: MediaItem(
            id: '${emisora.id}_fallback',
            album: emisora.dial,
            title: emisora.nombre,
            artUri: Uri.tryParse(emisora.logoUrl),
          ),
        );
        await activePlayer.setAudioSource(fallbackSource);
        await activePlayer.play();
      } else {
        rethrow;
      }
    }
  }

  void pausar() => _player?.pause();
  void detener() => _player?.stop();
}
