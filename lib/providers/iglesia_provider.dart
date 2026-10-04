import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- Importante

import '../modelos/iglesia_model.dart';

//

class IglesiaProvider extends ChangeNotifier {
  //
  bool _tieneIglesiaGuardada = false;
  bool get tieneIglesiaGuardada => _tieneIglesiaGuardada;

  IglesiaModel? _iglesiaActual;
  bool _isLoading = false;
  String? _errorMessage;

  IglesiaModel? get iglesiaActual => _iglesiaActual;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- NUEVO MÉTODO PARA GUARDAR ---
  Future<void> guardarIglesiaLocal(String jsonString) async {
    try {
      //
      _tieneIglesiaGuardada = true; // <--- AGREGA ESTA LÍNEA AQUÍ
      // Obtenemos la instancia del almacenamiento local[cite: 5]
      final prefs = await SharedPreferences.getInstance();

      // Guardamos el JSON bajo la llave 'iglesia_guardada'
      await prefs.setString('iglesia_guardada', jsonString);

      // Actualizamos la variable en memoria y notificamos a la pantalla
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      _iglesiaActual = IglesiaModel.fromJson(jsonMap);
      //
      notifyListeners();
    } catch (e) {
      debugPrint('Error al guardar la iglesia: $e');
    }
  }

  // --- MÉTODO DE CARGA MODIFICADO ---
  Future<void> cargarIglesiaSeleccionada() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Retardo visual corto

      final prefs = await SharedPreferences.getInstance();
      final String? jsonGuardado = prefs.getString('iglesia_guardada');

      //-----------
      if (jsonGuardado != null && jsonGuardado.isNotEmpty) {
        _tieneIglesiaGuardada = true; // <--- AGREGA ESTA LÍNEA
        final Map<String, dynamic> jsonMap =
            jsonDecode(jsonGuardado) as Map<String, dynamic>;
        _iglesiaActual = IglesiaModel.fromJson(jsonMap);
      } else {
        _tieneIglesiaGuardada = false; // <--- AGREGA ESTA LÍNEA
        final String jsonString = await rootBundle.loadString(
          'assets/json/iglesia.json',
        );
        final Map<String, dynamic> jsonMap =
            jsonDecode(jsonString) as Map<String, dynamic>;
        _iglesiaActual = IglesiaModel.fromJson(jsonMap);
      }
      //---------------
    } catch (error) {
      _errorMessage = 'Error al cargar la información de la iglesia: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //
  // --- NUEVA FUNCIÓN DE VERIFICACIÓN ---
  Future<bool> verificarIglesiaGuardada() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonGuardado = prefs.getString('iglesia_guardada');

      // Si existe y no está vacío, actualiza la variable a true
      _tieneIglesiaGuardada = jsonGuardado != null && jsonGuardado.isNotEmpty;
      notifyListeners();

      return _tieneIglesiaGuardada;
    } catch (e) {
      debugPrint('Error al verificar SharedPreferences: $e');
      return false;
    }
  }
  //
}
