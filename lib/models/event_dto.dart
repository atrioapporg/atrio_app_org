import 'package:flutter/foundation.dart';

/// Modalidad del evento congregacional.
enum EventModality {
  presencial,
  virtual,
  hibrido;

  /// Parsea valores de la API de Odoo 19 a [EventModality].
  static EventModality fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'virtual':
      case 'online':
      case 'en_linea':
        return EventModality.virtual;
      case 'hibrido':
      case 'hybrid':
      case 'mixto':
        return EventModality.hibrido;
      case 'presencial':
      case 'in_person':
      default:
        return EventModality.presencial;
    }
  }

  /// Retorna la cadena para serializar a Odoo 19.
  String toOdooString() {
    switch (this) {
      case EventModality.presencial:
        return 'presencial';
      case EventModality.virtual:
        return 'virtual';
      case EventModality.hibrido:
        return 'hibrido';
    }
  }

  /// Etiqueta visual para la interfaz de usuario.
  String get label {
    switch (this) {
      case EventModality.presencial:
        return 'Presencial';
      case EventModality.virtual:
        return 'Virtual / Streaming';
      case EventModality.hibrido:
        return 'Híbrido (Presencial y En Vivo)';
    }
  }
}

/// DTO Inmutable para la creación, edición y consulta de Eventos en ATRIO y Odoo 19.
@immutable
class EventDto {
  final int? id;
  final String titulo;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final EventModality modalidad;
  final String? enlaceUbicacionOStream;
  final String? imagenPortadaBase64;
  final String? coverUrl;
  final int cupoMaximo;
  final int cupoReservado;
  final bool esDestacado;
  final String? organizador;
  final String? categoria;
  final String? lugar;

  const EventDto({
    this.id,
    required this.titulo,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    this.modalidad = EventModality.presencial,
    this.enlaceUbicacionOStream,
    this.imagenPortadaBase64,
    this.coverUrl,
    this.cupoMaximo = 100,
    this.cupoReservado = 0,
    this.esDestacado = false,
    this.organizador,
    this.categoria,
    this.lugar,
  });

  /// Indica si el evento incluye componente virtual o transmisión en directo.
  bool get tieneStreaming =>
      modalidad == EventModality.virtual || modalidad == EventModality.hibrido;

  /// Retorna la fracción de ocupación del cupo (0.0 a 1.0).
  double get porcentajeOcupacion =>
      cupoMaximo > 0 ? (cupoReservado / cupoMaximo).clamp(0.0, 1.0) : 0.0;

  /// Indica si aún quedan cupos disponibles para inscripción.
  bool get tieneCupoDisponible => cupoMaximo <= 0 || cupoReservado < cupoMaximo;

  /// Deserialización segura tolerante a respuestas de Odoo 19 (`atrio.event` y endpoints REST).
  factory EventDto.fromJson(Map<String, dynamic> json) {
    // Parseo seguro de identificador
    final rawId = json['id'];
    final int? parsedId = rawId is int
        ? rawId
        : (rawId != null ? int.tryParse(rawId.toString()) : null);

    // Parseo de fechas (formato ISO 8601 UTC de Odoo 19 o 'YYYY-MM-DD' con 'time'/'time_label')
    final dateBeginStr = (json['date_begin'] ??
            json['date_start'] ??
            json['fecha_inicio'] ??
            json['date'])
        ?.toString();
    final dateEndStr = (json['date_end'] ??
            json['date_finish'] ??
            json['fecha_fin'])
        ?.toString();

    final now = DateTime.now();
    DateTime fechaInicioParsed = now;
    if (dateBeginStr != null && dateBeginStr.isNotEmpty) {
      final parsed = DateTime.tryParse(dateBeginStr)?.toLocal();
      if (parsed != null) {
        fechaInicioParsed = parsed;
        // Si el string era solo de fecha (YYYY-MM-DD) y viene time_label o time
        if (!dateBeginStr.contains('T') && !dateBeginStr.contains(':')) {
          final timeLabel = json['time_label']?.toString();
          if (timeLabel != null && timeLabel.contains(':')) {
            final parts = timeLabel.split(':');
            final h = int.tryParse(parts[0]) ?? 0;
            final m = int.tryParse(parts[1]) ?? 0;
            fechaInicioParsed = DateTime(
              parsed.year,
              parsed.month,
              parsed.day,
              h,
              m,
            );
          } else if (json['time'] is num) {
            final timeNum = (json['time'] as num).toDouble();
            final h = timeNum.floor();
            final m = ((timeNum - h) * 60).round();
            fechaInicioParsed = DateTime(
              parsed.year,
              parsed.month,
              parsed.day,
              h,
              m,
            );
          }
        }
      }
    }

    final fechaFinParsed = dateEndStr != null
        ? (DateTime.tryParse(dateEndStr)?.toLocal() ??
            fechaInicioParsed.add(const Duration(hours: 2)))
        : fechaInicioParsed.add(const Duration(hours: 2));

    // Modalidad
    final rawModality = json['modalidad'] ??
        json['modality'] ??
        json['event_mode'] ??
        json['mode'];
    final modalidadParsed = EventModality.fromString(rawModality?.toString());

    // Portada / URL de imagen
    String? coverUrlParsed = (json['cover_url'] ??
            json['image_url'] ??
            json['image_1920_url'] ??
            json['cover_image'])
        ?.toString();
    if (coverUrlParsed != null &&
        coverUrlParsed.isNotEmpty &&
        coverUrlParsed.startsWith('/')) {
      coverUrlParsed = 'https://atrioapp.odoo19rd.com$coverUrlParsed';
    }

    final maxCap = json['max_capacity'] ??
        json['seats_max'] ??
        json['cupo_maximo'] ??
        100;
    final regCount = json['registration_count'] ??
        json['seats_reserved'] ??
        json['cupo_reservado'] ??
        0;

    return EventDto(
      id: parsedId,
      titulo: (json['title'] ??
              json['name'] ??
              json['titulo'] ??
              'Evento Congregacional')
          .toString(),
      descripcion: (json['description'] ??
              json['content'] ??
              json['descripcion'] ??
              '')
          .toString(),
      fechaInicio: fechaInicioParsed,
      fechaFin: fechaFinParsed,
      modalidad: modalidadParsed,
      enlaceUbicacionOStream: (json['enlace_ubicacion_o_stream'] ??
              json['stream_url'] ??
              json['stream_link'] ??
              json['meeting_link'] ??
              json['location_url'] ??
              json['virtual_link'])
          ?.toString(),
      coverUrl: coverUrlParsed,
      cupoMaximo: maxCap is int
          ? maxCap
          : (int.tryParse(maxCap.toString()) ?? 100),
      cupoReservado: regCount is int
          ? regCount
          : (int.tryParse(regCount.toString()) ?? 0),
      esDestacado: (json['is_featured'] ??
              json['featured'] ??
              json['es_destacado'] ??
              false) ==
          true,
      organizador: (json['organizer'] ??
              json['organizador'] ??
              json['speaker'] ??
              json['church_name'])
          ?.toString(),
      categoria: (json['category'] ??
              json['event_type'] ??
              json['categoria'] ??
              'General')
          .toString(),
      lugar: (json['place'] ??
              json['address'] ??
              json['location'] ??
              json['lugar'])
          ?.toString(),
    );
  }

