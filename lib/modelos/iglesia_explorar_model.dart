import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modelo de datos para las iglesias en la pantalla Explorar
class IglesiaExplorarModel {
  final String id;
  final String nombre;
  final String denominacion;
  final String direccion;
  final double distanciaKm;
  final double rating;
  final int totalResenas;
  final String colorHex;
  final LatLng? latLng;

  IglesiaExplorarModel({
    required this.id,
    required this.nombre,
    required this.denominacion,
    this.direccion = '',
    required this.distanciaKm,
    required this.rating,
    required this.totalResenas,
    required this.colorHex,
    this.latLng,
  });

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF072B4F);
    }
  }

  factory IglesiaExplorarModel.fromJson(Map<String, dynamic> json) {
    return IglesiaExplorarModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Sin nombre',
      denominacion: json['denominacion'] as String? ?? 'Comunidad cristiana',
      direccion: json['direccion'] as String? ?? '',
      distanciaKm: (json['distancia_km'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalResenas: json['total_resenas'] as int? ?? 0,
      colorHex: json['color_hex'] as String? ?? '#072B4F',
      latLng: json['lat'] != null && json['lng'] != null
          ? LatLng(
              (json['lat'] as num).toDouble(),
              (json['lng'] as num).toDouble(),
            )
          : null,
    );
  }

  factory IglesiaExplorarModel.fromPlacesApi(
    Map<String, dynamic> place,
    Position? userPos,
    Color brandColor,
  ) {
    final location = place['location'];
    LatLng? latLng;
    double distKm = 0.0;

    if (location != null) {
      final double pLat = (location['latitude'] as num).toDouble();
      final double pLng = (location['longitude'] as num).toDouble();
      latLng = LatLng(pLat, pLng);

      if (userPos != null) {
        final meters = Geolocator.distanceBetween(
          userPos.latitude,
          userPos.longitude,
          pLat,
          pLng,
        );
        distKm = meters / 1000.0;
      }
    }

    final formattedAddress = place['formattedAddress'] as String? ?? '';
    final nombreLugar = place['displayName']?['text'] as String? ?? 'Sin nombre';
    final nombreLower = nombreLugar.toLowerCase();
    final addressLower = formattedAddress.toLowerCase();
    final textoCompleto = '$nombreLower $addressLower';

    final textoNormalizado = textoCompleto
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');

    String denom;
    final esTerminoCatolico = textoNormalizado.contains('parroquia') ||
        textoNormalizado.contains('catedral') ||
        textoNormalizado.contains('basilica') ||
        textoNormalizado.contains('santuario') ||
        textoNormalizado.contains('capilla') ||
        textoNormalizado.contains('catolica') ||
        textoNormalizado.contains('arquidiocesis') ||
        textoNormalizado.contains('diocesis') ||
        textoNormalizado.contains('nuestra senora') ||
        textoNormalizado.contains('virgen') ||
        textoNormalizado.contains('sagrado corazon') ||
        textoNormalizado.contains('santisimo sacramento');

    final esNoCatolicaExplicita = textoNormalizado.contains('adventista') ||
        textoNormalizado.contains('bautista') ||
        textoNormalizado.contains('pentecostal') ||
        textoNormalizado.contains('evangelica');

    if (esTerminoCatolico && !esNoCatolicaExplicita) {
      denom = 'Católica';
    } else if (textoNormalizado.contains('adventista')) {
      denom = 'Adventista';
    } else if (textoNormalizado.contains('bautista')) {
      denom = 'Bautista';
    } else if (textoNormalizado.contains('pentecostal')) {
      denom = 'Pentecostal';
    } else if (textoNormalizado.contains('evangelica')) {
      denom = 'Evangélica';
    } else if (formattedAddress.isNotEmpty) {
      denom = formattedAddress.split(',').first;
    } else {
      denom = 'Comunidad cristiana';
    }

    final hex =
        '#${brandColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    return IglesiaExplorarModel(
      id: place['id'] as String? ?? '',
      nombre: place['displayName']?['text'] as String? ?? 'Sin nombre',
      denominacion: denom,
      direccion: formattedAddress,
      distanciaKm: distKm,
      rating: (place['rating'] as num?)?.toDouble() ?? 0.0,
      totalResenas: place['userRatingCount'] as int? ?? 0,
      colorHex: hex,
      latLng: latLng,
    );
  }
}
