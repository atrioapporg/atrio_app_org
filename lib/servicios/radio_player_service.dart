import 'package:atrio/modelos/emisora_model.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class RadioPlayerService {
  RadioPlayerService._();
  static final RadioPlayerService instance = RadioPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  Future<void> reproducirEmisora(EmisoraModel emisora) async {
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

      await _player.setAudioSource(audioSource);
      _player.play();
    } catch (e) {
      if (emisora.streamUrlFallback.isNotEmpty) {
        final fallbackSource = AudioSource.uri(
          Uri.parse(emisora.streamUrlFallback),
        );
        await _player.setAudioSource(fallbackSource);
        _player.play();
      } else {
        rethrow;
      }
    }
  }

  void pausar() => _player.pause();
  void detener() => _player.stop();
}