  /// Serialización segura hacia el backend Odoo 19 para `POST /admin/events` o `PUT /admin/events/{id}`.
  Map<String, dynamic> toJson() {
    final y = fechaInicio.year.toString().padLeft(4, '0');
    final m = fechaInicio.month.toString().padLeft(2, '0');
    final d = fechaInicio.day.toString().padLeft(2, '0');
    final dateFormatted = '$y-$m-$d';
    final hh = fechaInicio.hour.toString().padLeft(2, '0');
    final mm = fechaInicio.minute.toString().padLeft(2, '0');
    final timeLabel = '$hh:$mm';
    final timeFloat = fechaInicio.hour + (fechaInicio.minute / 60.0);

    return {
      if (id != null) 'id': id,
      'name': titulo,
      'title': titulo,
      'titulo': titulo,
      'description': descripcion,
      'content': descripcion,
      'date': dateFormatted,
      'date_begin': fechaInicio.toUtc().toIso8601String(),
      'date_end': fechaFin.toUtc().toIso8601String(),
      'time': timeFloat,
      'time_label': timeLabel,
      'modalidad': modalidad.toOdooString(),
      'modality': modalidad.toOdooString(),
      if (enlaceUbicacionOStream != null && enlaceUbicacionOStream!.isNotEmpty) ...{
        'stream_url': enlaceUbicacionOStream,
        'enlace_ubicacion_o_stream': enlaceUbicacionOStream,
      },
      if (lugar != null && lugar!.isNotEmpty) ...{
        'place': lugar,
        'location': lugar,
      },
      if (imagenPortadaBase64 != null && imagenPortadaBase64!.isNotEmpty) ...{
        'image_1920': imagenPortadaBase64,
        'image': imagenPortadaBase64,
        'cover_image': imagenPortadaBase64,
      },
      'seats_max': cupoMaximo,
      'max_capacity': cupoMaximo,
      'allow_registration': true,
      'audience': 'todos',
      'show_in_calendar': true,
      'is_featured': esDestacado,
      if (categoria != null) 'category': categoria,
      if (organizador != null) 'organizer': organizador,
    };
  }

  /// Crea una copia inmutable con valores actualizados.
  EventDto copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    EventModality? modalidad,
    String? enlaceUbicacionOStream,
    String? imagenPortadaBase64,
    String? coverUrl,
    int? cupoMaximo,
    int? cupoReservado,
    bool? esDestacado,
    String? organizador,
    String? categoria,
    String? lugar,
  }) {
    return EventDto(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      modalidad: modalidad ?? this.modalidad,
      enlaceUbicacionOStream:
          enlaceUbicacionOStream ?? this.enlaceUbicacionOStream,
      imagenPortadaBase64: imagenPortadaBase64 ?? this.imagenPortadaBase64,
      coverUrl: coverUrl ?? this.coverUrl,
      cupoMaximo: cupoMaximo ?? this.cupoMaximo,
      cupoReservado: cupoReservado ?? this.cupoReservado,
      esDestacado: esDestacado ?? this.esDestacado,
      organizador: organizador ?? this.organizador,
      categoria: categoria ?? this.categoria,
      lugar: lugar ?? this.lugar,
    );
  }
}
