import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/tradicion_cristiana_model.dart';

class TradicionCristianaProvider extends ChangeNotifier {
  List<TradicionCristianaModel> _tradiciones = [];
  TradicionCristianaModel? _tradicionSeleccionada;
  IglesiaAfiliadaModel? _iglesiaPertenencia;

  bool _isLoading = false;
  String? _errorMessage;

  List<TradicionCristianaModel> get tradiciones => _tradiciones;
  TradicionCristianaModel? get tradicionSeleccionada => _tradicionSeleccionada;
  IglesiaAfiliadaModel? get iglesiaPertenencia => _iglesiaPertenencia;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarTradiciones() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/json/tradiciones_cristianas.json',
      );
      final Map<String, dynamic> jsonMap =
          jsonDecode(jsonString) as Map<String, dynamic>;
      final response = TradicionesResponseModel.fromJson(jsonMap);
      _tradiciones = response.tradiciones;
    } catch (e) {
      _errorMessage = 'Error al cargar las tradiciones: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void seleccionarTradicion(TradicionCristianaModel tradicion) {
    _tradicionSeleccionada = tradicion;
    // Si la tradición cambia y no contiene la iglesia actual, reiniciamos la pertenencia
    if (_iglesiaPertenencia != null &&
        !tradicion.iglesias.any((i) => i.id == _iglesiaPertenencia!.id)) {
      _iglesiaPertenencia = null;
    }
    notifyListeners();
  }

  void seleccionarTradicionPorIndice(int index) {
    if (index >= 0 && index < _tradiciones.length) {
      seleccionarTradicion(_tradiciones[index]);
    }
  }

  void asignarIglesiaMembresia(IglesiaAfiliadaModel iglesia) {
    _iglesiaPertenencia = iglesia;
    notifyListeners();
  }

  /// Índice de denominación compatible con el filtro de [ExplorarProvider] y [SeleccionarIglesiaScreen]:
  /// 0: Todas, 1: Católica, 2: Evangélica, 3: Pentecostal, 4: Bautista, 5: Adventista
  int get denominacionFiltroIndex {
    if (_tradicionSeleccionada == null) return 0;
    final combinado =
        '${_tradicionSeleccionada!.id} ${_tradicionSeleccionada!.titulo}'
            .toLowerCase();
    if (combinado.contains('catolica') || combinado.contains('católica')) {
      return 1;
    }
    if (combinado.contains('evangelica') || combinado.contains('evangélica')) {
      return 2;
    }
    if (combinado.contains('pentecostal')) return 3;
    if (combinado.contains('bautista')) return 4;
    if (combinado.contains('adventista')) return 5;
    return 0;
  }

  void seleccionarTradicionPorId(String id) {
    final index = _tradiciones.indexWhere((t) => t.id == id);
    if (index != -1) {
      seleccionarTradicion(_tradiciones[index]);
    }
  }

  void limpiarSeleccion() {
    _tradicionSeleccionada = null;
    _iglesiaPertenencia = null;
    notifyListeners();
  }
}
