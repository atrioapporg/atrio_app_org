import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DispositivoHelper {
  static Map<String, dynamic> obtenerMetadatos([BuildContext? context]) {
    Size? size;
    Orientation? orientation;

    if (context != null && context.mounted) {
      try {
        size = MediaQuery.sizeOf(context);
        orientation = MediaQuery.orientationOf(context);
      } catch (_) {}
    }

    return {
      'Plataforma': kIsWeb ? 'Web' : Platform.operatingSystem,
      'Versión SO': kIsWeb ? 'N/A' : Platform.operatingSystemVersion,
      'Resolución Pantalla': size != null
          ? '${size.width.toInt()} x ${size.height.toInt()} px'
          : 'No disponible',
      'Orientación': orientation?.name ?? 'No disponible',
      'Fecha y Hora': DateTime.now().toIso8601String(),
    };
  }
}
