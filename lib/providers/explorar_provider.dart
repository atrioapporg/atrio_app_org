import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/iglesia_explorar_model.dart';

class ExplorarProvider extends ChangeNotifier {
  //
  List<IglesiaExplorarModel> _todasLasIglesias = [];
  List<IglesiaExplorarModel> _iglesiasFiltradas = [];

  bool _isLoading = false;
  String? _errorMessage;

  String _busquedaActual = '';
  int _filtroSeleccionadoIndex = 0;

  // --- Getters públicos ---
  List<IglesiaExplorarModel> get iglesiasFiltradas => _iglesiasFiltradas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get filtroSeleccionadoIndex => _filtroSeleccionadoIndex;
  String get busquedaActual => _busquedaActual;
  //
  //

  Future<void> cargarIglesias() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600)); // Simula red
      final String jsonString = await rootBundle.loadString(
        'assets/json/explorar_iglesias.json',
      );
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      _todasLasIglesias = (jsonMap['iglesias_sugeridas'] as List<dynamic>)
          .map((item) => IglesiaExplorarModel.fromJson(item))
          .toList();

      _aplicarFiltrosCombinados();
    } catch (e) {
      _errorMessage = 'Error al cargar el directorio: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void buscarPorTexto(String query) {
    _busquedaActual = query.toLowerCase();
    _aplicarFiltrosCombinados();
  }

  void seleccionarFiltro(int index) {
    _filtroSeleccionadoIndex = index;
    _aplicarFiltrosCombinados();
  }

  void _aplicarFiltrosCombinados() {
    List<IglesiaExplorarModel> resultado = List.from(_todasLasIglesias);

    // 1. Aplicar búsqueda por texto (Nombre o Denominación)
    if (_busquedaActual.isNotEmpty) {
      resultado = resultado.where((iglesia) {
        return iglesia.nombre.toLowerCase().contains(_busquedaActual) ||
            iglesia.denominacion.toLowerCase().contains(_busquedaActual);
      }).toList();
    }

    // 2. Aplicar filtro de categoría (Pastillas)
    switch (_filtroSeleccionadoIndex) {
      case 1: // Cerca de mí (Menos de 4 km)
        resultado = resultado.where((i) => i.distanciaKm <= 4.0).toList();
        resultado.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));
        break;
      case 2: // Evangélicas
        resultado = resultado
            .where((i) => i.denominacion.toLowerCase().contains('evangélica'))
            .toList();
        break;
      case 3: // Bautistas
        resultado = resultado
            .where((i) => i.denominacion.toLowerCase().contains('bautista'))
            .toList();
        break;
      case 4: // Pentecostales
        resultado = resultado
            .where((i) => i.denominacion.toLowerCase().contains('pentecostal'))
            .toList();
        break;
      case 0: // Todas
      default:
        break;
    }

    _iglesiasFiltradas = resultado;
    _isLoading = false;
    notifyListeners();
  }
}
