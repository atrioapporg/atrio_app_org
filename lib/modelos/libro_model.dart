class LibroModel {
  final String id;
  final String titulo;
  final String autor;
  final String portadaUrl;
  final String categoria;
  final String sinopsis;
  final double progreso; // 0.0 a 1.0 (ej. 0.65 para 65%)
  final bool esDestacado;
  final String? audioUrl;
  final int totalPaginas;
  final String fallbackBgColor;
  final String fallbackTextColor;

  LibroModel({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.portadaUrl,
    required this.categoria,
    this.sinopsis = '',
    this.progreso = 0.0,
    this.esDestacado = false,
    this.audioUrl,
    this.totalPaginas = 0,
    this.fallbackBgColor = '0xFF1E2E3D',
    this.fallbackTextColor = '0xFFFFFFFF',
  });

  /// Permite deserializar tanto estructuras REST genéricas como campos estándar de Odoo 19
  factory LibroModel.fromJson(Map<String, dynamic> json) => LibroModel(
        id: json['id']?.toString() ?? '',
        titulo: json['name'] ?? json['titulo'] ?? '',
        autor: json['author'] ?? json['autor'] ?? '',
        portadaUrl: json['cover_url'] ?? json['portada_url'] ?? '',
        categoria: json['category'] ?? json['categoria'] ?? 'Vida cristiana',
        sinopsis: json['description'] ?? json['sinopsis'] ?? '',
        progreso:
            ((json['reading_progress'] ?? json['progreso'] ?? 0.0) as num)
                .toDouble(),
        esDestacado: json['is_featured'] ?? json['es_destacado'] ?? false,
        audioUrl: json['audio_url'],
        totalPaginas: json['total_pages'] ?? json['total_paginas'] ?? 0,
        fallbackBgColor: json['fallback_bg_color'] ?? '0xFF1E2E3D',
        fallbackTextColor: json['fallback_text_color'] ?? '0xFFFFFFFF',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': titulo,
        'author': autor,
        'cover_url': portadaUrl,
        'category': categoria,
        'description': sinopsis,
        'reading_progress': progreso,
        'is_featured': esDestacado,
        'audio_url': audioUrl,
        'total_pages': totalPaginas,
      };
}
