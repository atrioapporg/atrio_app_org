// ignore_for_file: depend_on_referenced_packages
import 'package:atrio/modelos/emisora_model.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

class RadioPlayerService {
  RadioPlayerService._();
  static final RadioPlayerService instance = RadioPlayerService._();

  static JustAudioPlatform? _defaultPlatform;
  static bool _backgroundInitialized = false;
  static bool get isBackgroundInitialized => _backgroundInitialized;

  /// Inicializa `JustAudioBackground` de forma segura.
  /// Si la inicialización del servicio en segundo plano falla en algún entorno,
  /// restaura automáticamente la plataforma nativa original de `just_audio` para
  /// evitar `LateInitializationError: Field '_audioHandler' has not been initialized`
  /// y bloqueos posteriores de instancia única.
  static Future<void> initBackgroundAudio() async {
    _defaultPlatform ??= JustAudioPlatform.instance;
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.atrio.app.channel.audio',
        androidNotificationChannelName: 'ATRIO Radio y Audio',
        androidNotificationOngoing: true,
      );
      _backgroundInitialized = true;
    } catch (e) {
      _backgroundInitialized = false;
      if (_defaultPlatform != null) {
        JustAudioPlatform.instance = _defaultPlatform!;
      }
      debugPrint('Aviso inicializando JustAudioBackground: $e');
    }
  }

  AudioPlayer? _player;

  /// Única instancia compartida de [AudioPlayer] en toda la aplicación.
  /// `just_audio_background` exige estrictamente una sola instancia activa.
  AudioPlayer get player => _player ??= AudioPlayer();

  /// Restaura la plataforma por defecto y recrea el reproductor en caso de error crítico del handler.
  Future<AudioPlayer> recoverFromHandlerError() async {
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    if (_defaultPlatform != null) {
      JustAudioPlatform.instance = _defaultPlatform!;
      _backgroundInitialized = false;
    }
    return player;
  }

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

