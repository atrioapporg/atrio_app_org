class IglesiaModel {
  final int id;
  final String nombre;
  final String denominacion;
  final double calificacion;
  final int totalResenas;
  final String distancia;
  final bool esVerificada;
  final String direccion;
  final String plusCode;
  final String telefono;
  final String sitioWeb;
  final ProximoCulto proximoCulto;
  final List<HorarioServicio> horarios;
  final AvisoIglesia avisoActual;

  IglesiaModel({
    required this.id,
    required this.nombre,
    required this.denominacion,
    required this.calificacion,
    required this.totalResenas,
    required this.distancia,
    required this.esVerificada,
    required this.direccion,
    required this.plusCode,
    required this.telefono,
    required this.sitioWeb,
    required this.proximoCulto,
    required this.horarios,
    required this.avisoActual,
  });

  factory IglesiaModel.fromJson(Map<String, dynamic> json) {
    return IglesiaModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      denominacion: json['denominacion'] as String,
      calificacion: (json['calificacion'] as num).toDouble(),
      totalResenas: json['total_resenas'] as int,
      distancia: json['distancia'] as String,
      esVerificada: json['es_verificada'] as bool,
      direccion: json['direccion'] as String,
      plusCode: json['plus_code'] as String,
      telefono: json['telefono'] as String,
      sitioWeb: json['sitio_web'] as String,
      proximoCulto: ProximoCulto.fromJson(
        json['proximo_culto'] as Map<String, dynamic>,
      ),
      horarios: (json['horarios'] as List<dynamic>)
          .map((item) => HorarioServicio.fromJson(item as Map<String, dynamic>))
          .toList(),
      avisoActual: AvisoIglesia.fromJson(
        json['aviso_actual'] as Map<String, dynamic>,
      ),
    );
  }
}

class ProximoCulto {
  final String titulo;
  final String diaHora;
  final String estado;

  ProximoCulto({
    required this.titulo,
    required this.diaHora,
    required this.estado,
  });

  factory ProximoCulto.fromJson(Map<String, dynamic> json) {
    return ProximoCulto(
      titulo: json['titulo'] as String,
      diaHora: json['dia_hora'] as String,
      estado: json['estado'] as String,
    );
  }
}

class HorarioServicio {
  final String dia;
  final String detalle;
  final String tipo;

  HorarioServicio({
    required this.dia,
    required this.detalle,
    required this.tipo,
  });

  factory HorarioServicio.fromJson(Map<String, dynamic> json) {
    return HorarioServicio(
      dia: json['dia'] as String,
      detalle: json['detalle'] as String,
      tipo: json['tipo'] as String,
    );
  }
}

class AvisoIglesia {
  final String titulo;
  final String descripcion;

  AvisoIglesia({required this.titulo, required this.descripcion});

  factory AvisoIglesia.fromJson(Map<String, dynamic> json) {
    return AvisoIglesia(
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
    );
  }
}
