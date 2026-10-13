import 'package:atrio/servicios/bible_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ModoLectura { calido, suave, noche }

class BibliaProvider with ChangeNotifier {
  final BibleService _bibleService = BibleService();

  // Modos y ajustes visuales de lectura
  ModoLectura _modoLectura = ModoLectura.calido;
  double _fontScale = 1.0;
  String _selectedFont = 'Inter';

  ModoLectura get modoLectura => _modoLectura;
  double get fontScale => _fontScale;
  String get selectedFont => _selectedFont;

  // Versiones disponibles en Bolls Life categorizadas por idioma
  static const Map<String, String> versionesEspanol = {
    'RV1960': 'Reina-Valera 1960',
    'NVI': 'Nueva Versión Internacional',
    'RV2000': 'Reina Valera 2000',
  };

  static const Map<String, String> versionesIngles = {
    'KJV': 'King James Version',
    'WEB': 'World English Bible',
    'ESV': 'English Standard Version',
  };

  // Versiones totales registradas
  final Map<String, String> _versionesDisponibles = {
    ...versionesEspanol,
    ...versionesIngles,
  };

  String _versionActual = 'RV1960';
  Map<String, dynamic>? _versiculoDelDia;
  bool _isLoading = true;
  String? _errorMessage;

  // Estado para la búsqueda
  bool _isSearching = false;
  bool _busquedaRealizada = false;
  String _ultimaConsulta = '';
  List<Map<String, dynamic>> _resultadosBusqueda = [];
  String? _searchErrorMessage;

  Map<String, String> get versionesDisponibles => _versionesDisponibles;
  String get versionActual => _versionActual;
  String get nombreVersionActual =>
      _versionesDisponibles[_versionActual] ?? _versionActual;
  Map<String, dynamic>? get versiculoDelDia => _versiculoDelDia;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSearching => _isSearching;
  bool get busquedaRealizada => _busquedaRealizada;
  String get ultimaConsulta => _ultimaConsulta;
  List<Map<String, dynamic>> get resultadosBusqueda => _resultadosBusqueda;
  String? get searchErrorMessage => _searchErrorMessage;

  /// Retorna si una versión pertenece al conjunto de versiones en inglés
  static bool esVersionIngles(String version) {
    return versionesIngles.containsKey(version);
  }

  // Nombres de los libros en español (Canon protestante + deuterocanónicos KJV)
  static const Map<int, String> _nombresLibrosEs = {
    1: 'Génesis',
    2: 'Éxodo',
    3: 'Levítico',
    4: 'Números',
    5: 'Deuteronomio',
    6: 'Josué',
    7: 'Jueces',
    8: 'Rut',
    9: '1 Samuel',
    10: '2 Samuel',
    11: '1 Reyes',
    12: '2 Reyes',
    13: '1 Crónicas',
    14: '2 Crónicas',
    15: 'Esdras',
    16: 'Nehemías',
    17: 'Ester',
    18: 'Job',
    19: 'Salmos',
    20: 'Proverbios',
    21: 'Eclesiastés',
    22: 'Cantares',
    23: 'Isaías',
    24: 'Jeremías',
    25: 'Lamentaciones',
    26: 'Ezequiel',
    27: 'Daniel',
    28: 'Oseas',
    29: 'Joel',
    30: 'Amós',
    31: 'Abdías',
    32: 'Jonás',
    33: 'Miqueas',
    34: 'Nahúm',
    35: 'Habacuc',
    36: 'Sofonías',
    37: 'Hageo',
    38: 'Zacarías',
    39: 'Malaquías',
    40: 'Mateo',
    41: 'Marcos',
    42: 'Lucas',
    43: 'Juan',
    44: 'Hechos',
    45: 'Romanos',
    46: '1 Corintios',
    47: '2 Corintios',
    48: 'Gálatas',
    49: 'Efesios',
    50: 'Filipenses',
    51: 'Colosenses',
    52: '1 Tesalonicenses',
    53: '2 Tesalonicenses',
    54: '1 Timoteo',
    55: '2 Timoteo',
    56: 'Tito',
    57: 'Filemón',
    58: 'Hebreos',
    59: 'Santiago',
    60: '1 Pedro',
    61: '2 Pedro',
    62: '1 Juan',
    63: '2 Juan',
    64: '3 Juan',
    65: 'Judas',
    66: 'Apocalipsis',
    67: '1 Esdras',
    68: 'Tobías',
    69: 'Judit',
    70: 'Sabiduría',
    71: 'Eclesiástico',
    72: 'Baruc',
    73: 'Carta de Jeremías',
    74: '1 Macabeos',
    75: '2 Macabeos',
  };

