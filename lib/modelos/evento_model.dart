class EventoModel {
  final String id;
  final String titulo;
  final String organizador;
  final String imagenUrl;
  final String categoria;
  final String fecha;
  final String hora;
  final String lugar;
  final String dia;
  final String mes;
  final String descripcion;
  final int cupoMaximo;
  final int cupoReservado;
  final bool esDestacado;
  final bool estaInscrito;
  final String fallbackBgColor;
  final String fallbackTextColor;

  EventoModel({
    required this.id,
    required this.titulo,
    required this.organizador,
    required this.imagenUrl,
    required this.categoria,
    required this.fecha,
    required this.hora,
    required this.lugar,
    required this.dia,
    required this.mes,
    this.descripcion = '',
    this.cupoMaximo = 100,
    this.cupoReservado = 0,
    this.esDestacado = false,
    this.estaInscrito = false,
    this.fallbackBgColor = '0xFF072B4F',
    this.fallbackTextColor = '0xFFFFFFFF',
  });

  /// Retorna la fracción de ocupación de cupo (0.0 a 1.0)
  double get porcentajeOcupacion =>
      cupoMaximo > 0 ? (cupoReservado / cupoMaximo).clamp(0.0, 1.0) : 0.0;

  /// Permite deserializar tanto estructuras REST genéricas como campos estándar de Odoo 19 (módulo atrio.event)
  factory EventoModel.fromJson(Map<String, dynamic> json) {
    // Extraer día y mes a partir de date (ej: "2026-09-28")
    String diaCalculado = '01';
    String mesCalculado = 'OCT';
    final dateStr = (json['date'] ?? json['date_begin'] ?? json['fecha'])?.toString();
    if (dateStr != null && dateStr.contains('-')) {
      final parts = dateStr.split('T').first.split('-');
      if (parts.length >= 3) {
        diaCalculado = parts[2];
        final mesNum = int.tryParse(parts[1]) ?? 1;
        const meses = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
        if (mesNum >= 1 && mesNum <= 12) {
          mesCalculado = meses[mesNum - 1];
        }
      }
    }

    String img = (json['image_url'] ??
            json['cover_url'] ??
            json['image_1920'] ??
            json['imagen_url'] ??
            '')
        .toString();
    if (img.isNotEmpty && img.startsWith('/')) {
      img = 'https://atrioapp.odoo19rd.com$img';
    }

    final maxCap = json['max_capacity'] ?? json['seats_max'] ?? json['cupo_maximo'] ?? 100;
    final regCount = json['registration_count'] ?? json['seats_reserved'] ?? json['cupo_reservado'] ?? 0;

    return EventoModel(
      id: json['id']?.toString() ?? '',
      titulo: json['title'] ?? json['name'] ?? json['titulo'] ?? 'Evento ATRIO',
      organizador: json['organizer'] ??
          json['organizador'] ??
          json['speaker'] ??
          'Iglesia ATRIO',
      imagenUrl: img,
      categoria: json['category'] ??
          json['event_type'] ??
          json['categoria'] ??
          'General',
      fecha: json['date'] ??
          json['date_display'] ??
          json['date_begin'] ??
          json['fecha'] ??
          '',
      hora: json['time_label'] ??
          json['time_display'] ??
          json['hora'] ??
          'Por confirmar',
      lugar: json['place'] ??
          json['address'] ??
          json['location'] ??
          json['lugar'] ??
          'Auditorio Principal',
      dia: json['day'] ?? json['dia'] ?? diaCalculado,
      mes: json['month'] ?? json['mes'] ?? mesCalculado,
      descripcion: json['description'] ?? json['descripcion'] ?? '',
      cupoMaximo: maxCap is int ? maxCap : (int.tryParse(maxCap.toString()) ?? 100),
      cupoReservado: regCount is int ? regCount : (int.tryParse(regCount.toString()) ?? 0),
      esDestacado: json['is_featured'] ?? json['es_destacado'] ?? false,
      estaInscrito: json['registered'] ?? json['is_registered'] ?? json['esta_inscrito'] ?? false,
      fallbackBgColor: json['fallback_bg_color'] ?? '0xFF072B4F',
      fallbackTextColor: json['fallback_text_color'] ?? '0xFFFFFFFF',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': titulo,
        'organizer': organizador,
        'cover_url': imagenUrl,
        'category': categoria,
        'date_begin': fecha,
        'time_display': hora,
        'location': lugar,
        'day': dia,
        'month': mes,
        'description': descripcion,
        'seats_max': cupoMaximo,
        'seats_reserved': cupoReservado,
        'is_featured': esDestacado,
        'is_registered': estaInscrito,
      };
}
