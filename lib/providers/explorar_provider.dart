import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../data/app_config.dart';
import '../modelos/iglesia_explorar_model.dart';

/// Modo de exploración
enum ModoExploracion {
  /// Búsqueda por radio georreferenciado (10 km, 25 km, 50 km) dentro del país actual
  radio,

  /// Búsqueda por texto en todo el territorio del país actual
  nacional,
}

/// Elemento de caché en memoria con Time-To-Live (TTL de 10 min)
class _CachedExplorarResult {
  final List<IglesiaExplorarModel> resultados;
  final String? nextPageToken;
  final DateTime fechaCreacion;

  _CachedExplorarResult({required this.resultados, required this.nextPageToken})
    : fechaCreacion = DateTime.now();

  bool get esValido =>
      DateTime.now().difference(fechaCreacion) < const Duration(minutes: 10);
}

/// Proveedor de estado para la pantalla Explorar
/// Restricción estricta al país actual del usuario (ej. Colombia, República Dominicana, etc.),
/// búsqueda dual (radio/nacional), paginación de 15 en 15 y mitigación de costos de API.
class ExplorarProvider extends ChangeNotifier {
  static String get _googleApiKey => AppConfig.googleMapsApiKey;
  static const int itemsPerPage = 15;

  static const List<Color> _brandColors = [
    Color(0xFF072B4F),
    Color(0xFF4A7C59),
    Color(0xFFE5A023),
    Color(0xFF2B7A78),
  ];

  static const Map<String, String> paisesNombres = {
    'DO': 'República Dominicana',
    'CO': 'Colombia',
    'MX': 'México',
    'VE': 'Venezuela',
    'US': 'Estados Unidos',
    'PR': 'Puerto Rico',
    'GT': 'Guatemala',
    'CR': 'Costa Rica',
    'PA': 'Panamá',
    'AR': 'Argentina',
    'CL': 'Chile',
    'PE': 'Perú',
    'EC': 'Ecuador',
    'ES': 'España',
  };

  static const Map<String, String> paisesNombresEn = {
    'DO': 'Dominican Republic',
    'CO': 'Colombia',
    'MX': 'Mexico',
    'VE': 'Venezuela',
    'US': 'United States',
    'PR': 'Puerto Rico',
    'GT': 'Guatemala',
    'CR': 'Costa Rica',
    'PA': 'Panama',
    'AR': 'Argentina',
    'CL': 'Chile',
    'PE': 'Peru',
    'EC': 'Ecuador',
    'ES': 'Spain',
  };

  static const Map<String, String> paisesBanderas = {
    'DO': '🇩🇴',
    'CO': '🇨🇴',
    'MX': '🇲🇽',
    'VE': '🇻🇪',
    'US': '🇺🇸',
    'PR': '🇵🇷',
    'GT': '🇬🇹',
    'CR': '🇨🇷',
    'PA': '🇵🇦',
    'AR': '🇦🇷',
    'CL': '🇨🇱',
    'PE': '🇵🇪',
    'EC': '🇪🇨',
    'ES': '🇪🇸',
  };

  // --- Estado de Búsqueda y Filtros ---
  ModoExploracion _modo = ModoExploracion.radio;
  double _radioKm = 10.0; // 10, 25, 50 km
  String _paisCodigo = 'DO'; // Estrictamente el país actual del usuario
  int _filtroDenominacionIndex = 0;
  String _textoBusqueda = '';

  // --- Estado de Carga y Datos ---
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = false;
  String? _errorMessage;

  // --- Paginación estricta (15 en 15) ---
  final List<IglesiaExplorarModel> _iglesiasMostradas = [];
  List<IglesiaExplorarModel> _bufferResultados = [];
  String? _nextPageToken;

  // --- Mitigación de Costos de API ---
  Timer? _debounceTimer;
  final Map<String, _CachedExplorarResult> _cache = {};

  // --- Getters Públicos ---
  ModoExploracion get modo => _modo;
  double get radioKm => _radioKm;
  String get paisCodigo => _paisCodigo;
  String get paisNombre => getPaisNombre();

  /// Obtiene el nombre del país localizado según el código de idioma ('es' o 'en')
  String getPaisNombre([String? codigoIdioma]) {
    final codigo = _paisCodigo.toUpperCase();
    if (codigoIdioma != null && codigoIdioma.toLowerCase().startsWith('en')) {
      return paisesNombresEn[codigo] ??
          paisesNombres[codigo] ??
          'Dominican Republic';
    }
    return paisesNombres[codigo] ?? 'República Dominicana';
  }

