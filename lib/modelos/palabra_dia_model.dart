class PalabraDelDiaModel {
  final String id;
  final String titulo;
  final String autor;
  final String textoBreve;
  final String contenidoCompleto;
  final String citaBiblica;
  final String? imagenFondo;

  const PalabraDelDiaModel({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.textoBreve,
    required this.contenidoCompleto,
    required this.citaBiblica,
    this.imagenFondo,
  });

  factory PalabraDelDiaModel.fromJson(Map<String, dynamic> json) {
    return PalabraDelDiaModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo'] ?? json['title'] ?? '',
      autor: json['autor'] ?? json['author'] ?? '',
      textoBreve: json['texto_breve'] ?? json['excerpt'] ?? '',
      contenidoCompleto:
          json['contenido_completo'] ?? json['content'] ?? json['texto_breve'] ?? '',
      citaBiblica: json['cita_biblica'] ?? json['reference'] ?? '',
      imagenFondo: json['imagen_fondo'] ?? json['image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'autor': autor,
        'texto_breve': textoBreve,
        'contenido_completo': contenidoCompleto,
        'cita_biblica': citaBiblica,
        'imagen_fondo': imagenFondo,
      };
}
