// lib/models/capitulo_audio.dart

class CapituloAudio {
  final int? id;
  final String testamento; // 'AT' o 'NT'
  final String libro; // ej. 'Mateo', 'Marcos'
  final int capitulo; // ej. 1, 2, 3
  final int startSeconds;
  final int endSeconds;
  final String videoId; // ID del video de YouTube

  CapituloAudio({
    this.id,
    required this.testamento,
    required this.libro,
    required this.capitulo,
    required this.startSeconds,
    required this.endSeconds,
    required this.videoId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testamento': testamento,
      'libro': libro,
      'capitulo': capitulo,
      'start_seconds': startSeconds,
      'end_seconds': endSeconds,
      'video_id': videoId,
    };
  }

  factory CapituloAudio.fromMap(Map<String, dynamic> map) {
    return CapituloAudio(
      id: map['id'],
      testamento: map['testamento'],
      libro: map['libro'],
      capitulo: map['capitulo'],
      startSeconds: map['start_seconds'],
      endSeconds: map['end_seconds'],
      videoId: map['video_id'],
    );
  }
}