  String get paisBandera => paisesBanderas[_paisCodigo.toUpperCase()] ?? '🌎';
  int get filtroDenominacionIndex => _filtroDenominacionIndex;
  String get textoBusqueda => _textoBusqueda;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  String? get errorMessage => _errorMessage;
  List<IglesiaExplorarModel> get iglesiasMostradas => _iglesiasMostradas;
  List<IglesiaExplorarModel> get bufferResultados => _bufferResultados;
  int get totalResultadosCargados => _bufferResultados.length;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Sincroniza el país de residencia del usuario
  void sincronizarPais(String codigo) {
    final normalizado = codigo.toUpperCase();
    if (_paisCodigo != normalizado && paisesNombres.containsKey(normalizado)) {
      _paisCodigo = normalizado;
    }
  }

  /// Actualiza la posición GPS y detecta automáticamente el país estricto según coordenadas
  void setUbicacion(Position posicion) {
    _currentPosition = posicion;
    final paisDetectado = _detectarPaisPorCoordenadas(
      posicion.latitude,
      posicion.longitude,
    );
    if (paisDetectado != null && paisDetectado != _paisCodigo) {
      _paisCodigo = paisDetectado;
      debugPrint('[ExplorarProvider] País detectado por GPS: $_paisCodigo');
    }
  }

  /// Detección geográfica estricta por polígonos/cuadrantes de coordenadas
  String? _detectarPaisPorCoordenadas(double lat, double lng) {
    // República Dominicana
    if (lat >= 17.4 && lat <= 20.1 && lng >= -72.1 && lng <= -68.2) {
      return 'DO';
    }
    // Colombia
    if (lat >= -4.3 && lat <= 13.5 && lng >= -79.2 && lng <= -66.8) {
      return 'CO';
    }
    // México
    if (lat >= 14.5 && lat <= 32.8 && lng >= -118.5 && lng <= -86.7) {
      return 'MX';
    }
    // Venezuela
    if (lat >= 0.6 && lat <= 12.5 && lng >= -73.5 && lng <= -59.8) {
      return 'VE';
    }
    // Estados Unidos
    if (lat >= 24.5 && lat <= 49.5 && lng >= -125.0 && lng <= -66.9) {
      return 'US';
    }
    // Puerto Rico
    if (lat >= 17.8 && lat <= 18.6 && lng >= -67.3 && lng <= -65.2) {
      return 'PR';
    }
    return null;
  }

  /// Cambia el modo de exploración: Radio GPS o Búsqueda Nacional dentro del país actual
  void cambiarModo(ModoExploracion nuevoModo) {
    if (_modo == nuevoModo) return;
    _modo = nuevoModo;
    notifyListeners();
    buscar(ignorarDebounce: true);
  }

  /// Cambia el radio georreferenciado (10 km, 25 km, 50 km)
  void cambiarRadio(double nuevoRadioKm) {
    if (_radioKm == nuevoRadioKm) return;
    _radioKm = nuevoRadioKm;
    _modo = ModoExploracion.radio;
    notifyListeners();
    buscar(ignorarDebounce: true);
  }

  /// Cambia el filtro de denominación (0: Todas, 1: Católica, 2: Evangélica, etc.)
  void cambiarDenominacion(int index) {
    if (_filtroDenominacionIndex == index) return;
    _filtroDenominacionIndex = index;
    notifyListeners();
    buscar(ignorarDebounce: true);
  }

  /// Normaliza texto para búsqueda insensible a mayúsculas, minúsculas y tildes
  static String normalizarTexto(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }

  /// Verifica si el nombre de la iglesia contiene estrictamente el término buscado
  static bool contieneTerminoEnNombre(
    String nombreIglesia,
    String terminoBuscado,
  ) {
    final termino = normalizarTexto(terminoBuscado);
    if (termino.isEmpty) return true;

    final nombre = normalizarTexto(nombreIglesia);
    if (nombre.contains(termino)) return true;

    // Si el término contiene varias palabras (ej. "monte sion"), verificar que todas estén presentes
    final palabras =
        termino.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (palabras.length > 1 && palabras.every((p) => nombre.contains(p))) {
      return true;
    }

    return false;
  }

