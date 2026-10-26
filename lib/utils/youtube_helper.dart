import 'package:flutter/foundation.dart';

/// Enumeración de plataformas de streaming de video soportadas por ATRIO.
enum StreamingPlatform {
  youtube,
  vimeo,
  hlsDirect;

  /// Parsea una cadena al enum [StreamingPlatform] de forma tolerante.
  static StreamingPlatform fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'vimeo':
        return StreamingPlatform.vimeo;
      case 'hls_direct':
      case 'hls':
      case 'm3u8':
        return StreamingPlatform.hlsDirect;
      case 'youtube':
      default:
        return StreamingPlatform.youtube;
    }
  }

  /// Retorna la cadena estándar para almacenar o enviar a Odoo 19.
  String toOdooString() {
    switch (this) {
      case StreamingPlatform.youtube:
        return 'youtube';
      case StreamingPlatform.vimeo:
        return 'vimeo';
      case StreamingPlatform.hlsDirect:
        return 'hls_direct';
    }
  }
}

/// Helper especializado para el análisis, extracción de identificadores y
/// construcción de URLs de streaming para YouTube y otras plataformas de video.
@immutable
class YoutubeHelper {
  const YoutubeHelper._();

  /// Expresión regular robusta que cubre todas las variantes conocidas de URLs de YouTube:
  /// - Estándar: https://www.youtube.com/watch?v=XXXXXXXXXXX
  /// - Con parámetros: https://www.youtube.com/watch?feature=share&v=XXXXXXXXXXX&t=12
  /// - Enlaces cortos: https://youtu.be/XXXXXXXXXXX
  /// - Transmisión en Vivo: https://www.youtube.com/live/XXXXXXXXXXX
  /// - Móvil: https://m.youtube.com/watch?v=XXXXXXXXXXX
  /// - Embebido: https://www.youtube.com/embed/XXXXXXXXXXX
  /// - Shorts: https://www.youtube.com/shorts/XXXXXXXXXXX
  /// - URL antigua: https://www.youtube.com/v/XXXXXXXXXXX
  static final RegExp _youtubeUrlRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|live\/|shorts\/))([\w-]{11})(?:[^\w-]|$)',
    caseSensitive: false,
  );

  /// Expresión regular para validar si una cadena es un ID directo de YouTube (11 caracteres alfanuméricos, guiones o guiones bajos).
  static final RegExp _directIdRegex = RegExp(r'^[\w-]{11}$');

  /// Expresión regular para canales con handle (@nombreCanal, ej: @AtrioIglesia)
  static final RegExp _channelHandleRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.|m\.)?youtube\.com\/(@[\w.-]+)(?:\/(?:live|streams|videos|featured))?(?:[?&].*)?$',
    caseSensitive: false,
  );

  /// Expresión regular para canales con ID de canal clásico (UC... de 24 caracteres)
  static final RegExp _channelIdRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.|m\.)?youtube\.com\/channel\/(UC[\w-]{22})(?:\/(?:live|streams|videos|featured))?(?:[?&].*)?$',
    caseSensitive: false,
  );

  /// Expresión regular para validar si una cadena es directamente un handle (@AtrioIglesia)
  static final RegExp _directHandleRegex = RegExp(r'^@[\w.-]+$');

  /// Expresión regular para validar si una cadena es directamente un Channel ID (UC...)
  static final RegExp _directChannelIdRegex = RegExp(r'^UC[\w-]{22}$');

  /// Extrae el ID canónico de YouTube (11 caracteres) a partir de cualquier variante de URL o ID directo.
  /// Retorna `null` si la cadena no contiene un ID de video válido (por ejemplo, si es una URL de canal).
  static String? extractId(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // 1. Verificar si ya es un ID directo de 11 caracteres
    if (_directIdRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    // 2. Extraer mediante regex de URL completa de video
    final match = _youtubeUrlRegex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      if (id != null && _directIdRegex.hasMatch(id)) {
        return id;
      }
    }

    return null;
  }

  /// Extrae el handle de un canal de YouTube (ej: `@AtrioIglesia`) si el texto corresponde a un canal.
  static String? extractChannelHandle(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    if (_directHandleRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    final match = _channelHandleRegex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  /// Extrae el identificador canónico de canal (ej: `UCuW2ZM9B8MEm5FiKBQENjTw`) si corresponde.
  static String? extractChannelId(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    if (_directChannelIdRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    final match = _channelIdRegex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  /// Indica si la cadena corresponde a la URL o handle de un canal de YouTube.
  static bool isChannelUrl(String? input) {
    return extractChannelHandle(input) != null || extractChannelId(input) != null;
  }

  /// Indica si la URL apunta específicamente a la transmisión permanente en vivo de un canal
  /// (ej: `https://www.youtube.com/@AtrioIglesia/live` o `https://www.youtube.com/channel/UC.../live`).
  static bool isChannelLiveUrl(String? input) {
    if (input == null) return false;
    final lower = input.trim().toLowerCase();
    return (lower.contains('/@') || lower.contains('/channel/')) &&
        lower.contains('/live');
  }

  /// Indica si la ruta o URL corresponde a un archivo de video directo (MP4, WebM, MOV).
  static bool isDirectVideoFile(String? input) {
    if (input == null) return false;
    final lower = input.trim().toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m4v');
  }

  /// Verifica si una cadena es una URL o ID de YouTube válido (video, canal o transmisión).
  static bool isValidYoutubeUrlOrId(String? input) {
    if (input == null) return false;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;

    // Acepta ID de video, URL de video, handle de canal, ID de canal o URL de canal
    return extractId(trimmed) != null || isChannelUrl(trimmed);
  }

  /// Detecta la plataforma de video adecuada analizando la URL.
  static StreamingPlatform detectPlatform(String? url) {
    if (url == null || url.trim().isEmpty) return StreamingPlatform.youtube;
    final lower = url.trim().toLowerCase();

    if (lower.contains('vimeo.com')) {
      return StreamingPlatform.vimeo;
    }
    if (lower.endsWith('.m3u8') || lower.contains('/hls/')) {
      return StreamingPlatform.hlsDirect;
    }
    return StreamingPlatform.youtube;
  }

  /// Construye la URL estándar de reproducción en YouTube a partir del [videoId].
  static String buildWatchUrl(String videoId) {
    final cleanId = extractId(videoId) ?? videoId.trim();
    return 'https://www.youtube.com/watch?v=$cleanId';
  }

  /// Construye la URL de la miniatura de YouTube en resolución estándar o de alta calidad.
  /// [highQuality] define si se solicita `maxresdefault.jpg` (1280x720) o `hqdefault.jpg` (480x360).
  static String buildThumbnailUrl(String videoId, {bool highQuality = true}) {
    final cleanId = extractId(videoId) ?? videoId.trim();
    final qualityPath = highQuality ? 'maxresdefault.jpg' : 'hqdefault.jpg';
    return 'https://img.youtube.com/vi/$cleanId/$qualityPath';
  }

  /// Construye la URL del reproductor embebido compatible con web y iframes.
  static String buildEmbedUrl(String videoId, {bool autoPlay = false}) {
    final cleanId = extractId(videoId) ?? videoId.trim();
    final autoPlayParam = autoPlay ? '?autoplay=1' : '';
    return 'https://www.youtube.com/embed/$cleanId$autoPlayParam';
  }
}
