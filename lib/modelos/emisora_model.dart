import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

/// Modelo inmutable y optimizado para representar una emisora de radio en ATRIO.
/// Incluye un índice de búsqueda pre-computado ([searchBlob]) para filtrado en O(1)
/// sin asignaciones de memoria durante el tipeo del usuario.
class EmisoraModel {
  final String id;
  final String name;
  final String frequency;
  final String city;
  final String region;
  final String paisCodigo;
  final String paisNombre;
  final String streamUrl;
  final String streamUrlFallback;
  final String logo;
  final String idioma;
  final String denomination;
  final String description;
  final int priority;

  /// Getters de compatibilidad con código existente
  String get nombre => name;
  String get dial => frequency;
  String get logoUrl => logo;
  String get denominacion => denomination;

  /// Cadena pre-normalizada en minúsculas y sin tildes para búsqueda instantánea.
  final String searchBlob;

  const EmisoraModel({
    required this.id,
    required this.name,
    required this.frequency,
    required this.city,
    required this.region,
    required this.paisCodigo,
    required this.paisNombre,
    required this.streamUrl,
    this.streamUrlFallback = '',
    required this.logo,
    required this.idioma,
    required this.denomination,
    required this.description,
    required this.priority,
    required this.searchBlob,
  });

  factory EmisoraModel.create({
    required String id,
    required String name,
    required String frequency,
    required String city,
    required String region,
    required String paisCodigo,
    required String paisNombre,
    required String streamUrl,
    String streamUrlFallback = '',
    required String logo,
    required String idioma,
    required String denomination,
    String description = '',
    int priority = 3,
  }) {
    final String blob = normalizeForSearch(
      '$name|$denomination|$city|$region|$paisCodigo|$paisNombre|$frequency',
    );
    return EmisoraModel(
      id: id,
      name: name,
      frequency: frequency,
      city: city,
      region: region,
      paisCodigo: paisCodigo,
      paisNombre: paisNombre,
      streamUrl: streamUrl,
      streamUrlFallback: streamUrlFallback,
      logo: logo,
      idioma: idioma,
      denomination: denomination,
      description: description,
      priority: priority,
      searchBlob: blob,
    );
  }

