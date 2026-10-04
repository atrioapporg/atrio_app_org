import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  String _tituloApp = "atrio Iglesia";

  String get tituloApp => _tituloApp;

  void cambiarTitulo(String nuevoTitulo) {
    _tituloApp = nuevoTitulo;
    notifyListeners(); // Avisa a las pantallas que algo cambió
  }
}
