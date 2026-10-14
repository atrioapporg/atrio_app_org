import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Servicio para la gestión dinámica del tema del mapa de Google (Modo Día / Modo Noche automático)
class MapStyleService {
  MapStyleService._();

  static String? _cachedDarkStyle;

  /// Determina si actualmente debe aplicarse el modo noche
  /// (si la hora local es entre las 7:00 PM y las 6:00 AM, o si el tema del sistema es oscuro)
  static bool esDeNoche(BuildContext context) {
    final hora = DateTime.now().hour;
    final esNochePorHora = hora >= 19 || hora < 6;
    final esModoOscuroSistema =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return esNochePorHora || esModoOscuroSistema;
  }

  /// Carga el JSON de estilo oscuro desde assets con caché en memoria
  static Future<String> getDarkStyle() async {
    if (_cachedDarkStyle != null && _cachedDarkStyle!.isNotEmpty) {
      return _cachedDarkStyle!;
    }
    try {
      _cachedDarkStyle =
          await rootBundle.loadString('assets/json/map_dark_style.json');
      return _cachedDarkStyle!;
    } catch (e) {
      debugPrint('Error al cargar assets/json/map_dark_style.json: $e');
      return '';
    }
  }
}