  /// Normaliza texto en minúsculas y remueve diacríticos para búsquedas rápidas.
  static String normalizeForSearch(String input) {
    if (input.isEmpty) return '';
    return input
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  Map<String, dynamic> toSqlMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'frequency': frequency,
      'city': city,
      'region': region,
      'pais_codigo': paisCodigo,
      'pais_nombre': paisNombre,
      'stream_url': streamUrl,
      'logo': logo,
      'idioma': idioma,
      'denomination': denomination,
      'description': description,
      'priority': priority,
      'search_blob': searchBlob,
    };
  }

  factory EmisoraModel.fromSqlMap(Map<String, dynamic> map) {
    final String id = (map['id'] ?? '').toString();
    final String name = (map['name'] ?? '').toString();
    final String frequency = (map['frequency'] ?? 'Online').toString();
    final String city = (map['city'] ?? '').toString();
    final String region = (map['region'] ?? '').toString();
    final String paisCodigo = (map['pais_codigo'] ?? 'OTROS').toString();
    final String paisNombre = (map['pais_nombre'] ?? '').toString();
    final String streamUrl = (map['stream_url'] ?? '').toString();
    final String logo = (map['logo'] ?? '').toString();
    final String idioma = (map['idioma'] ?? 'es').toString();
    final String denomination = (map['denomination'] ?? 'Cristiana').toString();
    final String description = (map['description'] ?? '').toString();
    final int priority = map['priority'] is int
        ? map['priority'] as int
        : int.tryParse((map['priority'] ?? '3').toString()) ?? 3;
    final String existingBlob = (map['search_blob'] ?? '').toString();

    return EmisoraModel(
      id: id,
      name: name,
      frequency: frequency,
      city: city,
      region: region,
      paisCodigo: paisCodigo,
      paisNombre: paisNombre,
      streamUrl: streamUrl,
      logo: logo,
      idioma: idioma,
      denomination: denomination,
      description: description,
      priority: priority,
      searchBlob: existingBlob.isNotEmpty
          ? existingBlob
          : normalizeForSearch(
              '$name|$denomination|$city|$region|$paisCodigo|$paisNombre|$frequency',
            ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmisoraModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          streamUrl == other.streamUrl &&
          name == other.name &&
          logo == other.logo;

  @override
  int get hashCode => Object.hash(id, streamUrl, name, logo);
}

/// Parser puro diseñado para ejecutarse en un [Isolate] secundario (`Isolate.run`)
/// evitando bloquear el hilo principal de UI durante la decodificación CSV o JSON.
class EmisorasCatalogParser {
  EmisorasCatalogParser._();

  // URLs verificadas y corregidas para emisoras con enlaces reparados
  static const Map<String, String> correccionesUrlsEmisoras = <String, String>{
    '101': 'http://cdn.instream.audio:9726/stream', // Radio Renuevo 88.7
    '107': 'https://cast10.plugstreaming.com/stream/pvsdq', // Pura Vida 96.7
    '259': 'https://livestreamcdn.net:2000/stream/RadioVisionCristianaRadio/',
    '262': 'https://stream2.305stream.com:8040/;',
    '263': 'https://stream.radiojar.com/ynxaw7n8x74tv',
    '273': 'https://streaming.live365.com/a71179',
    '281': 'https://ewtn-ice.streamguys1.com/english-aac',
    '277': 'https://maestro.emfcdn.com/stream_for/air1/tunein/mp3',
    '282': 'https://shoutcast.christianrock.net/stream/5/',
  };

  /// Decodifica y transforma los bytes CSV de Google Sheets en una lista de [EmisoraModel].
  static List<EmisoraModel> parseCsvBytes(Uint8List bodyBytes) {
    final String csvString = utf8.decode(bodyBytes, allowMalformed: true);
    final String lowerCsv = csvString.trim().toLowerCase();

    if (lowerCsv.startsWith('<!doctype html') || lowerCsv.startsWith('<html')) {
      return const <EmisoraModel>[];
    }

    final List<List<dynamic>> filas = csv.decode(csvString);
    if (filas.isEmpty) return const <EmisoraModel>[];

    int headerRowIndex = -1;
    List<String> headers = <String>[];

    for (int r = 0; r < filas.length; r++) {
      final List<String> candidateHeaders = filas[r]
          .map((dynamic e) => e.toString().trim().toLowerCase())
          .toList();
      if (candidateHeaders.contains('emisora_nombre') ||
          candidateHeaders.contains('emisora_id') ||
          candidateHeaders.contains('name') ||
          candidateHeaders.contains('streamurl')) {
        headerRowIndex = r;
        headers = candidateHeaders;
        break;
      }
    }

    final Set<String> clavesProcesadas = <String>{};
    final List<EmisoraModel> resultado = <EmisoraModel>[];

    for (int i = 0; i < filas.length; i++) {
      if (i == headerRowIndex) continue;
      try {
        final List<dynamic> row = filas[i];
        if (row.isEmpty) continue;

        final Map<String, dynamic> rowData = <String, dynamic>{};
        if (headers.isNotEmpty) {
          for (int j = 0; j < headers.length; j++) {
            rowData[headers[j]] = (row.length > j) ? row[j] : '';
          }
        } else {
          rowData['emisora_id'] = row.isNotEmpty ? row[0] : '';
          rowData['pais_codigo'] = row.length > 1 ? row[1] : '';
          rowData['pais'] = row.length > 2 ? row[2] : '';
          rowData['es_favorita'] = row.length > 3 ? row[3] : '';
          rowData['emisora_nombre'] = row.length > 4 ? row[4] : '';
          rowData['emisora_poster'] = row.length > 5 ? row[5] : '';
          rowData['emisora_url'] = row.length > 6 ? row[6] : '';
          rowData['idioma'] = row.length > 7 ? row[7] : '';
        }

        final String idRaw =
            (rowData['emisora_id'] ?? rowData['id'] ?? i.toString())
                .toString()
                .trim();
        final String nombreRaw =
            (rowData['emisora_nombre'] ??
                    rowData['name'] ??
                    rowData['nombre'] ??
                    '')
                .toString()
                .trim();

        if (idRaw.toLowerCase() == 'emisora_id' ||
            nombreRaw.toLowerCase() == 'emisora_nombre') {
          continue;
        }

        bool isActive = true;
        String activeKey = '';
        for (final String key in rowData.keys) {
          if (key == 'isactive' ||
              key == 'is_active' ||
              key == 'activo' ||
              key == 'es_activo' ||
              key == 'estado') {
            activeKey = key;
            break;
          }
        }

        if (activeKey.isNotEmpty) {
          final String raw = rowData[activeKey].toString().toLowerCase().trim();
          isActive = const <String>[
            'true',
            '1',
            'verdadero',
            'si',
            'sí',
            'yes',
            'activo',
          ].contains(raw);
        }

        if (!isActive) continue;

        String rawUrl = _limpiarStreamUrl(
          (rowData['streamurl'] ??
                  rowData['emisora_url'] ??
                  rowData['url'] ??
                  '')
              .toString()
              .trim(),
        );

        if (correccionesUrlsEmisoras.containsKey(idRaw)) {
          rawUrl = correccionesUrlsEmisoras[idRaw]!;
        }

        if (nombreRaw.isEmpty && rawUrl.isEmpty) continue;

        final String claveUnica = idRaw.isNotEmpty
            ? idRaw
            : '$nombreRaw|$rawUrl';
        if (!clavesProcesadas.add(claveUnica)) {
          continue;
        }

        final String rawPais =
            (rowData['pais_codigo'] ??
                    rowData['pais'] ??
                    rowData['country'] ??
                    '')
                .toString()
                .trim()
                .toUpperCase();
        final String paisCodigo = rawPais.isEmpty ? 'OTROS' : rawPais;

        final String paisNombre =
            (rowData['pais'] ??
                    rowData['pais_nombre'] ??
                    rowData['country'] ??
                    '')
                .toString()
                .trim();

        final String logo =
            (rowData['emisora_poster'] ??
                    rowData['logo'] ??
                    rowData['poster'] ??
                    '')
                .toString()
                .trim();

        String idioma = (rowData['idioma'] ?? rowData['language'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        if (idioma.isEmpty) {
          idioma = (paisCodigo == 'US') ? 'en' : 'es';
        } else if (idioma.startsWith('es') || idioma.contains('espa')) {
          idioma = 'es';
        } else if (idioma.startsWith('en') || idioma.contains('ingl')) {
          idioma = 'en';
        }

        resultado.add(
          EmisoraModel.create(
            id: idRaw.isNotEmpty ? idRaw : i.toString(),
            name: nombreRaw,
            frequency: (rowData['frequency'] ?? 'Online').toString().trim(),
            city: (rowData['city'] ?? rowData['pais'] ?? '').toString().trim(),
            region: (rowData['region'] ?? '').toString().trim(),
            paisCodigo: paisCodigo,
            paisNombre: paisNombre,
            streamUrl: rawUrl,
            logo: logo,
            idioma: idioma,
            denomination:
                (rowData['denomination'] ??
                        rowData['denominacion'] ??
                        'Cristiana')
                    .toString()
                    .trim(),
            description: (rowData['description'] ?? '').toString().trim(),
            priority: 3,
          ),
        );
      } catch (_) {
        // Ignorar fila malformada individual sin abortar el lote
      }
    }

    return resultado;
  }

  /// Decodifica el JSON local de respaldo (`assets/json/emisoras_rd.json`) en un Isolate.
  static List<EmisoraModel> parseFallbackJson(String jsonString) {
    try {
      final List<dynamic> data = json.decode(jsonString) as List<dynamic>;
      final List<EmisoraModel> listaParseada = <EmisoraModel>[];

      for (int i = 0; i < data.length; i++) {
        final Map<String, dynamic> e = Map<String, dynamic>.from(
          data[i] as Map<dynamic, dynamic>,
        );

        if (e['isActive'] == false) continue;

        final String id = (e['id'] ?? e['emisora_id'] ?? i.toString())
            .toString()
            .trim();
        String rawUrl = _limpiarStreamUrl(
          (e['streamUrl'] ?? e['emisora_url'] ?? e['url'] ?? '')
              .toString()
              .trim(),
        );
        if (correccionesUrlsEmisoras.containsKey(id)) {
          rawUrl = correccionesUrlsEmisoras[id]!;
        }

        final String nombre =
            (e['name'] ?? e['emisora_nombre'] ?? e['nombre'] ?? '')
                .toString()
                .trim();

        if (nombre.isEmpty && rawUrl.isEmpty) continue;

        final String rawPais = (e['pais_codigo'] ?? e['pais'] ?? 'DO')
            .toString()
            .trim()
            .toUpperCase();
        final String idPais = rawPais.isEmpty ? 'DO' : rawPais;
        final String poster =
            (e['logo'] ?? e['emisora_poster'] ?? e['poster'] ?? '')
                .toString()
                .trim();
        final String paisNombre = (e['pais'] ?? e['pais_nombre'] ?? '')
            .toString()
            .trim();

        listaParseada.add(
          EmisoraModel.create(
            id: id.isNotEmpty ? id : i.toString(),
            name: nombre,
            frequency: (e['frequency'] ?? 'Online').toString().trim(),
            city: (e['city'] ?? paisNombre).toString().trim(),
            region: (e['region'] ?? paisNombre).toString().trim(),
            paisCodigo: idPais,
            paisNombre: paisNombre,
            streamUrl: rawUrl,
            logo: poster,
            idioma: (e['idioma'] ?? 'es').toString().trim().toLowerCase(),
            denomination:
                (e['denomination'] ?? e['denominacion'] ?? 'Cristiana')
                    .toString()
                    .trim(),
            description: (e['description'] ?? '').toString().trim(),
            priority: e['priority'] is int ? e['priority'] as int : 3,
          ),
        );
      }
      return listaParseada;
    } catch (_) {
      return const <EmisoraModel>[];
    }
  }

  static String _limpiarStreamUrl(String rawUrl) {
    if (rawUrl.contains('src="')) {
      final int inicio = rawUrl.indexOf('src="') + 5;
      final int fin = rawUrl.indexOf('"', inicio);
      if (fin > inicio) {
        return rawUrl.substring(inicio, fin);
      }
    } else if (rawUrl.contains("src='")) {
      final int inicio = rawUrl.indexOf("src='") + 5;
      final int fin = rawUrl.indexOf("'", inicio);
      if (fin > inicio) {
        return rawUrl.substring(inicio, fin);
      }
    }
    return rawUrl;
  }
}
