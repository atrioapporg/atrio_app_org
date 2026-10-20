class VersiculoDia {
  final String texto;
  final String referencia;
  final String? traduccion;
  final String? reflexion;

  VersiculoDia({
    required this.texto,
    required this.referencia,
    this.traduccion,
    this.reflexion,
  });

  factory VersiculoDia.fromJson(Map<String, dynamic> json) {
    return VersiculoDia(
      texto: json['texto'] ?? '',
      referencia: json['referencia'] ?? '',
      traduccion: json['traduccion'],
      reflexion: json['reflexion'],
    );
  }

  Map<String, dynamic> toJson() => {
        'texto': texto,
        'referencia': referencia,
        if (traduccion != null) 'traduccion': traduccion,
        if (reflexion != null) 'reflexion': reflexion,
      };
}
