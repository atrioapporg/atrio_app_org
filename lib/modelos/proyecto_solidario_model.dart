class ProyectosSolidariosData {
  final String lema;
  final ProyectoModel proyectoDestacado;
  final List<CampanaSecundariaModel> otrasCampanas;

  ProyectosSolidariosData({
    required this.lema,
    required this.proyectoDestacado,
    required this.otrasCampanas,
  });

  factory ProyectosSolidariosData.fromJson(Map<String, dynamic> json) {
    return ProyectosSolidariosData(
      lema: json['lema'] as String,
      proyectoDestacado: ProyectoModel.fromJson(
        json['proyecto_destacado'] as Map<String, dynamic>,
      ),
      otrasCampanas: (json['otras_campanas'] as List<dynamic>)
          .map(
            (c) => CampanaSecundariaModel.fromJson(c as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class ProyectoModel {
  final String id;
  final String titulo;
  final String subtitulo;
  final String imagenAsset;
  final int montoRecaudado;
  final int metaMonto;
  final int diasRestantes;
  final bool esDestacado;

  ProyectoModel({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.imagenAsset,
    required this.montoRecaudado,
    required this.metaMonto,
    required this.diasRestantes,
    required this.esDestacado,
  });

  double get porcentajeProgreso =>
      metaMonto > 0 ? (montoRecaudado / metaMonto).clamp(0.0, 1.0) : 0.0;
  int get porcentajeEntero => (porcentajeProgreso * 100).round();

  factory ProyectoModel.fromJson(Map<String, dynamic> json) {
    return ProyectoModel(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      subtitulo: json['subtitulo'] as String,
      imagenAsset: json['imagen_asset'] as String,
      montoRecaudado: json['monto_recaudado'] as int,
      metaMonto: json['meta_monto'] as int,
      diasRestantes: json['dias_restantes'] as int,
      esDestacado: json['es_destacado'] as bool? ?? false,
    );
  }
}

class CampanaSecundariaModel {
  final String id;
  final String titulo;
  final String categoria;
  final String iconoNombre;
  final String colorFondoHex;
  final String colorBarraHex;
  final double progreso;
  final int montoRecaudado;
  final int metaMonto;

  CampanaSecundariaModel({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.iconoNombre,
    required this.colorFondoHex,
    required this.colorBarraHex,
    required this.progreso,
    required this.montoRecaudado,
    required this.metaMonto,
  });

  int get porcentajeEntero => (progreso * 100).round();

  factory CampanaSecundariaModel.fromJson(Map<String, dynamic> json) {
    return CampanaSecundariaModel(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      categoria: json['categoria'] as String,
      iconoNombre: json['icono_nombre'] as String,
      colorFondoHex: json['color_fondo_hex'] as String,
      colorBarraHex: json['color_barra_hex'] as String,
      progreso: (json['progreso'] as num).toDouble(),
      montoRecaudado: json['monto_recaudado'] as int,
      metaMonto: json['meta_monto'] as int,
    );
  }
}
