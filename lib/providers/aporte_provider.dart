import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/aporte_model.dart';

class AporteProvider extends ChangeNotifier {
  AporteConfigModel? _configuracion;
  bool _isLoading = false;
  String? _errorMessage;

  AporteConfigModel? get configuracion => _configuracion;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarConfiguracion() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    //

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final String jsonString = await rootBundle.loadString(
        'assets/json/aporte.json',
      );
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      _configuracion = AporteConfigModel.fromJson(jsonMap);
    } catch (e) {
      _errorMessage = 'Error al cargar configuración: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
