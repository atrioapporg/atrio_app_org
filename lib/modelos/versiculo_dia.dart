class VersiculoDia {
  final String texto;
  final String referencia;

  VersiculoDia({required this.texto, required this.referencia});

  factory VersiculoDia.fromJson(Map<String, dynamic> json) {
    return VersiculoDia(
      texto: json['texto'] ?? '',
      referencia: json['referencia'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'texto': texto, 'referencia': referencia};
}
