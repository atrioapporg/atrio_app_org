class AporteConfigModel {
  final PerfilDonante perfil;
  final ConfiguracionPago configPago;
  final List<String> propositos;

  AporteConfigModel({
    required this.perfil,
    required this.configPago,
    required this.propositos,
  });

  factory AporteConfigModel.fromJson(Map<String, dynamic> json) {
    return AporteConfigModel(
      perfil: PerfilDonante.fromJson(json['perfil_donante']),
      configPago: ConfiguracionPago.fromJson(json['configuracion_pago']),
      propositos: List<String>.from(json['propositos_disponibles']),
    );
  }
}

class PerfilDonante {
  final String nombre;
  final String correo;

  PerfilDonante({required this.nombre, required this.correo});

  factory PerfilDonante.fromJson(Map<String, dynamic> json) {
    return PerfilDonante(nombre: json['nombre'], correo: json['correo']);
  }
}

class ConfiguracionPago {
  final String monedaSimbolo;
  final List<int> montosSugeridos;
  final List<String> frecuencias;
  final MetodoPago metodoDefecto;

  ConfiguracionPago({
    required this.monedaSimbolo,
    required this.montosSugeridos,
    required this.frecuencias,
    required this.metodoDefecto,
  });

  factory ConfiguracionPago.fromJson(Map<String, dynamic> json) {
    return ConfiguracionPago(
      monedaSimbolo: json['moneda_simbolo'],
      montosSugeridos: List<int>.from(json['montos_sugeridos']),
      frecuencias: List<String>.from(json['frecuencias']),
      metodoDefecto: MetodoPago.fromJson(json['metodo_pago_defecto']),
    );
  }
}

//
class MetodoPago {
  final String marca;
  final String ultimosCuatro;

  MetodoPago({required this.marca, required this.ultimosCuatro});

  factory MetodoPago.fromJson(Map<String, dynamic> json) {
    return MetodoPago(
      marca: json['marca'],
      ultimosCuatro: json['ultimos_cuatro'],
    );
  }
}
