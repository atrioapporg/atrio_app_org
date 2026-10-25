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
    final bool esPrimeraUbicacion = _currentPosition == null;
    _currentPosition = posicion;
    final paisDetectado = _detectarPaisPorCoordenadas(
      posicion.latitude,
      posicion.longitude,
    );
    if (paisDetectado != null && paisDetectado != _paisCodigo) {
      _paisCodigo = paisDetectado;
      debugPrint('[ExplorarProvider] País detectado por GPS: $_paisCodigo');
    }
    // Si es la primera vez que se adquiere la ubicación GPS, limpiar caché huérfano sin GPS
    if (esPrimeraUbicacion) {
      _cache.removeWhere((k, _) => k.contains('sin_gps'));
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
  void cambiarDenominacion(int index, {bool recargar = true}) {
    if (_filtroDenominacionIndex == index) return;
    _filtroDenominacionIndex = index;
    notifyListeners();
    if (recargar) {
      buscar(ignorarDebounce: true);
    }
  }

  /// Términos sinónimos y jerárquicos del catolicismo para búsquedas eclesiásticas inclusivas
  static const List<String> terminosEclesiasticosCatolicos = [
    'iglesia',
    'parroquia',
    'capilla',
    'catedral',
    'santuario',
    'basílica',
    'basilica',
    'católica',
    'catolica',
    'arquidiócesis',
    'arquidiocesis',
    'diócesis',
    'diocesis',
  ];

  /// Comprueba si el nombre o dirección corresponden a una institución o templo católico
  static bool esLugarCatolico(String nombre, [String formattedAddress = '']) {
    final n = normalizarTexto(nombre);
    final a = normalizarTexto(formattedAddress);
    final combinado = '$n $a';

    // Descartar de inmediato si contiene términos explícitos de otras confesiones
    if (combinado.contains('adventista') ||
        combinado.contains('bautista') ||
        combinado.contains('pentecostal') ||
        combinado.contains('evangelica') ||
        combinado.contains('mormon') ||
        combinado.contains('testigos de jehova') ||
        combinado.contains('asamblea de dios') ||
        combinado.contains('asambleas de dios')) {
      return false;
    }

    // Comprobar términos jerárquicos eclesiásticos específicos (excluyendo 'iglesia' que es genérica)
    for (final termino in terminosEclesiasticosCatolicos) {
      if (termino == 'iglesia') continue;
      final normalizado = normalizarTexto(termino);
      if (combinado.contains(normalizado)) {
        return true;
      }
    }

    // Invocaciones marianas y patronales típicamente católicas
    if (combinado.contains('catolica') ||
        combinado.contains('nuestra senora') ||
        combinado.contains('nuestra senor') ||
        combinado.contains('virgen') ||
        combinado.contains('sagrado corazon') ||
        combinado.contains('santisimo sacramento')) {
      return true;
    }

    return false;
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

  /// Verifica si el nombre de la iglesia contiene el término buscado,
  /// contemplando sinónimos eclesiásticos cuando corresponda o cuando
  /// la búsqueda activa sea sobre la fe católica.
  static bool contieneTerminoEnNombre(
    String nombreIglesia,
    String terminoBuscado, {
    int filtroDenominacionIndex = 0,
  }) {
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

    // Si el filtro de denominación es Católica (1) o el término de búsqueda es "iglesia"
    // y el lugar posee una denominación o título eclesiástico católico (parroquia, capilla, catedral, etc.),
    // debe ser inclusivo y no descartar el registro.
    final esFiltroCatolico = filtroDenominacionIndex == 1;
    if (esFiltroCatolico || termino == 'iglesia') {
      final coincideEclesiastico = terminosEclesiasticosCatolicos.any(
        (e) => nombre.contains(normalizarTexto(e)),
      );
      if (coincideEclesiastico) {
        // Si el usuario buscó "iglesia", cualquier parroquia/capilla/catedral es válida
        if (termino == 'iglesia') return true;
        // Si el usuario buscó un término específico más allá de "iglesia" (ej. "amparo"),
        // verificar si alguna de las palabras específicas coincide
        final palabrasEspecificas = palabras
            .where((p) => !terminosEclesiasticosCatolicos.contains(p))
            .toList();
        if (palabrasEspecificas.isEmpty ||
            palabrasEspecificas.any((p) => nombre.contains(p))) {
          return true;
        }
      }
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

  /// Verifica que el templo cumpla estrictamente con la denominación seleccionada
  bool cumpleFiltroDenominacion(IglesiaExplorarModel iglesia) {
    if (_filtroDenominacionIndex == 1) {
      // Filtro Católico: Parroquias, capillas, catedrales, santuarios, basílicas o catalogadas como Católicas
      return esLugarCatolico(iglesia.nombre, iglesia.direccion) ||
          iglesia.denominacion.toLowerCase() == 'católica' ||
          iglesia.denominacion.toLowerCase() == 'catolica';
    } else if (_filtroDenominacionIndex == 2) {
      return (iglesia.denominacion.toLowerCase().contains('evang') ||
              iglesia.nombre.toLowerCase().contains('evang')) &&
          !esLugarCatolico(iglesia.nombre, iglesia.direccion);
    } else if (_filtroDenominacionIndex == 3) {
      return (iglesia.denominacion.toLowerCase().contains('pentecost') ||
              iglesia.nombre.toLowerCase().contains('pentecost')) &&
          !esLugarCatolico(iglesia.nombre, iglesia.direccion);
    } else if (_filtroDenominacionIndex == 4) {
      return (iglesia.denominacion.toLowerCase().contains('bautist') ||
              iglesia.nombre.toLowerCase().contains('bautist')) &&
          !esLugarCatolico(iglesia.nombre, iglesia.direccion);
    } else if (_filtroDenominacionIndex == 5) {
      return (iglesia.denominacion.toLowerCase().contains('adventist') ||
              iglesia.nombre.toLowerCase().contains('adventist')) &&
          !esLugarCatolico(iglesia.nombre, iglesia.direccion);
    }
    return true; // 0: Todas
  }

  /// Construye las consultas textuales concurrentes para Google Places API (New).
  /// Google Places Text Search NO soporta sintaxis booleana 'OR'. Por ello,
  /// se construyen consultas atómicas especializadas que se ejecutan en paralelo.
  List<String> _construirQueriesApi() {
    final texto = _textoBusqueda.trim();
    final List<String> queries = [];

    switch (_filtroDenominacionIndex) {
      case 1:
        // Denominación Católica:
        // Aseguramos consultas para "parroquia", "iglesia católica" y en radio "iglesia"
        // para garantizar que templos locales como "Parroquia Nuestra Señora del Amparo"
        // aparezcan siempre en el mapa.
        if (texto.isNotEmpty) {
          queries.add('$texto parroquia $paisNombre');
          queries.add('$texto iglesia católica $paisNombre');
          queries.add('$texto $paisNombre');
        } else {
          queries.add('parroquia $paisNombre');
          queries.add('iglesia católica $paisNombre');
          if (_modo == ModoExploracion.radio) {
            queries.add('iglesia $paisNombre');
          }
        }
        break;
      case 2:
        if (texto.isNotEmpty) {
          queries.add('$texto iglesia evangélica $paisNombre');
          queries.add('$texto evangélica $paisNombre');
        } else {
          queries.add('iglesia evangélica $paisNombre');
        }
        break;
      case 3:
        if (texto.isNotEmpty) {
          queries.add('$texto iglesia pentecostal $paisNombre');
          queries.add('$texto pentecostal $paisNombre');
        } else {
          queries.add('iglesia pentecostal $paisNombre');
        }
        break;
      case 4:
        if (texto.isNotEmpty) {
          queries.add('$texto iglesia bautista $paisNombre');
          queries.add('$texto bautista $paisNombre');
        } else {
          queries.add('iglesia bautista $paisNombre');
        }
        break;
      case 5:
        if (texto.isNotEmpty) {
          queries.add('$texto iglesia adventista $paisNombre');
          queries.add('$texto adventista $paisNombre');
        } else {
          queries.add('iglesia adventista $paisNombre');
        }
        break;
      case 0:
      default:
        if (texto.isNotEmpty) {
          queries.add('$texto iglesia $paisNombre');
          queries.add('$texto parroquia $paisNombre');
          queries.add('$texto $paisNombre');
        } else {
          queries.add('iglesia $paisNombre');
          queries.add('parroquia $paisNombre');
        }
        break;
    }
    return queries;
  }

  /// Resuelve la consulta textual principal para la API de Google Places
  String _construirQueryApi() {
    final queries = _construirQueriesApi();
    return queries.isNotEmpty ? queries.first : 'iglesia $paisNombre';
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

  /// Clave única para la caché en memoria vinculada a la geolocalización aproximada
  String _generarClaveCache() {
    final latStr = _currentPosition != null
        ? _currentPosition!.latitude.toStringAsFixed(2)
        : 'sin_gps';
    final lngStr = _currentPosition != null
        ? _currentPosition!.longitude.toStringAsFixed(2)
        : 'sin_gps';
    return '${_modo.name}_${_radioKm}_${_paisCodigo}_${_filtroDenominacionIndex}_${_textoBusqueda.trim().toLowerCase()}_${latStr}_$lngStr';
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
      final queries = _construirQueriesApi();
      final uri = Uri.parse(
        'https://places.googleapis.com/v1/places:searchText',
      );

      const fieldMask =
          'places.id,places.displayName,places.formattedAddress,'
          'places.location,places.rating,places.userRatingCount,nextPageToken';

      final Map<String, dynamic> vistos = {};
      final List<Map<String, dynamic>> rawPlaces = [];

      Future<List<Map<String, dynamic>>> ejecutarSubconsulta(
        String queryText, {
        double? lat,
        double? lng,
        double? radiusMeters,
      }) async {
        try {
          final Map<String, dynamic> bodyJson = {
            "textQuery": queryText,
            "includedType": "church",
            "languageCode": "es",
            "regionCode": _paisCodigo.toLowerCase(),
            "pageSize": 20,
          };

          if (_modo == ModoExploracion.radio) {
            final centerLat = lat ?? _currentPosition?.latitude;
            final centerLng = lng ?? _currentPosition?.longitude;
            final r = radiusMeters ?? (_radioKm * 1000.0);
            if (centerLat != null && centerLng != null) {
              bodyJson["locationBias"] = {
                "circle": {
                  "center": {"latitude": centerLat, "longitude": centerLng},
                  "radius": r,
                },
              };
            }
          }

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
            final List items = d['places'] ?? [];
            if (_nextPageToken == null && d['nextPageToken'] != null) {
              _nextPageToken = d['nextPageToken'] as String?;
            }
            return items.cast<Map<String, dynamic>>();
          }
        } catch (e) {
          debugPrint('Aviso en subconsulta Places API ($queryText): $e');
        }
        return [];
      }

      // Cuando estamos en Modo Radio y el usuario selecciona 25 km o 50 km,
      // realizamos un muestreo radial distribuido en anillos concéntricos
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

        final subconsultas = <Future<List<Map<String, dynamic>>>>[];
        for (final q in queries) {
          for (final pt in puntosMuestreo) {
            subconsultas.add(ejecutarSubconsulta(
              q,
              lat: pt['lat'] as double,
              lng: pt['lng'] as double,
              radiusMeters: pt['radius'] as double,
            ));
          }
        }

        final resultadosPorPunto = await Future.wait(subconsultas);
        for (final lista in resultadosPorPunto) {
          for (final place in lista) {
            final id =
                place['id'] as String? ?? place['displayName']?['text'] ?? '';
            if (id.isNotEmpty && !vistos.containsKey(id)) {
              vistos[id] = place;
              rawPlaces.add(place);
            }
          }
        }
      } else {
        // Consulta estándar (10 km o Modo Nacional): ejecutar consultas concurrentes
        final subconsultas = queries.map((q) => ejecutarSubconsulta(q));
        final resultados = await Future.wait(subconsultas);
        for (final lista in resultados) {
          for (final place in lista) {
            final id =
                place['id'] as String? ?? place['displayName']?['text'] ?? '';
            if (id.isNotEmpty && !vistos.containsKey(id)) {
              vistos[id] = place;
              rawPlaces.add(place);
            }
          }
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

        // FILTRO ESTRICTO POR DENOMINACIÓN:
        if (!cumpleFiltroDenominacion(iglesia)) {
          continue;
        }

        // FILTRO ESTRICTO POR NOMBRE:
        // Si el usuario especificó un término de búsqueda (ej. "amparo"),
        // deben aparecer única y exclusivamente las iglesias que contengan dicho término en su nombre.
        if (terminoFiltro.isNotEmpty &&
            !contieneTerminoEnNombre(
              iglesia.nombre,
              terminoFiltro,
              filtroDenominacionIndex: _filtroDenominacionIndex,
            )) {
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

            // FILTRO ESTRICTO POR DENOMINACIÓN
            if (!cumpleFiltroDenominacion(iglesia)) {
              continue;
            }

            // FILTRO ESTRICTO POR NOMBRE
            if (terminoFiltro.isNotEmpty &&
                !contieneTerminoEnNombre(
                  iglesia.nombre,
                  terminoFiltro,
                  filtroDenominacionIndex: _filtroDenominacionIndex,
                )) {
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
