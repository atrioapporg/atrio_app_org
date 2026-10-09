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
        if (data is Map<String, dynamic>) {
          return List<Map<String, dynamic>>.from(data['results'] ?? []);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Error en respuesta del servidor: ${response.statusCode}');
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
