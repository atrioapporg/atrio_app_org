import 'dart:convert';

import 'package:atrio/data/atrio_database_helper.dart';
import 'package:atrio/modelos/versiculo_dia.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VersiculoService {
  static const String _havenUrlEs =
      'https://www.try-haven.app/es-MX/daily-verse';
  static const String _havenUrlEn = 'https://www.try-haven.app/en/daily-verse';

  Future<VersiculoDia> obtenerVersiculoDelDia({String? idioma}) async {
    String lang = idioma?.trim() ?? '';
    if (lang.isEmpty) {
      try {
        final ajustes = await AtrioDatabaseHelper.instance.getAjustes();
        lang = ajustes.idiomaCodigo;
      } catch (_) {
        lang = 'es';
      }
    }

    final bool esIngles = lang.toLowerCase().startsWith('en');
    final String url = esIngles ? _havenUrlEn : _havenUrlEs;
    final String langKey = esIngles ? 'en' : 'es';

    final String keyVersiculoCache = 'cache_versiculo_haven_${langKey}_v1';
    final String keyTimestamp = 'cache_timestamp_haven_${langKey}_v1';

    final prefs = await SharedPreferences.getInstance();
    final int? lastFetch = prefs.getInt(keyTimestamp);
    final String? cachedJson = prefs.getString(keyVersiculoCache);

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // Si se descargó hoy en el mismo idioma y tenemos caché, usarlo
    if (lastFetch != null && cachedJson != null) {
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastFetch);
      final bool esMismoDia = lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day;

      if (esMismoDia) {
        try {
          final data = jsonDecode(cachedJson) as Map<String, dynamic>;
          return VersiculoDia.fromJson(data);
        } catch (_) {}
      }
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept-Language': esIngles ? 'en-US,en;q=0.9' : 'es-MX,es;q=0.9',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final versiculo = _extraerDeRespuesta(response.body);
        if (versiculo != null &&
            versiculo.texto.isNotEmpty &&
            versiculo.referencia.isNotEmpty) {
          await prefs.setString(
            keyVersiculoCache,
            jsonEncode(versiculo.toJson()),
          );
          await prefs.setInt(keyTimestamp, nowMs);
          return versiculo;
        }
      }
      throw Exception(
        'Respuesta HTTP ${response.statusCode} o formato no reconocido',
      );
    } catch (e) {
      debugPrint(
        '[VERSICULO_SERVICE] Error obteniendo versículo de Haven ($langKey): $e',
      );

      if (cachedJson != null) {
        try {
          return VersiculoDia.fromJson(
            jsonDecode(cachedJson) as Map<String, dynamic>,
          );
        } catch (_) {}
      }

      if (esIngles) {
        return VersiculoDia(
          texto: 'I can do all things through Christ who strengthens me.',
          referencia: 'Philippians 4:13',
          traduccion: 'World English Bible',
        );
      } else {
        return VersiculoDia(
          texto: 'Todo lo puedo en Cristo que me fortalece.',
          referencia: 'Filipenses 4:13',
          traduccion: 'Reina-Valera',
        );
      }
    }
  }

  VersiculoDia? _extraerDeRespuesta(String body) {
    try {
      // Método 1: Extraer del payload estructurado de componentes Next.js
      // Formato: \"text\":\"...\",\"reference\":\"...\",\"theme\":\"...\",\"translation\":\"...\"
      final matchVerse = RegExp(
        r'\\"text\\":\s*\\"(.*?)\\",\s*\\"reference\\":\s*\\"(.*?)\\"(?:,\s*\\"theme\\":\s*\\"(.*?)\\")?(?:,\s*\\"translation\\":\s*\\"(.*?)\\")?',
      ).firstMatch(body);

      // Reflexión devocional
      final matchReflex =
          RegExp(r'\\"reflection\\":\s*\\"(.*?)\\"').firstMatch(body);

      if (matchVerse != null) {
        final texto = _limpiarTextoEscapado(matchVerse.group(1) ?? '');
        final referencia = _limpiarTextoEscapado(matchVerse.group(2) ?? '');
        final traduccion = matchVerse.group(4) != null
            ? _limpiarTextoEscapado(matchVerse.group(4)!)
            : null;
        final reflexion = matchReflex != null
            ? _limpiarTextoEscapado(matchReflex.group(1) ?? '')
            : null;

        if (texto.isNotEmpty && referencia.isNotEmpty) {
          return VersiculoDia(
            texto: texto,
            referencia: referencia,
            traduccion: traduccion,
            reflexion: reflexion,
          );
        }
      }

      // Método 2 (Fallback): Extraer directamente de las etiquetas HTML
      final matchBlockquote = RegExp(
        r'<blockquote[^>]*>“?(?:<!-- -->)?(.*?)(?:<!-- -->)?”?</blockquote>',
        dotAll: true,
      ).firstMatch(body);
      final matchPRef = RegExp(
        r'<p[^>]*class="[^"]*text-lg mb-2"[^>]*>(.*?)</p>',
        dotAll: true,
      ).firstMatch(body);

      if (matchBlockquote != null && matchPRef != null) {
        final texto = _limpiarHtml(matchBlockquote.group(1) ?? '');
        final referencia = _limpiarHtml(matchPRef.group(1) ?? '');
        if (texto.isNotEmpty && referencia.isNotEmpty) {
          return VersiculoDia(
            texto: texto,
            referencia: referencia,
          );
        }
      }
    } catch (e) {
      debugPrint('[VERSICULO_SERVICE] Error parseando HTML/JSON de Haven: $e');
    }
    return null;
  }

  String _limpiarTextoEscapado(String str) {
    try {
      return jsonDecode('"$str"') as String;
    } catch (_) {
      return str
          .replaceAll(r'\"', '"')
          .replaceAll(r'\\', r'\')
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\t', '\t')
          .trim();
    }
  }

  String _limpiarHtml(String html) {
    return html
        .replaceAll(RegExp(r'<!--.*?-->'), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('“', '')
        .replaceAll('”', '')
        .trim();
  }
}
