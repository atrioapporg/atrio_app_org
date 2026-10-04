import 'dart:convert';

import 'package:atrio/modelos/versiculo_dia.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VersiculoService {
  static const String _sheetId = '1124H0Z6-8ikfxrG6Yg4Wlx7svigQlWBcWTKPlYN-rZ0';
  static const String _sheetName = 'versiculos_originales';

  static final Uri _csvUri = Uri.parse(
    'https://docs.google.com/spreadsheets/d/$_sheetId/gviz/tq?tqx=out:csv&sheet=$_sheetName',
  );

  // NUEVAS CLAVES DE CACHÉ: Fuerzan a la app a borrar el error anterior y descargar de nuevo
  static const String _keyVersiculoCache = 'cache_versiculo_v3';
  static const String _keyTimestamp = 'cache_timestamp_v3';

  Future<VersiculoDia> obtenerVersiculoDelDia() async {
    final prefs = await SharedPreferences.getInstance();
    final int? lastFetch = prefs.getInt(_keyTimestamp);
    final String? cachedJson = prefs.getString(_keyVersiculoCache);

    final now = DateTime.now().millisecondsSinceEpoch;
    const duracion12Horas = 12 * 60 * 60 * 1000;

    if (lastFetch != null && cachedJson != null) {
      final diferencia = now - lastFetch;
      if (diferencia < duracion12Horas) {
        final data = jsonDecode(cachedJson) as Map<String, dynamic>;
        return VersiculoDia.fromJson(data);
      }
    }

    try {
      final response = await http.get(_csvUri);

      if (response.statusCode == 200) {
        final versiculos = _parsearCsv(response.body);

        if (versiculos.isNotEmpty) {
          final hoy = DateTime.now();
          final diaDelAno = hoy.difference(DateTime(hoy.year, 1, 1)).inDays;
          final seleccionado = versiculos[diaDelAno % versiculos.length];

          await prefs.setString(
            _keyVersiculoCache,
            jsonEncode(seleccionado.toJson()),
          );
          await prefs.setInt(_keyTimestamp, now);

          return seleccionado;
        }
      }
      throw Exception('Respuesta HTTP no válida o CSV vacío');
    } catch (e) {
      debugPrint('[VERSICULO_SERVICE] Error descargando hoja: $e');

      if (cachedJson != null) {
        return VersiculoDia.fromJson(
          jsonDecode(cachedJson) as Map<String, dynamic>,
        );
      }

      return VersiculoDia(
        texto: 'Todo lo puedo en Cristo que me fortalece.',
        referencia: 'Filipenses 4:13',
      );
    }
  }

  List<VersiculoDia> _parsearCsv(String csvData) {
    final List<VersiculoDia> lista = [];
    final lineas = const LineSplitter().convert(csvData);

    if (lineas.length <= 1) return lista;

    for (int i = 1; i < lineas.length; i++) {
      final linea = lineas[i].trim();
      if (linea.isEmpty) continue;

      final columnas = _separarColumnasCsv(linea);

      // Columna 0: id | Columna 1: topic | Columna 2: reference | Columna 3: text
      if (columnas.length >= 4) {
        final referencia = columnas[2];
        final texto = columnas[3];

        if (texto.isNotEmpty && referencia.isNotEmpty) {
          lista.add(VersiculoDia(texto: texto, referencia: referencia));
        }
      }
    }
    return lista;
  }

  // Nuevo procesador de filas: ignora las comillas dobles y extrae el texto puro
  List<String> _separarColumnasCsv(String row) {
    final List<String> result = [];
    final StringBuffer buffer = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < row.length; i++) {
      final char = row[i];

      if (char == '"') {
        insideQuotes = !insideQuotes;
        continue;
      } else if (char == ',' && !insideQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    result.add(buffer.toString().trim());
    return result;
  }
}
