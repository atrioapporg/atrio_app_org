class AnuncioModel {
  final String id;
  final String titulo;
  final String artista;
  final String subtitulo;
  final String descripcion;
  final String imagenUrl;
  final String fecha;
  final String lugar;
  final String categoria;
  final String etiqueta;
  final String enlaceAccion;
  final String textoAccion;
  final bool esDestacado;
  final String fallbackBgColor;
  final String fallbackTextColor;

  AnuncioModel({
    required this.id,
    required this.titulo,
    required this.artista,
    required this.subtitulo,
    required this.descripcion,
    required this.imagenUrl,
    required this.fecha,
    required this.lugar,
    this.categoria = 'Concierto',
    this.etiqueta = 'ANUNCIO',
    this.enlaceAccion = '',
    this.textoAccion = 'Más información',
    this.esDestacado = false,
    this.fallbackBgColor = '0xFF072B4F',
    this.fallbackTextColor = '0xFFFFFFFF',
  });

  /// Deserialización flexible preparada para el backend de Odoo 19
  factory AnuncioModel.fromJson(Map<String, dynamic> json) => AnuncioModel(
        id: json['id']?.toString() ?? '',
        titulo: json['name'] ?? json['titulo'] ?? '',
        artista: json['artist'] ?? json['artista'] ?? json['organizer'] ?? '',
        subtitulo: json['subtitle'] ?? json['subtitulo'] ?? '',
        descripcion: json['description'] ?? json['descripcion'] ?? '',
        imagenUrl: json['cover_url'] ??
            json['image_1920'] ??
            json['imagen_url'] ??
            '',
        fecha: json['date'] ?? json['fecha'] ?? '',
        lugar: json['location'] ?? json['lugar'] ?? '',
        categoria: json['category'] ?? json['categoria'] ?? 'Concierto',
        etiqueta: json['tag'] ?? json['etiqueta'] ?? 'ANUNCIO',
        enlaceAccion: json['action_url'] ?? json['enlace_accion'] ?? '',
        textoAccion:
            json['action_text'] ?? json['texto_accion'] ?? 'Más información',
        esDestacado: json['is_featured'] ?? json['es_destacado'] ?? false,
        fallbackBgColor: json['fallback_bg_color'] ?? '0xFF072B4F',
        fallbackTextColor: json['fallback_text_color'] ?? '0xFFFFFFFF',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': titulo,
        'artist': artista,
        'subtitle': subtitulo,
        'description': descripcion,
        'cover_url': imagenUrl,
        'date': fecha,
        'location': lugar,
        'category': categoria,
        'tag': etiqueta,
        'action_url': enlaceAccion,
        'action_text': textoAccion,
        'is_featured': esDestacado,
        'fallback_bg_color': fallbackBgColor,
        'fallback_text_color': fallbackTextColor,
      };
}
