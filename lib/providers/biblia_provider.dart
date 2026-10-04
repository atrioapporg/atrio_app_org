import 'package:atrio/servicios/bible_service.dart';
import 'package:flutter/material.dart';

//
class BibliaProvider with ChangeNotifier {
  final BibleService _bibleService = BibleService();

  // Versiones disponibles en Bolls Life
  final Map<String, String> _versionesDisponibles = {
    'RV1960': 'Reina-Valera 1960',
    'RV2000': 'Reina Valera 2000',
    'NVI': 'Nueva Versión Internacional',
    'KJV': 'King James Version',
  };

  String _versionActual = 'RV1960';
  Map<String, dynamic>? _versiculoDelDia;
  bool _isLoading = true;
  String? _errorMessage;

  // Estado para la búsqueda
  bool _isSearching = false;
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
  List<Map<String, dynamic>> get resultadosBusqueda => _resultadosBusqueda;
  String? get searchErrorMessage => _searchErrorMessage;

  final Map<int, String> _nombresLibros = {
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
  };

  BibliaProvider() {
    cargarVersiculoDelDia();
  }

  Future<void> cambiarVersion(String nuevaVersion) async {
    if (_versionActual == nuevaVersion) return;
    _versionActual = nuevaVersion;
    notifyListeners();
    await cargarVersiculoDelDia();
  }

  Future<void> cargarVersiculoDelDia() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> data = await _bibleService.versiculoDelDia(
        _versionActual,
      );

      // Creamos una copia mutable y limpiamos el texto
      final Map<String, dynamic> versiculoLimpio = Map<String, dynamic>.from(
        data,
      );

      if (versiculoLimpio.containsKey('text')) {
        versiculoLimpio['text'] = _limpiarTextoHtml(
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

  //
  String _limpiarTextoHtml(String? texto) {
    if (texto == null || texto.isEmpty) return '';

    String resultado = texto;

    // 1. Reemplazar saltos de línea HTML por saltos reales o espacios
    resultado = resultado.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );

    // 2. Eliminar cualquier otra etiqueta HTML (ej: <i>, </i>, <b>, <span>, etc.)
    resultado = resultado.replaceAll(RegExp(r'<[^>]*>'), '');

    // 3. Decodificar entidades HTML comunes
    resultado = resultado
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ');

    // 4. Limpiar espacios redundantes preservando saltos de línea limpios
    resultado = resultado
        .split('\n')
        .map((linea) => linea.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((linea) => linea.isNotEmpty)
        .join('\n');

    return resultado.trim();
  }
  //

  Future<void> ejecutarBusqueda(String query) async {
    if (query.trim().isEmpty) {
      limpiarBusqueda();
      return;
    }

    _isSearching = true;
    _searchErrorMessage = null;
    notifyListeners();

    try {
      _resultadosBusqueda = await _bibleService.buscar(_versionActual, query);
    } catch (e) {
      _searchErrorMessage = 'No se pudo completar la búsqueda';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void limpiarBusqueda() {
    _resultadosBusqueda = [];
    _searchErrorMessage = null;
    _isSearching = false;
    notifyListeners();
  }

  String obtenerNombreLibro(int bookId) {
    return _nombresLibros[bookId] ?? 'Libro $bookId';
  }
  //

  String obtenerReferenciaFormateada() {
    if (_versiculoDelDia == null) return '';
    final int bookId = _versiculoDelDia!['book'];
    final String bookName = obtenerNombreLibro(bookId);
    return '$bookName ${_versiculoDelDia!['chapter']}:${_versiculoDelDia!['verse']}';
  }
}