  /// Restablece la búsqueda al estado base: borra término, asegura modo radio
  /// y carga todas las iglesias en el rango de acción del usuario (10, 25 o 50 km).
  void limpiarBusqueda() {
    _debounceTimer?.cancel();
    _textoBusqueda = '';
    _modo = ModoExploracion.radio;
    buscar(ignorarDebounce: true);
  }

  /// Limpia únicamente el término de búsqueda de texto, manteniendo el modo y la denominación actuales.
  void limpiarTextoBusqueda({bool recargar = true}) {
    _debounceTimer?.cancel();
    _textoBusqueda = '';
    if (recargar) {
      buscar(ignorarDebounce: true);
    } else {
      notifyListeners();
    }
  }

  /// Maneja el cambio de texto con Debounce de 500 ms y longitud mínima de 3 caracteres
  void onTextoBusquedaCambiado(String nuevoTexto) {
    _textoBusqueda = nuevoTexto;
    _debounceTimer?.cancel();

    final textoLimpio = nuevoTexto.trim();

    // Si el usuario borra o limpia la barra de búsqueda, restablecer al rango de acción normal
    if (textoLimpio.isEmpty) {
      limpiarBusqueda();
      return;
    }

    if (textoLimpio.length < 3) {
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      buscar(ignorarDebounce: true);
    });
  }

  /// Ejecuta la búsqueda de inmediato con el término dado o restablece si está vacío
  void ejecutarBusquedaInmediata(String texto) {
    _debounceTimer?.cancel();
    final textoLimpio = texto.trim();
    if (textoLimpio.isEmpty) {
      limpiarBusqueda();
    } else {
      _textoBusqueda = texto;
      buscar(ignorarDebounce: true);
    }
  }

  /// Resuelve la clave de consulta para la API de Google Places, vinculándola estrictamente al país
  String _construirQueryApi() {
    String terminoDenominacion = '';
    switch (_filtroDenominacionIndex) {
      case 1:
        terminoDenominacion = 'católica';
        break;
      case 2:
        terminoDenominacion = 'evangélica';
        break;
      case 3:
        terminoDenominacion = 'pentecostal';
        break;
      case 4:
        terminoDenominacion = 'bautista';
        break;
      case 5:
        terminoDenominacion = 'adventista';
        break;
      case 0:
      default:
        terminoDenominacion = '';
        break;
    }

    final texto = _textoBusqueda.trim();

    if (_modo == ModoExploracion.nacional) {
      // Modo Nacional: Búsqueda estricta en todo el país actual del usuario
      final partes = <String>[];
      if (texto.isNotEmpty) {
        partes.add(texto);
      }
      if (terminoDenominacion.isNotEmpty) {
        partes.add(terminoDenominacion);
      }
      partes.add('iglesia');
      // Forzar explícitamente el país actual
      partes.add(paisNombre);
      return partes.join(' ');
    } else {
      // Modo Radio: Búsqueda local reforzada con el país actual (priorizando el término de búsqueda)
      final partes = <String>[];
      if (texto.isNotEmpty) {
        partes.add(texto);
      }
      partes.add('iglesia');
      if (terminoDenominacion.isNotEmpty) {
        partes.add(terminoDenominacion);
      }
      partes.add(paisNombre);
      return partes.join(' ');
    }
  }

  /// Verifica estrictamente que la dirección del lugar pertenezca al país actual
  bool _perteneceAlPaisActual(String formattedAddress) {
    if (formattedAddress.isEmpty) return true;
    final addr = formattedAddress.toLowerCase();
    final nombre = paisNombre.toLowerCase();
    final codigo = _paisCodigo.toLowerCase();

    // 1. Coincidencia directa de nombre de país o código ISO
    if (addr.contains(nombre) || addr.contains(codigo)) {
      return true;
    }

    // 2. Variantes idiomáticas y abreviaturas oficiales por país
    switch (codigo) {
      case 'do':
        return addr.contains('república dominicana') ||
            addr.contains('republica dominicana') ||
            addr.contains('dominican republic') ||
            addr.contains('dominicana') ||
            addr.contains('r.d.') ||
            addr.contains(', rd');
      case 'co':
        return addr.contains('colombia');
      case 'mx':
        return addr.contains('méxico') ||
            addr.contains('mexico') ||
            addr.contains('cdmx');
      case 've':
        return addr.contains('venezuela');
      case 'us':
        return addr.contains('united states') ||
            addr.contains('usa') ||
            addr.contains('ee. uu.');
      case 'pr':
        return addr.contains('puerto rico');
      default:
        return addr.contains(nombre);
    }
  }

  /// Clave única para la caché en memoria
  String _generarClaveCache() {
    return '${_modo.name}_${_radioKm}_${_paisCodigo}_${_filtroDenominacionIndex}_${_textoBusqueda.trim().toLowerCase()}';
  }

  /// Realiza la búsqueda principal controlando estados y caché
  Future<void> buscar({
    bool ignorarDebounce = false,
    bool forzarRecarga = false,
  }) async {
    if (!ignorarDebounce &&
        _debounceTimer != null &&
        _debounceTimer!.isActive) {
      return;
    }

    if (_isLoading) return;

    final claveCache = _generarClaveCache();

    // 1. Verificar si existe en caché válido (Mitigación de costos $0)
    if (!forzarRecarga && _cache.containsKey(claveCache)) {
      final cached = _cache[claveCache]!;
      if (cached.esValido) {
        _bufferResultados = List.from(cached.resultados);
        _nextPageToken = cached.nextPageToken;
        _actualizarLoteInicial();
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return;
      } else {
        _cache.remove(claveCache);
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final query = _construirQueryApi();
      final uri = Uri.parse(
        'https://places.googleapis.com/v1/places:searchText',
      );

      const fieldMask =
          'places.id,places.displayName,places.formattedAddress,'
          'places.location,places.rating,places.userRatingCount,nextPageToken';

      final List<Map<String, dynamic>> rawPlaces = [];

      // Cuando estamos en Modo Radio y el usuario selecciona 25 km o 50 km,
      // Google Places por defecto solo retorna 20 lugares concentrados en el centro (< 5 km).
      // Realizamos un muestreo radial distribuido en anillos concéntricos para abarcar
      // y traer efectivamente TODAS las iglesias de la denominación en ese radio geográfico.
      if (_modo == ModoExploracion.radio &&
          _currentPosition != null &&
          _radioKm >= 25.0) {
        final centerLat = _currentPosition!.latitude;
        final centerLng = _currentPosition!.longitude;
        final cosLat = cos(centerLat * pi / 180.0);

        final List<Map<String, dynamic>> puntosMuestreo = [
          {"lat": centerLat, "lng": centerLng, "radius": 10000.0},
        ];

        if (_radioKm == 25.0) {
          const offsetKm = 16.0;
          final dLat = offsetKm / 111.0;
          final dLng = offsetKm / (111.0 * cosLat);
          puntosMuestreo.addAll([
            {"lat": centerLat + dLat, "lng": centerLng, "radius": 12000.0},
            {"lat": centerLat - dLat, "lng": centerLng, "radius": 12000.0},
            {"lat": centerLat, "lng": centerLng + dLng, "radius": 12000.0},
            {"lat": centerLat, "lng": centerLng - dLng, "radius": 12000.0},
          ]);
        } else if (_radioKm >= 50.0) {
          const r1 = 16.0;
          const r2 = 35.0;
          final dLat1 = r1 / 111.0;
          final dLng1 = r1 / (111.0 * cosLat);
          final dLat2 = r2 / 111.0;
          final dLng2 = r2 / (111.0 * cosLat);
          puntosMuestreo.addAll([
            {"lat": centerLat + dLat1, "lng": centerLng, "radius": 12000.0},
            {"lat": centerLat - dLat1, "lng": centerLng, "radius": 12000.0},
            {"lat": centerLat, "lng": centerLng + dLng1, "radius": 12000.0},
            {"lat": centerLat, "lng": centerLng - dLng1, "radius": 12000.0},
            {"lat": centerLat + dLat2, "lng": centerLng, "radius": 18000.0},
            {"lat": centerLat - dLat2, "lng": centerLng, "radius": 18000.0},
            {"lat": centerLat, "lng": centerLng + dLng2, "radius": 18000.0},
            {"lat": centerLat, "lng": centerLng - dLng2, "radius": 18000.0},
          ]);
        }

        final futures = puntosMuestreo.map((pt) async {
          try {
            final bodyJson = {
              "textQuery": query,
              "includedType": "church",
              "languageCode": "es",
              "regionCode": _paisCodigo.toLowerCase(),
              "pageSize": 20,
              "locationBias": {
                "circle": {
                  "center": {"latitude": pt['lat'], "longitude": pt['lng']},
                  "radius": pt['radius'],
                },
              },
            };

            final res = await http.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'X-Goog-Api-Key': _googleApiKey,
                'X-Goog-FieldMask': fieldMask,
              },
              body: jsonEncode(bodyJson),
            );

            if (res.statusCode == 200) {
              final d = jsonDecode(res.body) as Map<String, dynamic>;
              return d['places'] as List? ?? [];
            }
          } catch (e) {
            debugPrint('Aviso en subconsulta de muestreo radial: $e');
          }
          return [];
        });

        final resultadosPorPunto = await Future.wait(futures);
        final Map<String, dynamic> vistos = {};
        for (final lista in resultadosPorPunto) {
          for (final place in lista) {
            final id =
                place['id'] as String? ?? place['displayName']?['text'] ?? '';
            if (id.isNotEmpty && !vistos.containsKey(id)) {
              vistos[id] = place;
              rawPlaces.add(place as Map<String, dynamic>);
            }
          }
        }
      } else {
        // Consulta estándar (10 km o Modo Nacional)
        final Map<String, dynamic> bodyJson = {
          "textQuery": query,
          "includedType": "church",
          "languageCode": "es",
          "regionCode": _paisCodigo.toLowerCase(),
          "pageSize": 20,
        };

        if (_modo == ModoExploracion.radio && _currentPosition != null) {
          bodyJson["locationBias"] = {
            "circle": {
              "center": {
                "latitude": _currentPosition!.latitude,
                "longitude": _currentPosition!.longitude,
              },
              "radius": _radioKm * 1000.0,
            },
          };
        }

        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _googleApiKey,
            'X-Goog-FieldMask': fieldMask,
          },
          body: jsonEncode(bodyJson),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final List resultados = data['places'] ?? [];
          _nextPageToken = data['nextPageToken'] as String?;
          rawPlaces.addAll(resultados.cast<Map<String, dynamic>>());
        }
      }

      final List<IglesiaExplorarModel> iglesiasObtenidas = [];
      int colorIdx = 0;
      final String terminoFiltro = _textoBusqueda.trim();

      for (var place in rawPlaces) {
        final formattedAddress = place['formattedAddress'] as String? ?? '';

        // FILTRO ESTRICTO DE PAÍS: Descartar tajantemente cualquier lugar que no pertenezca al país actual
        if (!_perteneceAlPaisActual(formattedAddress)) {
          continue;
        }

        final iglesia = IglesiaExplorarModel.fromPlacesApi(
          place,
          _currentPosition,
          _brandColors[colorIdx % _brandColors.length],
        );

        // FILTRO ESTRICTO POR NOMBRE:
        // Si el usuario especificó un término de búsqueda (ej. "lima"),
        // deben aparecer única y exclusivamente las iglesias que contengan dicho término en su nombre.
        if (terminoFiltro.isNotEmpty &&
            !contieneTerminoEnNombre(iglesia.nombre, terminoFiltro)) {
          continue;
        }

        // En modo radio, verificar además que no supere el radio seleccionado en km (+ 1.5 km de tolerancia)
        if (_modo == ModoExploracion.radio) {
          if (iglesia.distanciaKm <= (_radioKm + 1.5)) {
            iglesiasObtenidas.add(iglesia);
            colorIdx++;
          }
        } else {
          iglesiasObtenidas.add(iglesia);
          colorIdx++;
        }
      }

      // Ordenar por cercanía si tenemos ubicación
      if (_currentPosition != null) {
        iglesiasObtenidas.sort(
          (a, b) => a.distanciaKm.compareTo(b.distanciaKm),
        );
      }

      _bufferResultados = iglesiasObtenidas;

      // Guardar en caché con TTL de 10 min
      _cache[claveCache] = _CachedExplorarResult(
        resultados: iglesiasObtenidas,
        nextPageToken: _nextPageToken,
      );

      _actualizarLoteInicial();
    } catch (e) {
      debugPrint('Error en ExplorarProvider.buscar: $e');
      _errorMessage = '😕 No se pudieron cargar las iglesias.\nRevisa tu conexión a internet e inténtalo de nuevo.';
      _iglesiasMostradas.clear();
      _bufferResultados.clear();
      _hasMoreData = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Extrae el primer lote estricto de 15 elementos
  void _actualizarLoteInicial() {
    _iglesiasMostradas.clear();
    if (_bufferResultados.length <= itemsPerPage) {
      _iglesiasMostradas.addAll(_bufferResultados);
      _hasMoreData = _nextPageToken != null;
    } else {
      _iglesiasMostradas.addAll(_bufferResultados.take(itemsPerPage));
      _hasMoreData = true;
    }
  }

  /// Carga la siguiente página de 15 en 15 elementos (Scroll infinito / Lazy Loading)
  Future<void> cargarSiguientePagina() async {
    if (_isLoadingMore || _isLoading || !_hasMoreData) return;

    final totalCargados = _iglesiasMostradas.length;

    // Caso A: Si aún tenemos más elementos en el buffer local no mostrados
    if (_bufferResultados.length > totalCargados) {
      _isLoadingMore = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 200));
      final restantes = _bufferResultados.length - totalCargados;
      final elementosParaAgregar = restantes >= itemsPerPage
          ? itemsPerPage
          : restantes;

      _iglesiasMostradas.addAll(
        _bufferResultados.skip(totalCargados).take(elementosParaAgregar),
      );

      _hasMoreData =
          _iglesiasMostradas.length < _bufferResultados.length ||
          _nextPageToken != null;
      _isLoadingMore = false;
      notifyListeners();
      return;
    }

    // Caso B: Si el buffer local se agotó pero Google Places API tiene nextPageToken
    if (_nextPageToken != null) {
      _isLoadingMore = true;
      notifyListeners();

      try {
        final query = _construirQueryApi();
        final uri = Uri.parse(
          'https://places.googleapis.com/v1/places:searchText',
        );

        final Map<String, dynamic> bodyJson = {
          "textQuery": query,
          "includedType": "church",
          "languageCode": "es",
          "regionCode": _paisCodigo.toLowerCase(),
          "pageSize": 20,
          "pageToken": _nextPageToken,
        };

        if (_modo == ModoExploracion.radio && _currentPosition != null) {
          bodyJson["locationBias"] = {
            "circle": {
              "center": {
                "latitude": _currentPosition!.latitude,
                "longitude": _currentPosition!.longitude,
              },
              "radius": _radioKm * 1000.0,
            },
          };
        }

        const fieldMask =
            'places.id,places.displayName,places.formattedAddress,'
            'places.location,places.rating,places.userRatingCount,nextPageToken';

        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _googleApiKey,
            'X-Goog-FieldMask': fieldMask,
          },
          body: jsonEncode(bodyJson),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final List nuevos = data['places'] ?? [];
          _nextPageToken = data['nextPageToken'] as String?;

          int colorIdx = _bufferResultados.length;
          final List<IglesiaExplorarModel> nuevasIglesias = [];
          final String terminoFiltro = _textoBusqueda.trim();

          for (var place in nuevos) {
            final formattedAddress = place['formattedAddress'] as String? ?? '';

            // FILTRO ESTRICTO DE PAÍS
            if (!_perteneceAlPaisActual(formattedAddress)) {
              continue;
            }

            final iglesia = IglesiaExplorarModel.fromPlacesApi(
              place,
              _currentPosition,
              _brandColors[colorIdx % _brandColors.length],
            );

            // FILTRO ESTRICTO POR NOMBRE
            if (terminoFiltro.isNotEmpty &&
                !contieneTerminoEnNombre(iglesia.nombre, terminoFiltro)) {
              continue;
            }

            if (_modo == ModoExploracion.radio) {
              if (iglesia.distanciaKm <= _radioKm) {
                nuevasIglesias.add(iglesia);
                colorIdx++;
              }
            } else {
              nuevasIglesias.add(iglesia);
              colorIdx++;
            }
          }

          _bufferResultados.addAll(nuevasIglesias);

          final elementosParaAgregar = nuevasIglesias.length >= itemsPerPage
              ? itemsPerPage
              : nuevasIglesias.length;

          _iglesiasMostradas.addAll(nuevasIglesias.take(elementosParaAgregar));

          _hasMoreData =
              _iglesiasMostradas.length < _bufferResultados.length ||
              _nextPageToken != null;
        } else {
          _hasMoreData = false;
        }
      } catch (e) {
        debugPrint('Error cargando siguiente página: $e');
        _hasMoreData = false;
      } finally {
        _isLoadingMore = false;
        notifyListeners();
      }
    } else {
      _hasMoreData = false;
      notifyListeners();
    }
  }

  /// Limpia la caché y fuerza recarga completa
  Future<void> refrescar() async {
    _cache.remove(_generarClaveCache());
    await buscar(ignorarDebounce: true, forzarRecarga: true);
  }
}
