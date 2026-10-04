// lib/data/tiempos_audio_biblia.dart

class TiemposAudioBiblia {
  // 1. IDs de los videos en YouTube para cada libro
  static const Map<String, String> videoIds = {
    'Mateo': 'wPrGd73mj-s',
    'Marcos': 'htgJyS9k1aY', // Reemplazar por el ID real
    'Lucas': 'JwWicqONOvM',
    'Juan': 'CqKq67x7zLA',
    'Hechos': 'gHb0D-rK4dw',
  };

  // 2. Duración total del video en segundos (Fallback vital para el último capítulo)
  static const Map<String, int> duracionTotalSegundos = {
    'Mateo': 11092,
    'Marcos': 7265, // Añadir duración de Marcos en segundos
    'Lucas': 12307,
    'Juan': 8758,
    'Hechos': 11612,
  };

  // 3. Mapa central (Inyecta las colecciones privadas de forma limpia)
  static const Map<String, Map<int, int>> tiempos = {
    'Mateo': _tiemposMateo,
    'Marcos': _tiemposMarcos,
    'Lucas': _tiemposLucas,
    'Juan': _tiemposJuan,
    'Hechos': _tiemposHechos,
  };
  //
  // MÉTODO PRINCIPAL
  // =========================================================================
  static List<int> obtenerRangoCapitulo(String libro, int capitulo) {
    final mapaCapitulos = tiempos[libro];
    if (mapaCapitulos == null || !mapaCapitulos.containsKey(capitulo)) {
      return [0, 0];
    }

    final int inicio = mapaCapitulos[capitulo]!;

    // Calcula el fin basándose en el siguiente capítulo o en la duración final
    final int fin =
        mapaCapitulos[capitulo + 1] ??
        duracionTotalSegundos[libro] ??
        (inicio + 300); // 5 minutos extra de seguridad

    return [inicio, fin];
  }
  //

  // =========================================================================
  // DESGLOSE DE TIEMPOS POR LIBRO (SEGUNDOS EXACTOS)
  // =========================================================================

  static const Map<int, int> _tiemposMateo = {
    1: 0,
    2: 251,
    3: 519,
    4: 725,
    5: 1020,
    6: 1586,
    7: 2022,
    8: 2349,
    9: 2731,
    10: 3143,
    11: 3571,
    12: 3951,
    13: 4488,
    14: 5100,
    15: 5415,
    16: 5792,
    17: 6112,
    18: 6429,
    19: 6763,
    20: 7047,
    21: 7369,
    22: 7870,
    23: 8275,
    24: 8696,
    25: 9156,
    26: 9586,
    27: 10366,
    28: 10889,
  };

  static const Map<int, int> _tiemposMarcos = {
    1: 0,
    2: 474,
    3: 807,
    4: 1167,
    5: 1594,
    6: 2075,
    7: 2646,
    8: 3027,
    9: 3441,
    10: 3959,
    11: 4513,
    12: 4858,
    13: 5385,
    14: 5771,
    15: 6564,
    16: 7039,
  };

  static const Map<int, int> _tiemposLucas = {
    1: 0,
    2: 685,
    3: 1135,
    4: 1594,
    5: 2085,
    6: 2506,
    7: 3116,
    8: 3691,
    9: 4354,
    10: 5001,
    11: 5491,
    12: 6204,
    13: 6852,
    14: 7273,
    15: 7643,
    16: 7996,
    17: 8372,
    18: 8735,
    19: 9182,
    20: 9649,
    21: 10150,
    22: 10534,
    23: 11224,
    24: 11809,
  };

  static const Map<int, int> _tiemposJuan = {
    1: 0,
    2: 475,
    3: 716,
    4: 1076,
    5: 1597,
    6: 2082,
    7: 2726,
    8: 3201,
    9: 3811,
    10: 4167,
    11: 4579,
    12: 5083,
    13: 5598,
    14: 5980,
    15: 6330,
    16: 6593,
    17: 6929,
    18: 7233,
    19: 7640,
    20: 8124,
    21: 8447,
  };

  static const Map<int, int> _tiemposHechos = {
    1: 0,
    2: 318,
    3: 868,
    4: 1193,
    5: 1599,
    6: 2075,
    7: 2257,
    8: 2870,
    9: 3243,
    10: 3694,
    11: 4185,
    12: 4530,
    13: 4819,
    14: 5552,
    15: 5870,
    16: 6318,
    17: 6771,
    18: 7201,
    19: 7514,
    20: 7992,
    21: 8439,
    22: 8928,
    23: 9337,
    24: 9722,
    25: 10029,
    26: 10340,
    27: 10740,
    28: 11240,
  };
  //

  // =========================================================================
}
