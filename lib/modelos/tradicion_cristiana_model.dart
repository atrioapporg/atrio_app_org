class TradicionesResponseModel {
  final List<TradicionCristianaModel> tradiciones;

  TradicionesResponseModel({required this.tradiciones});

  factory TradicionesResponseModel.fromJson(Map<String, dynamic> json) {
    return TradicionesResponseModel(
      tradiciones: (json['tradiciones'] as List<dynamic>)
          .map(
            (t) => TradicionCristianaModel.fromJson(t as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class TradicionCristianaModel {
  final String id;
  final String titulo;
  final String iconoNombre;
  final String colorHex;
  final List<IglesiaAfiliadaModel> iglesias;

  TradicionCristianaModel({
    required this.id,
    required this.titulo,
    required this.iconoNombre,
    required this.colorHex,
    required this.iglesias,
  });

  factory TradicionCristianaModel.fromJson(Map<String, dynamic> json) {
    return TradicionCristianaModel(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      iconoNombre: json['icono_nombre'] as String,
      colorHex: json['color_hex'] as String,
      iglesias: (json['iglesias'] as List<dynamic>)
          .map((i) => IglesiaAfiliadaModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'icono_nombre': iconoNombre,
    'color_hex': colorHex,
    'iglesias': iglesias.map((i) => i.toJson()).toList(),
  };
}

class IglesiaAfiliadaModel {
  final String id;
  final String nombre;
  final String denominacion;
  final String direccion;
  final String plusCode;
  final String telefono;
  final double calificacion;
  final int totalResenas;
  final bool esVerificada;

  IglesiaAfiliadaModel({
    required this.id,
    required this.nombre,
    required this.denominacion,
    required this.direccion,
    required this.plusCode,
    required this.telefono,
    required this.calificacion,
    required this.totalResenas,
    required this.esVerificada,
  });

  factory IglesiaAfiliadaModel.fromJson(Map<String, dynamic> json) {
    return IglesiaAfiliadaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      denominacion: json['denominacion'] as String,
      direccion: json['direccion'] as String,
      plusCode: json['plus_code'] as String,
      telefono: json['telefono'] as String,
      calificacion: (json['calificacion'] as num).toDouble(),
      totalResenas: json['total_resenas'] as int,
      esVerificada: json['es_verificada'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'denominacion': denominacion,
    'direccion': direccion,
    'plus_code': plusCode,
    'telefono': telefono,
    'calificacion': calificacion,
    'total_resenas': totalResenas,
    'es_verificada': esVerificada,
  };
}