  // Nombres de los libros en inglés (Canon protestante + deuterocanónicos KJV)
  static const Map<int, String> _nombresLibrosEn = {
    1: 'Genesis',
    2: 'Exodus',
    3: 'Leviticus',
    4: 'Numbers',
    5: 'Deuteronomy',
    6: 'Joshua',
    7: 'Judges',
    8: 'Ruth',
    9: '1 Samuel',
    10: '2 Samuel',
    11: '1 Kings',
    12: '2 Kings',
    13: '1 Chronicles',
    14: '2 Chronicles',
    15: 'Ezra',
    16: 'Nehemiah',
    17: 'Esther',
    18: 'Job',
    19: 'Psalms',
    20: 'Proverbs',
    21: 'Ecclesiastes',
    22: 'Song of Solomon',
    23: 'Isaiah',
    24: 'Jeremiah',
    25: 'Lamentations',
    26: 'Ezekiel',
    27: 'Daniel',
    28: 'Hosea',
    29: 'Joel',
    30: 'Amos',
    31: 'Obadiah',
    32: 'Jonah',
    33: 'Micah',
    34: 'Nahum',
    35: 'Habakkuk',
    36: 'Zephaniah',
    37: 'Haggai',
    38: 'Zechariah',
    39: 'Malachi',
    40: 'Matthew',
    41: 'Mark',
    42: 'Luke',
    43: 'John',
    44: 'Acts',
    45: 'Romans',
    46: '1 Corinthians',
    47: '2 Corinthians',
    48: 'Galatians',
    49: 'Ephesians',
    50: 'Philippians',
    51: 'Colossians',
    52: '1 Thessalonians',
    53: '2 Thessalonians',
    54: '1 Timothy',
    55: '2 Timothy',
    56: 'Titus',
    57: 'Philemon',
    58: 'Hebrews',
    59: 'James',
    60: '1 Peter',
    61: '2 Peter',
    62: '1 John',
    63: '2 Juan',
    64: '3 Juan',
    65: 'Jude',
    66: 'Revelation',
    67: '1 Esdras',
    68: 'Tobit',
    69: 'Judith',
    70: 'Wisdom',
    71: 'Sirach',
    72: 'Baruch',
    73: 'Epistle of Jeremiah',
    74: '1 Maccabees',
    75: '2 Maccabees',
  };

  BibliaProvider() {
    _cargarAjustesLectura();
    cargarVersiculoDelDia();
  }

  void actualizarModoLectura(ModoLectura modo) {
    _modoLectura = modo;
    _guardarAjustesLectura();
    notifyListeners();
  }

  void actualizarAjustesVisuales(double fontScale, String font) {
    _fontScale = fontScale;
    _selectedFont = font;
    _guardarAjustesLectura();
    notifyListeners();
  }

