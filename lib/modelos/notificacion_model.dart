class NotificacionModel {
  final String id;
  final String titulo;
  final String resumen;
  final String cuerpo;
  final String fecha;
  final String hora;
  final String categoria;
  final String remitente;
  final bool leida;
  final bool esUrgente;
  final String iconCode;
  final String? imageUrl;

  NotificacionModel({
    required this.id,
    required this.titulo,
    required this.resumen,
    required this.cuerpo,
    required this.fecha,
    required this.hora,
    required this.categoria,
    required this.remitente,
    this.leida = false,
    this.esUrgente = false,
    this.iconCode = 'notifications',
    this.imageUrl,
  });

  NotificacionModel copyWith({
    String? id,
    String? titulo,
    String? resumen,
    String? cuerpo,
    String? fecha,
    String? hora,
    String? categoria,
    String? remitente,
    bool? leida,
    bool? esUrgente,
    String? iconCode,
    String? imageUrl,
  }) {
    return NotificacionModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      resumen: resumen ?? this.resumen,
      cuerpo: cuerpo ?? this.cuerpo,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      categoria: categoria ?? this.categoria,
      remitente: remitente ?? this.remitente,
      leida: leida ?? this.leida,
      esUrgente: esUrgente ?? this.esUrgente,
      iconCode: iconCode ?? this.iconCode,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Deserialización flexible adaptada a la API de Odoo 19 (/notifications y atrio.notification)
  factory NotificacionModel.fromJson(Map<String, dynamic> json) =>
      NotificacionModel(
        id: json['id']?.toString() ?? '',
        titulo: json['title'] ?? json['subject'] ?? json['titulo'] ?? json['name'] ?? '',
        resumen: json['summary'] ?? json['message'] ?? json['resumen'] ?? '',
        cuerpo: json['message'] ?? json['body'] ?? json['cuerpo'] ?? json['description'] ?? '',
        fecha: json['send_date'] ?? json['sent_date'] ?? json['date'] ?? json['fecha'] ?? '',
        hora: json['time'] ?? json['hora'] ?? '',
        categoria:
            json['category'] ?? json['categoria'] ?? json['type'] ?? 'General',
        remitente: json['author'] ?? json['church_name'] ?? json['remitente'] ?? 'Iglesia ATRIO',
        leida: json['is_read'] ?? json['leida'] ?? false,
        esUrgente: json['is_urgent'] ?? json['es_urgente'] ?? false,
        iconCode: json['icon_type'] ?? json['icon'] ?? 'notifications',
        imageUrl: json['image_url'] ?? json['imagen_url'] ?? json['image'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': titulo,
        'summary': resumen,
        'body': cuerpo,
        'date': fecha,
        'time': hora,
        'category': categoria,
        'author': remitente,
        'is_read': leida,
        'is_urgent': esUrgente,
        'icon': iconCode,
        'image_url': imageUrl,
      };
}
