import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/anuncio_model.dart';

class AnuncioService {
  static const String _keyAnunciosCache = 'cache_anuncios_atrio_v1';
  static const String _keyTimestamp = 'cache_anuncios_timestamp_v1';

  // Endpoint preparado para la integración con backend Odoo 19
  // (módulo de anuncios públicos e interdenominacionales de ATRIO)
  static const String odooEndpoint =
      'https://odoo.atrio.app/api/v1/anuncios/publicos';

  /// Retorna la lista de anuncios interdenominacionales.
  /// Lee desde caché local o backend de Odoo 19, utilizando datos iniciales si no hay conexión.
  Future<List<AnuncioModel>> obtenerAnuncios() async {
    final prefs = await SharedPreferences.getInstance();
    final int? lastFetch = prefs.getInt(_keyTimestamp);
    final String? cachedJson = prefs.getString(_keyAnunciosCache);

    final now = DateTime.now().millisecondsSinceEpoch;
    const duracion6Horas = 6 * 60 * 60 * 1000;

    if (lastFetch != null && cachedJson != null) {
      final diferencia = now - lastFetch;
      if (diferencia < duracion6Horas) {
        try {
          final List<dynamic> listaRaw = jsonDecode(cachedJson);
          return listaRaw
              .map((item) => AnuncioModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('[ANUNCIO_SERVICE] Error decodificando caché: $e');
        }
      }
    }

    try {
      // Simulación de llamada REST/RPC a Odoo 19 con fallback robusto
      final anuncios = _obtenerAnunciosFicticiosIniciales();

      // Guardamos en caché local para disponibilidad offline
      await prefs.setString(
        _keyAnunciosCache,
        jsonEncode(anuncios.map((a) => a.toJson()).toList()),
      );
      await prefs.setInt(_keyTimestamp, now);

      return anuncios;
    } catch (e) {
      debugPrint('[ANUNCIO_SERVICE] Error cargando anuncios: $e');

      if (cachedJson != null) {
        try {
          final List<dynamic> listaRaw = jsonDecode(cachedJson);
          return listaRaw
              .map((item) => AnuncioModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }

      return _obtenerAnunciosFicticiosIniciales();
    }
  }

  /// Catálogo de anuncios interdenominacionales y genéricos de alta relevancia cristiana,
  /// aplicables a cualquier congregación o denominación (Conciertos y Eventos Internacionales).
  List<AnuncioModel> _obtenerAnunciosFicticiosIniciales() {
    return [
      AnuncioModel(
        id: '1',
        titulo: 'Tour "Terrenal": Noche de Esperanza y Fe',
        artista: 'Jesús Adrián Romero – México',
        subtitulo: 'Concierto Acústico Internacional',
        descripcion:
            'Una velada íntima de alabanza, adoración y reflexión con las canciones más emblemáticas de Jesús Adrián Romero. Un encuentro diseñado para unir a toda la familia y comunidad cristiana sin distinción de denominación.',
        imagenUrl:
            'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?q=80&w=800&auto=format&fit=crop',
        fecha: 'Sábado 21 de Noviembre, 2026 · 8:00 p. m.',
        lugar: 'Estadio Olímpico Central',
        categoria: 'Concierto Internacional',
        etiqueta: 'GIRA 2026',
        enlaceAccion: 'https://atrio.app/eventos/jar-tour',
        textoAccion: 'Boletos disponibles',
        esDestacado: true,
        fallbackBgColor: '0xFF072B4F',
        fallbackTextColor: '0xFFE5A023',
      ),
      AnuncioModel(
        id: '2',
        titulo: 'Gira "Viviré": Celebración de Alabanza',
        artista: 'Marcos Witt – EE. UU. / México',
        subtitulo: '35 Años de Ministerio en Vivo',
        descripcion:
            'Acompaña a Marcos Witt y su banda completa en un concierto histórico de adoración congregacional, gozo y unidad del pueblo de Dios en nuestra ciudad. Invitados especiales de toda Latinoamérica.',
        imagenUrl:
            'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=800&auto=format&fit=crop',
        fecha: 'Viernes 04 de Diciembre, 2026 · 7:30 p. m.',
        lugar: 'Gran Arena Metropolitana',
        categoria: 'Concierto Magno',
        etiqueta: 'EXCLUSIVO',
        enlaceAccion: 'https://atrio.app/eventos/marcos-witt',
        textoAccion: 'Reservar lugar',
        esDestacado: false,
        fallbackBgColor: '0xFF1B3B5A',
        fallbackTextColor: '0xFFFAF7F0',
      ),
      AnuncioModel(
        id: '3',
        titulo: 'Noche de Gracia y Adoración: "Al Final"',
        artista: 'Lilly Goodman – República Dominicana',
        subtitulo: 'Voz Inspiradora en Concierto',
        descripcion:
            'Una noche conmovedora de inspiración, esperanza y fe con la prodigiosa voz de Lilly Goodman. Un llamado a renovar la confianza en las promesas divinas para creyentes de todas las iglesias.',
        imagenUrl:
            'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=800&auto=format&fit=crop',
        fecha: 'Sábado 16 de Enero, 2027 · 7:00 p. m.',
        lugar: 'Auditorio Nacional de las Artes',
        categoria: 'Concierto Acústico',
        etiqueta: 'INTERNACIONAL',
        enlaceAccion: 'https://atrio.app/eventos/lilly-goodman',
        textoAccion: 'Más información',
        esDestacado: false,
        fallbackBgColor: '0xFF2E4057',
        fallbackTextColor: '0xFFE5A023',
      ),
      AnuncioModel(
        id: '4',
        titulo: 'Gira "Al Taller del Maestro" 2027',
        artista: 'Alex Campos – Colombia',
        subtitulo: 'Encuentro de Fe y Música en Vivo',
        descripcion:
            'El reconocido cantautor colombiano Alex Campos llega con una puesta en escena vibrante que fusiona rock, pop y alabanza sincera. Un concierto imperdible para jóvenes, adultos y familias cristianas.',
        imagenUrl:
            'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?q=80&w=800&auto=format&fit=crop',
        fecha: 'Viernes 29 de Enero, 2027 · 8:00 p. m.',
        lugar: 'Coliseo Mayor de la Ciudad',
        categoria: 'Concierto Familiar',
        etiqueta: 'GIRA LATINA',
        enlaceAccion: 'https://atrio.app/eventos/alex-campos',
        textoAccion: 'Ver detalles',
        esDestacado: false,
        fallbackBgColor: '0xFF3D5A80',
        fallbackTextColor: '0xFFFFFFFF',
      ),
    ];
  }
}
