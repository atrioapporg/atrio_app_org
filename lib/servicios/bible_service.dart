import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BibleService {
  static const String _baseUrl = 'https://bolls.life';

  Future<Map<String, dynamic>> versiculoDelDia(String version) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/get-random-verse/$version/'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al obtener versículo del día');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerCapitulo(
    String version,
    String libro,
    int capitulo,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/get-text/$version/$libro/$capitulo/'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener capítulo');
    }
  }

  /// Limpia etiquetas HTML, números de concordancia de Strong (<S>...</S>)
  /// y notas al pie (<sup>...</sup>) para visualización clara y profesional.
  static String limpiarTextoVerso(String? texto) {
    if (texto == null || texto.isEmpty) return '';
    return texto
        .replaceAll(RegExp(r'<S>[^<]*</S>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<sup[^>]*>.*?</sup>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((l) => l.isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Diccionario bíblico de alta frecuencia Español -> Inglés
  static const Map<String, String> _diccionarioBiblicoEsEn = {
    'necio': 'fool',
    'necios': 'fools',
    'necedad': 'folly',
    'sabio': 'wise',
    'sabios': 'wise',
    'sabiduría': 'wisdom',
    'sabiduria': 'wisdom',
    'amor': 'love',
    'amar': 'love',
    'fe': 'faith',
    'esperanza': 'hope',
    'gracia': 'grace',
    'paz': 'peace',
    'verdad': 'truth',
    'camino': 'way',
    'vida': 'life',
    'muerte': 'death',
    'luz': 'light',
    'tinieblas': 'darkness',
    'oscuridad': 'darkness',
    'salvación': 'salvation',
    'salvacion': 'salvation',
    'salvo': 'saved',
    'pecado': 'sin',
    'pecados': 'sins',
    'pecador': 'sinner',
    'pecadores': 'sinners',
    'perdón': 'forgiveness',
    'perdon': 'forgiveness',
    'perdonar': 'forgive',
    'oración': 'prayer',
    'oracion': 'prayer',
    'orar': 'pray',
    'alabanza': 'praise',
    'alabar': 'praise',
    'adoración': 'worship',
    'adoracion': 'worship',
    'espíritu': 'spirit',
    'espiritu': 'spirit',
    'espíritu santo': 'holy spirit',
    'cielo': 'heaven',
    'cielos': 'heavens',
    'tierra': 'earth',
    'bendición': 'blessing',
    'bendicion': 'blessing',
    'bendecir': 'bless',
    'misericordia': 'mercy',
    'misericordias': 'mercies',
    'justicia': 'righteousness',
    'justo': 'righteous',
    'justos': 'righteous',
    'temor': 'fear',
    'miedo': 'fear',
    'palabra': 'word',
    'evangelio': 'gospel',
    'cruz': 'cross',
    'resurrección': 'resurrection',
    'resurreccion': 'resurrection',
    'rey': 'king',
    'reino': 'kingdom',
    'señor': 'lord',
    'senor': 'lord',
    'dios': 'god',
    'padre': 'father',
    'hijo': 'son',
    'creación': 'creation',
    'creacion': 'creation',
    'ángel': 'angel',
    'angel': 'angel',
    'ángeles': 'angels',
    'angeles': 'angels',
    'discípulo': 'disciple',
    'discipulo': 'disciple',
    'discípulos': 'disciples',
    'discipulos': 'disciples',
    'apóstol': 'apostle',
    'apostol': 'apostle',
    'profeta': 'prophet',
    'profetas': 'prophets',
    'mandamiento': 'commandment',
    'mandamientos': 'commandments',
    'ley': 'law',
    'pacto': 'covenant',
    'sangre': 'blood',
    'corazón': 'heart',
    'corazon': 'heart',
    'alma': 'soul',
    'fuerza': 'strength',
    'poder': 'power',
    'gloria': 'glory',
    'santo': 'holy',
    'santidad': 'holiness',
    'santos': 'saints',
    'gozo': 'joy',
    'alegría': 'joy',
    'alegria': 'joy',
    'paciencia': 'patience',
    'bondad': 'goodness',
    'benignidad': 'kindness',
    'mansedumbre': 'meekness',
    'templanza': 'temperance',
    'obediencia': 'obedience',
    'humildad': 'humility',
    'orgullo': 'pride',
    'pastor': 'shepherd',
    'oveja': 'sheep',
    'ovejas': 'sheep',
    'iglesia': 'church',
    'templo': 'temple',
    'sacerdote': 'priest',
    'sacrificio': 'sacrifice',
    'pan': 'bread',
    'vino': 'wine',
    'agua': 'water',
    'fuego': 'fire',
    'monte': 'mountain',
    'desierto': 'wilderness',
    'mar': 'sea',
    'enemigo': 'enemy',
    'enemigos': 'enemies',
    'diablo': 'devil',
    'satanás': 'satan',
    'satanas': 'satan',
    'victoria': 'victory',
  };

  // Diccionario bíblico inverso Inglés -> Español
  static final Map<String, String> _diccionarioBiblicoEnEs = {
    for (final entry in _diccionarioBiblicoEsEn.entries)
      entry.value.toLowerCase(): entry.key,
    // Prioridad para términos bíblicos canónicos
    'fool': 'necio',
    'fools': 'necios',
    'folly': 'necedad',
    'wise': 'sabio',
    'wisdom': 'sabiduría',
    'love': 'amor',
    'faith': 'fe',
    'hope': 'esperanza',
    'grace': 'gracia',
    'peace': 'paz',
    'salvation': 'salvación',
    'sin': 'pecado',
    'sins': 'pecados',
    'forgiveness': 'perdón',
    'prayer': 'oración',
    'spirit': 'espíritu',
    'holy spirit': 'espíritu santo',
    'righteousness': 'justicia',
    'righteous': 'justo',
  };

  /// Traduce la consulta de búsqueda entre español e inglés si el idioma objetivo lo amerita.
  static Future<String> traducirConsulta({
    required String query,
    required String idiomaDestino, // 'es' o 'en'
  }) async {
    final clean = query.trim();
    if (clean.isEmpty) return clean;

    final lower = clean.toLowerCase();

    // 1. Coincidencia inmediata en diccionario local integrado (0ms de latencia, 100% offline)
    if (idiomaDestino == 'en') {
      if (_diccionarioBiblicoEsEn.containsKey(lower)) {
        return _diccionarioBiblicoEsEn[lower]!;
      }
    } else {
      if (_diccionarioBiblicoEnEs.containsKey(lower)) {
        return _diccionarioBiblicoEnEs[lower]!;
      }
    }

    // 2. Fallback de traducción online (MyMemory API gratuita sin API key)
    try {
      final pair = (idiomaDestino == 'en') ? 'es|en' : 'en|es';
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(clean)}&langpair=$pair',
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = data['responseData']?['translatedText'] as String?;
        if (translated != null &&
            translated.trim().isNotEmpty &&
            !translated.toLowerCase().contains('my memory') &&
            !translated.toLowerCase().contains('quota exceeded')) {
          final cleanTranslated = translated
              .trim()
              .replaceAll(RegExp(r'[\.!]+$'), '')
              .trim();
          if (cleanTranslated.isNotEmpty) {
            return cleanTranslated;
          }
        }
      }
    } catch (_) {
      // Ignorar fallo de red y conservar el término original
    }

    return clean;
  }

  Future<List<Map<String, dynamic>>> buscar(
    String version,
    String query, {
    int pagina = 1,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final uri = Uri.parse(
      '$_baseUrl/v2/find/$version?search=${Uri.encodeComponent(cleanQuery)}&limit=30&page=$pagina',
    );

    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List rawList = [];
        if (data is Map<String, dynamic>) {
          rawList = data['results'] as List? ?? [];
        } else if (data is List) {
          rawList = data;
        }

        return rawList.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          if (map.containsKey('text')) {
            map['text'] = limpiarTextoVerso(map['text'] as String?);
          }
          return map;
        }).toList();
      } else {
        throw Exception(
          'Error en respuesta del servidor: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[BIBLE_SERVICE] Error al buscar "$cleanQuery": $e');
      rethrow;
    }
  }

  //
  /// Obtiene la información y resumen descriptivo del libro bíblico dinámicamente
  Future<Map<String, String>> obtenerInfoLibro(String nombreLibro) async {
    final String query = Uri.encodeComponent('$nombreLibro (Biblia)');
    final Uri uri = Uri.parse(
      'https://es.wikipedia.org/api/rest_v1/page/summary/$query',
    );

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ); //[cite: 9]

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body) as Map<String, dynamic>; //[cite: 4, 9]
        return {
          'titulo': data['title'] ?? nombreLibro,
          'descripcion':
              data['extract'] ??
              'No hay descripción disponible para este libro.',
        };
      } else {
        // Respaldo sin desambiguación si falla la primera
        final fallbackUri = Uri.parse(
          'https://es.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(nombreLibro)}',
        );
        final fallbackResp = await http.get(
          fallbackUri,
          headers: {'Accept': 'application/json'},
        ); //[cite: 9]
        if (fallbackResp.statusCode == 200) {
          final data = jsonDecode(
            fallbackResp.body,
          ) as Map<String, dynamic>; //[cite: 4, 9]
          return {
            'titulo': data['title'] ?? nombreLibro,
            'descripcion':
                data['extract'] ??
                'No hay descripción disponible para este libro.',
          };
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo info de libro: $e');
    }

    return {
      'titulo': nombreLibro,
      'descripcion':
          'No se pudo cargar la información del libro en este momento.',
    };
  }
  //
}
