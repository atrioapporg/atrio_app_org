import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atrio/atrio_api.dart';

/// Servicio encargado de gestionar el token de notificación del dispositivo
/// y sincronizarlo automáticamente con el backend Odoo 19 (endpoints /devices).
class DeviceNotificationService {
  DeviceNotificationService._internal();
  static final DeviceNotificationService instance =
      DeviceNotificationService._internal();

  static const String _prefKeyDeviceToken = 'atrio_device_push_token';
  static const String _prefKeyLastRegisteredToken =
      'atrio_last_registered_push_token';

  String? _cachedToken;

  /// Obtiene la plataforma actual en formato normalizado para Odoo ('android' o 'ios').
  String get platformName {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'android';
  }

  /// Obtiene o genera un token de dispositivo identificador.
  /// Cuando FirebaseMessaging esté inicializado con google-services,
  /// este método puede alimentar el FCM Token real.
  Future<String> getOrCreateDeviceToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_prefKeyDeviceToken);

    if (token == null || token.isEmpty) {
      // Genera un token identificador único persistente para este dispositivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (timestamp % 100000).toString().padLeft(5, '0');
      token = 'atrio_${platformName}_${timestamp}_$random';
      await prefs.setString(_prefKeyDeviceToken, token);
    }

    _cachedToken = token;
    return token;
  }

  /// Permite establecer directamente el FCM Token generado por Firebase Cloud Messaging.
  Future<void> setFcmToken(String fcmToken) async {
    _cachedToken = fcmToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyDeviceToken, fcmToken);
  }

  /// Registra el token del dispositivo en el backend Odoo (POST /devices).
  /// Se ejecuta automáticamente al iniciar sesión o al validar credenciales guardadas.
  Future<bool> registerDeviceWithBackend(
    AtrioApi api, {
    String? customToken,
  }) async {
    if (!api.isAuthenticated) {
      debugPrint(
        '⚠️ [DeviceNotificationService] No se puede registrar dispositivo: Usuario no autenticado en Odoo.',
      );
      return false;
    }

    try {
      final token = customToken ?? await getOrCreateDeviceToken();
      final prefs = await SharedPreferences.getInstance();
      final lastRegistered = prefs.getString(_prefKeyLastRegisteredToken);

      // Si ya está registrado con el mismo token en esta sesión, evitamos llamadas redundantes
      if (lastRegistered == token) {
        debugPrint(
          'ℹ️ [DeviceNotificationService] Dispositivo ya sincronizado con Odoo ($token).',
        );
        return true;
      }

      final payload = {
        'token': token,
        'platform': platformName,
        'device_name': 'ATRIO Mobile App (${platformName.toUpperCase()})',
      };

      debugPrint(
        '📡 [DeviceNotificationService] Registrando dispositivo en Odoo: $payload',
      );

      final res = await api
          .registerDevice(payload)
          .timeout(const Duration(seconds: 8));
      debugPrint(
        '✅ [DeviceNotificationService] Dispositivo registrado exitosamente: $res',
      );

      await prefs.setString(_prefKeyLastRegisteredToken, token);
      return true;
    } on AtrioApiException catch (e) {
      debugPrint(
        '❌ [DeviceNotificationService] Error de API Odoo registrando dispositivo: $e',
      );
      return false;
    } catch (e) {
      debugPrint(
        '❌ [DeviceNotificationService] Error inesperado registrando dispositivo: $e',
      );
      return false;
    }
  }

  /// Desregistra o marca como inactivo el token en Odoo (DELETE /devices) al cerrar sesión.
  Future<bool> unregisterDeviceFromBackend(AtrioApi api) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_prefKeyDeviceToken) ?? _cachedToken;

      if (token == null || token.isEmpty) {
        return true;
      }

      debugPrint(
        '📡 [DeviceNotificationService] Desregistrando dispositivo en Odoo: $token',
      );

      if (api.isAuthenticated) {
        await api.unregisterDevice({'token': token});
      }

      await prefs.remove(_prefKeyLastRegisteredToken);
      debugPrint(
        '✅ [DeviceNotificationService] Dispositivo desregistrado de Odoo.',
      );
      return true;
    } on AtrioApiException catch (e) {
      debugPrint(
        '⚠️ [DeviceNotificationService] Error de API desregistrando dispositivo: $e',
      );
      return false;
    } catch (e) {
      debugPrint(
        '⚠️ [DeviceNotificationService] Error inesperado desregistrando dispositivo: $e',
      );
      return false;
    }
  }
}
