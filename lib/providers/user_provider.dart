import 'dart:convert';

import 'package:atrio/modelos/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Función para simular una petición a la API (o leer el archivo falso)
  Future<void> loadFakeUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Avisamos a la UI que empezamos a cargar

    try {
      // 1. Simulamos la latencia de una red (1.5 segundos)
      await Future.delayed(const Duration(milliseconds: 1500));

      // 2. Cargamos el archivo JSON local desde los assets crudos
      final String jsonString = await rootBundle.loadString(
        'assets/json/perfil.json',
      );

      // 3. Decodificamos el String a un Map
      final Map<String, dynamic> jsonMap =
          jsonDecode(jsonString) as Map<String, dynamic>;

      // 4. Instanciamos el objeto estructurado
      _currentUser = UserModel.fromJson(jsonMap);
    } catch (error) {
      _errorMessage = 'Error al cargar datos de perfil: $error';
    } finally {
      _isLoading = false;
      notifyListeners(); // Avisamos a la UI que hemos terminado (éxito o fallo)
    }
  }

  //
  // Método para actualizar los datos locales en memoria
  void updateUserProfile({
    required String nombre,
    required String email,
    required String telefono,
    required String iglesiaActual,
  }) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        nombre: nombre,
        email: email,
        telefono: telefono.isNotEmpty ? telefono : null,
        iglesiaActual: iglesiaActual,
        fechaRegistro: _currentUser!.fechaRegistro,
        avatarIniciales: nombre.isNotEmpty
            ? nombre.trim()[0].toUpperCase()
            : 'U',
        esMiembroVerificado: _currentUser!.esMiembroVerificado,
        estadisticas: _currentUser!.estadisticas,
      );
      notifyListeners(); // Actualiza automáticamente la cabecera y campos de PerfilScreen
    }
  }

  // Método temporal para limpiar la sesión (Logout local)
  //
  void clearSession() {
    _currentUser = null;
    notifyListeners();
  }
}
