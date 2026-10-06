class VideoModel {
  final String id;
  final String titulo;
  final String canalOIglesia;
  final String? predicador;
  final String thumbnailUrl;
  final String videoUrl;
  final String categoria;
  final String sinopsis;
  final bool esEnVivo;
  final String? horario;
  final String? duracion;
  final String? estadisticas; // Ej: "1,230 vistas" o "420 en vivo"
  final bool esDestacado;
  final String fallbackBgColor;

  VideoModel({
    required this.id,
    required this.titulo,
    required this.canalOIglesia,
    this.predicador,
    required this.thumbnailUrl,
    this.videoUrl = '',
    required this.categoria,
    this.sinopsis = '',
    this.esEnVivo = false,
    this.horario,
    this.duracion,
    this.estadisticas,
    this.esDestacado = false,
    this.fallbackBgColor = '0xFF1E2D3D',
  });

  /// Deserializa respuestas JSON-RPC o REST provenientes de Odoo 19
  factory VideoModel.fromJson(Map<String, dynamic> json) => VideoModel(
        id: json['id']?.toString() ?? '',
        titulo: json['name'] ?? json['titulo'] ?? '',
        canalOIglesia: json['church_name'] ?? json['canal_o_iglesia'] ?? '',
        predicador: json['speaker'] ?? json['predicador'],
        thumbnailUrl: json['thumbnail_url'] ??
            json['cover_url'] ??
            json['miniatura_url'] ??
            '',
        videoUrl: json['video_url'] ?? json['stream_url'] ?? '',
        categoria: json['category'] ?? json['categoria'] ?? 'Prédicas',
        sinopsis: json['description'] ?? json['sinopsis'] ?? '',
        esEnVivo: json['is_live'] ?? json['es_en_vivo'] ?? false,
        horario: json['schedule'] ?? json['horario'],
        duracion: json['duration'] ?? json['duracion'],
        estadisticas: json['stats'] ?? json['estadisticas'],
        esDestacado: json['is_featured'] ?? json['es_destacado'] ?? false,
        fallbackBgColor: json['fallback_bg_color'] ?? '0xFF1E2D3D',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': titulo,
        'church_name': canalOIglesia,
        'speaker': predicador,
        'thumbnail_url': thumbnailUrl,
        'video_url': videoUrl,
        'category': categoria,
        'description': sinopsis,
        'is_live': esEnVivo,
        'schedule': horario,
        'duration': duracion,
        'stats': estadisticas,
        'is_featured': esDestacado,
      };
}
