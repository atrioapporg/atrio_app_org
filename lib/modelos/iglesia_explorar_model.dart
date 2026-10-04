class IglesiaExplorarModel {
  final String id;
  final String nombre;
  final String denominacion;
  final double distanciaKm;
  final double rating;
  final int totalResenas;
  final String colorHex;

  IglesiaExplorarModel({
    required this.id,
    required this.nombre,
    required this.denominacion,
    required this.distanciaKm,
    required this.rating,
    required this.totalResenas,
    required this.colorHex,
  });

  factory IglesiaExplorarModel.fromJson(Map<String, dynamic> json) {
    return IglesiaExplorarModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      denominacion: json['denominacion'] as String,
      distanciaKm: (json['distancia_km'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      totalResenas: json['total_resenas'] as int,
      colorHex: json['color_hex'] as String,
    );
  }
}