  Future<void> _cargarAjustesLectura() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontScale = prefs.getDouble('lectura_font_scale') ?? 1.0;
      _selectedFont = prefs.getString('lectura_selected_font') ?? 'Inter';
      final modoStr = prefs.getString('lectura_modo_lectura');
      if (modoStr != null) {
        _modoLectura = ModoLectura.values.firstWhere(
          (m) => m.name == modoStr,
          orElse: () => ModoLectura.calido,
        );
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _guardarAjustesLectura() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lectura_font_scale', _fontScale);
      await prefs.setString('lectura_selected_font', _selectedFont);
      await prefs.setString('lectura_modo_lectura', _modoLectura.name);
    } catch (_) {}
  }

  /// Sincroniza la versión bíblica activa según el idioma seleccionado por el usuario ('es' o 'en')
  Future<void> sincronizarIdioma(
    String idiomaCodigo, {
    bool notificar = true,
  }) async {
    final bool esIngles = idiomaCodigo == 'en';
    final bool actualEsIngles = esVersionIngles(_versionActual);

    if (esIngles && !actualEsIngles) {
      _versionActual = 'KJV';
      if (notificar) {
        notifyListeners();
        await cargarVersiculoDelDia();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cargarVersiculoDelDia();
        });
      }
    } else if (!esIngles && actualEsIngles) {
      _versionActual = 'RV1960';
      if (notificar) {
        notifyListeners();
        await cargarVersiculoDelDia();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cargarVersiculoDelDia();
        });
      }
    }
  }

  Future<void> cambiarVersion(String nuevaVersion) async {
    if (_versionActual == nuevaVersion) return;
    _versionActual = nuevaVersion;
    notifyListeners();
    await cargarVersiculoDelDia();
  }

  Future<void> cargarVersiculoDelDia({bool notificarInicio = true}) async {
    _isLoading = true;
    _errorMessage = null;
    if (notificarInicio) {
      notifyListeners();
    }

    try {
      final Map<String, dynamic> data = await _bibleService.versiculoDelDia(
        _versionActual,
      );

      final Map<String, dynamic> versiculoLimpio = Map<String, dynamic>.from(
        data,
      );

      if (versiculoLimpio.containsKey('text')) {
        versiculoLimpio['text'] = BibleService.limpiarTextoVerso(
          versiculoLimpio['text'] as String?,
        );
      }

      _versiculoDelDia = versiculoLimpio;
    } catch (e) {
      _errorMessage = 'Error al conectar con la API';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ejecuta una búsqueda bíblica tomando en cuenta el idioma actual del usuario.
  /// Si el idioma es inglés ('en'), asegura una versión en inglés (KJV) y busca en inglés.
  /// Si el idioma es español ('es'), asegura una versión en español (RV1960) y busca en español.
  Future<void> ejecutarBusqueda(String query, {String? idiomaCodigo}) async {
    final queryLimpia = query.trim();
    if (queryLimpia.isEmpty) {
      limpiarBusqueda();
      return;
    }

    _isSearching = true;
    _busquedaRealizada = true;
    _ultimaConsulta = queryLimpia;
    _searchErrorMessage = null;
    notifyListeners();

    try {
      // 1. Determinar idioma preferido del usuario
      final String idiomaDestino = (idiomaCodigo == 'en') ? 'en' : 'es';

      // 2. Alinear la versión bíblica activa al idioma actual si no coincide
      if (idiomaDestino == 'en' && !esVersionIngles(_versionActual)) {
        _versionActual = 'KJV';
      } else if (idiomaDestino == 'es' && esVersionIngles(_versionActual)) {
        _versionActual = 'RV1960';
      }

      // 3. Traducir la consulta si fue ingresada en otro idioma (ej: "necio" -> "fool" para inglés)
      final String queryTraducida = await BibleService.traducirConsulta(
        query: queryLimpia,
        idiomaDestino: idiomaDestino,
      );

      // 4. Buscar en la versión correspondiente
      List<Map<String, dynamic>> resultados = await _bibleService.buscar(
        _versionActual,
        queryTraducida,
      );

      // 5. Fallback con la consulta original si no hubo resultados y diferían
      if (resultados.isEmpty &&
          queryTraducida.toLowerCase() != queryLimpia.toLowerCase()) {
        final resultadosOriginales = await _bibleService.buscar(
          _versionActual,
          queryLimpia,
        );
        if (resultadosOriginales.isNotEmpty) {
          resultados = resultadosOriginales;
        }
      }

      _resultadosBusqueda = resultados;
    } catch (e) {
      _searchErrorMessage =
          'No se pudo completar la búsqueda. Verifica tu conexión a internet.';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void limpiarBusqueda({bool notificar = true}) {
    _resultadosBusqueda = [];
    _searchErrorMessage = null;
    _isSearching = false;
    _busquedaRealizada = false;
    _ultimaConsulta = '';
    if (notificar) {
      notifyListeners();
    }
  }

  /// Retorna el nombre del libro en el idioma indicado o según la versión activa
  String obtenerNombreLibro(int bookId, {String? idiomaCodigo}) {
    final bool enIngles = (idiomaCodigo != null)
        ? (idiomaCodigo == 'en')
        : esVersionIngles(_versionActual);

    if (enIngles) {
      return _nombresLibrosEn[bookId] ??
          _nombresLibrosEs[bookId] ??
          'Book $bookId';
    }
    return _nombresLibrosEs[bookId] ??
        _nombresLibrosEn[bookId] ??
        'Libro $bookId';
  }

  String obtenerReferenciaFormateada({String? idiomaCodigo}) {
    if (_versiculoDelDia == null) return '';
    final int bookId = _versiculoDelDia!['book'];
    final String bookName = obtenerNombreLibro(
      bookId,
      idiomaCodigo: idiomaCodigo,
    );
    return '$bookName ${_versiculoDelDia!['chapter']}:${_versiculoDelDia!['verse']}';
  }
}
