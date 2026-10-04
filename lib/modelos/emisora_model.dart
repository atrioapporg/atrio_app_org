class EmisoraModel {
  final String id;
  final String nombre;
  final String dial; // Ej: "92.9 FM" o "Online"
  final String region; // "Nacional", "Santo Domingo", "Cibao", "Este", "Sur"
  final String
  denominacion; // "Evangélica", "Católica", "Adventista", "Interdenominacional"
  final String streamUrl;
  final String streamUrlFallback;
  final String logoUrl;
  final List<String> generos; // ["Música", "Predicación", "Juvenil"]

  EmisoraModel({
    required this.id,
    required this.nombre,
    required this.dial,
    required this.region,
    required this.denominacion,
    required this.streamUrl,
    this.streamUrlFallback = '',
    required this.logoUrl,
    required this.generos,
  });

  factory EmisoraModel.fromJson(Map<String, dynamic> json) => EmisoraModel(
    id: json['id'] ?? '',
    nombre: json['nombre'] ?? '',
    dial: json['dial'] ?? '',
    region: json['region'] ?? 'Nacional',
    denominacion: json['denominacion'] ?? 'Interdenominacional',
    streamUrl: json['stream_url'] ?? '',
    streamUrlFallback: json['stream_url_fallback'] ?? '',
    logoUrl: json['logo_url'] ?? '',
    generos: List<String>.from(json['generos'] ?? []),
  );
}
