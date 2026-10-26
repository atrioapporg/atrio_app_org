import 'package:flutter/foundation.dart';
import '../utils/youtube_helper.dart';

export '../utils/youtube_helper.dart' show StreamingPlatform;

/// DTO Inmutable para la creación, consulta y streaming de Prédicas y Cultos en Vivo.
@immutable
class SermonDto {
  final int? id;
  final String titulo;
  final String predicador;
  final DateTime fecha;
  final bool esEnVivo;
  final StreamingPlatform plataforma;
  final String urlOIdVideo;
  final String? descripcion;
  final String? miniaturaUrl;
  final String? imagenPortadaBase64;
  final String categoria;
  final bool fijado;
  final String? canalOIglesia;

  const SermonDto({
    this.id,
    required this.titulo,
    required this.predicador,
    required this.fecha,
    this.esEnVivo = false,
    this.plataforma = StreamingPlatform.youtube,
    required this.urlOIdVideo,
    this.descripcion,
    this.miniaturaUrl,
    this.imagenPortadaBase64,
    this.categoria = 'Prédicas',
    this.fijado = false,
    this.canalOIglesia,
  });

  /// Extrae el ID canónico de YouTube si la plataforma es YouTube.
  String? get youtubeId => YoutubeHelper.extractId(urlOIdVideo);

  /// Indica si la transmisión o video corresponde a YouTube.
  bool get esYoutube =>
      plataforma == StreamingPlatform.youtube ||
      YoutubeHelper.isValidYoutubeUrlOrId(urlOIdVideo);

  /// Retorna la URL de la miniatura efectiva (de Odoo o autogenerada por YouTube).
  String get miniaturaEfectiva {
    if (miniaturaUrl != null && miniaturaUrl!.trim().isNotEmpty) {
      return miniaturaUrl!.trim();
    }
    final ytId = youtubeId;
    if (ytId != null && ytId.isNotEmpty) {
      return YoutubeHelper.buildThumbnailUrl(ytId);
    }
    return '';
  }

  /// Deserialización tolerante para respuestas de Odoo 19 (`atrio.post` y catálogo de videos).
  factory SermonDto.fromJson(Map<String, dynamic> json) {
    // Identificador
    final rawId = json['id'];
    final int? parsedId = rawId is int
        ? rawId
        : (rawId != null ? int.tryParse(rawId.toString()) : null);

    // Fecha (ISO 8601 UTC de Odoo 19)
    final rawDate = (json['date'] ??
            json['publish_date'] ??
            json['fecha'] ??
            json['create_date'])
        ?.toString();
    final fechaParsed = rawDate != null
        ? (DateTime.tryParse(rawDate)?.toLocal() ?? DateTime.now())
        : DateTime.now();

    // URL o ID del video
    final videoUrlOrId = (json['url_o_id_video'] ??
            json['video_url'] ??
            json['stream_url'] ??
            json['youtube_id'] ??
            '')
        .toString()
        .trim();

    // Detección automática o asignación de plataforma
    final rawPlatform = json['plataforma'] ?? json['platform'];
    final plataformaParsed = rawPlatform != null
        ? StreamingPlatform.fromString(rawPlatform.toString())
        : YoutubeHelper.detectPlatform(videoUrlOrId);

    // Miniatura / Imagen
    String? thumb = (json['thumbnail_url'] ??
            json['cover_url'] ??
            json['image_url'] ??
            json['miniatura_url'])
        ?.toString();
    if (thumb != null && thumb.isNotEmpty && thumb.startsWith('/')) {
      thumb = 'https://atrioapp.odoo19rd.com$thumb';
    }

    return SermonDto(
      id: parsedId,
      titulo: (json['title'] ??
              json['name'] ??
              json['titulo'] ??
              'Prédica Congregacional')
          .toString(),
      predicador: (json['speaker'] ??
              json['predicador'] ??
              json['author_name'] ??
              'Pastor de la Comunidad')
          .toString(),
      fecha: fechaParsed,
      esEnVivo: (json['is_live'] ??
              json['es_en_vivo'] ??
              json['live'] ??
              false) ==
          true,
      plataforma: plataformaParsed,
      urlOIdVideo: videoUrlOrId,
      descripcion: (json['description'] ??
              json['content'] ??
              json['sinopsis'] ??
              json['descripcion'])
          ?.toString(),
      miniaturaUrl: thumb,
      categoria: (json['category'] ?? json['categoria'] ?? 'Prédicas').toString(),
      fijado: (json['pinned'] ?? json['is_pinned'] ?? json['fijado'] ?? false) ==
          true,
      canalOIglesia: (json['church_name'] ??
              json['canal_o_iglesia'] ??
              json['channel'])
          ?.toString(),
    );
  }

  /// Serialización segura para la API de Odoo 19 (`POST /admin/posts` o `PUT /admin/posts/{id}`).
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': titulo,
      'name': titulo,
      'speaker': predicador,
      'predicador': predicador,
      'date': fecha.toUtc().toIso8601String(),
      'publish_date': fecha.toUtc().toIso8601String(),
      'is_live': esEnVivo,
      'platform': plataforma.toOdooString(),
      'video_url': urlOIdVideo,
      'url_o_id_video': urlOIdVideo,
      if (descripcion != null && descripcion!.isNotEmpty) ...{
        'content': descripcion,
        'description': descripcion,
      },
      if (imagenPortadaBase64 != null && imagenPortadaBase64!.isNotEmpty)
        'image_1920': imagenPortadaBase64,
      'category': categoria,
      'pinned': fijado,
      'action': 'publish',
    };
  }

  /// Crea una copia inmutable con valores modificados.
  SermonDto copyWith({
    int? id,
    String? titulo,
    String? predicador,
    DateTime? fecha,
    bool? esEnVivo,
    StreamingPlatform? plataforma,
    String? urlOIdVideo,
    String? descripcion,
    String? miniaturaUrl,
    String? imagenPortadaBase64,
    String categoria = 'Prédicas',
    bool? fijado,
    String? canalOIglesia,
  }) {
    return SermonDto(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      predicador: predicador ?? this.predicador,
      fecha: fecha ?? this.fecha,
      esEnVivo: esEnVivo ?? this.esEnVivo,
      plataforma: plataforma ?? this.plataforma,
      urlOIdVideo: urlOIdVideo ?? this.urlOIdVideo,
      descripcion: descripcion ?? this.descripcion,
      miniaturaUrl: miniaturaUrl ?? this.miniaturaUrl,
      imagenPortadaBase64: imagenPortadaBase64 ?? this.imagenPortadaBase64,
      categoria: categoria,
      fijado: fijado ?? this.fijado,
      canalOIglesia: canalOIglesia ?? this.canalOIglesia,
    );
  }
}
