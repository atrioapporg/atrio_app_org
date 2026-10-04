import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/proyecto_solidario_model.dart';

class ProyectoSolidarioProvider extends ChangeNotifier {
  ProyectosSolidariosData? _data;
  bool _isLoading = false;
  String? _errorMessage;

  ProyectosSolidariosData? get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarProyectos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    //

    try {
      await Future.delayed(const Duration(milliseconds: 700));
      final String jsonString = await rootBundle.loadString(
        'assets/json/proyectos_solidarios.json',
      );
      final Map<String, dynamic> jsonMap =
          jsonDecode(jsonString) as Map<String, dynamic>;
      _data = ProyectosSolidariosData.fromJson(jsonMap);
    } catch (e) {
      _errorMessage = 'Error al cargar proyectos solidarios: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
