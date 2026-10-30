import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';

/// Handler de ejecución en segundo plano para notificaciones Firebase Cloud Messaging.
/// Debe ser una función top-level declarada con @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint(
    '🔔 [DeviceNotificationService:Background] Push recibido: ID=${message.messageId} | Data=${message.data}',
  );
}

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
  bool _isFCMInitialized = false;

  /// Obtiene la plataforma actual en formato normalizado para Odoo ('android' o 'ios').
  String get platformName {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'android';
  }

  /// Inicializa Firebase Cloud Messaging (FCM) y configura los listeners de notificaciones.
  /// Se ejecuta de forma resiliente: si los archivos nativos de Firebase aún no están presentes,
  /// captura la excepción sin interrumpir el arranque normal de la app.
  Future<void> initialize({
    AtrioApi? api,
    UserProvider? userProvider,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    if (_isFCMInitialized) return;

    try {
      // 1. Asegurar inicialización de Firebase Core
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint(
          'ℹ️ [DeviceNotificationService] Firebase Core no inicializado o usando fallback: $e',
        );
      }

      final messaging = FirebaseMessaging.instance;

      // 2. Registrar el handler de background
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Solicitar permisos de notificación (Android 13+ y iOS)
      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        '🔔 [DeviceNotificationService] Permisos de notificación concedidos: ${settings.authorizationStatus}',
      );

      // 4. Escuchar registro y rotación de tokens FCM (API estándar firebase_messaging v17+)
      messaging.onRegistered.listen((token) async {
        debugPrint('🔑 [DeviceNotificationService] FCM Token registrado: $token');
        await setFcmToken(token);
        if (api != null && api.isAuthenticated) {
          await registerDeviceWithBackend(api, customToken: token);
        }
      });

      // 5. Registrar la aplicación con Firebase Cloud Messaging
      try {
        await messaging.register();
      } catch (regErr) {
        debugPrint(
          'ℹ️ [DeviceNotificationService] Registro en FCM completado o en espera: $regErr',
        );
      }

      // Fallback para obtener token de inmediato si ya está emitido
      try {
        // ignore: deprecated_member_use
        final fcmToken = await messaging.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await setFcmToken(fcmToken);
          if (api != null && api.isAuthenticated) {
            await registerDeviceWithBackend(api, customToken: fcmToken);
          }
        }
      } catch (_) {}

      // 6. Notificaciones recibidas en PRIMER PLANO (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '🔔 [DeviceNotificationService:Foreground] Notificación recibida: ${message.notification?.title} | ${message.notification?.body} | Data: ${message.data}',
        );
        handlePushMessage(
          message.data,
          userProvider: userProvider,
          navigatorKey: navigatorKey,
        );
      });

      // 7. Notificación pulsada cuando la app estaba en SEGUNDO PLANO
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          '🔔 [DeviceNotificationService:OpenedApp] App abierta desde notificación: ${message.data}',
        );
        handlePushMessage(
          message.data,
          userProvider: userProvider,
          navigatorKey: navigatorKey,
        );
      });

      // 8. Notificación que abrió la app cuando estaba COMPLETAMENTE CERRADA
      messaging.getInitialMessage().then((RemoteMessage? initialMessage) {
        if (initialMessage != null) {
          debugPrint(
            '🔔 [DeviceNotificationService:InitialMessage] App iniciada por clic en push: ${initialMessage.data}',
          );
          handlePushMessage(
            initialMessage.data,
            userProvider: userProvider,
            navigatorKey: navigatorKey,
          );
        }
      });

      _isFCMInitialized = true;
      debugPrint('✅ [DeviceNotificationService] Firebase Cloud Messaging inicializado exitosamente.');
    } catch (e) {
      debugPrint(
        '⚠️ [DeviceNotificationService] Inicialización de FCM en espera de credenciales nativas completas: $e',
      );
    }
  }

  /// Obtiene o genera un token de dispositivo identificador.
  /// Si FCM ya generó un token real, lo devuelve prioritariamente.
  Future<String> getOrCreateDeviceToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_prefKeyDeviceToken);

    if (token == null || token.isEmpty) {
      // Intenta obtenerlo de Firebase si está disponible
      try {
        // ignore: deprecated_member_use
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          token = fcmToken;
          await prefs.setString(_prefKeyDeviceToken, token);
        }
      } catch (_) {}

      // Si aún no está disponible FCM, genera un identificador temporal para no bloquear el flujo
      if (token == null || token.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final random = (timestamp % 100000).toString().padLeft(5, '0');
        token = 'atrio_${platformName}_${timestamp}_$random';
        await prefs.setString(_prefKeyDeviceToken, token);
      }
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

  /// Procesa los datos recibidos en una notificación push de Odoo 19.
  /// Cuando `type == 'membership'` y `status == 'approved'`:
  /// 1. Sincroniza inmediatamente el perfil del usuario llamando a `refreshUserProfile()`.
  /// 2. Navega dinámicamente a `InicioAtrioScreen`.
  Future<void> handlePushMessage(
    Map<String, dynamic> data, {
    UserProvider? userProvider,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    final type = data['type'] as String?;
    final status = data['status'] as String?;
    final churchName = data['church_name'] as String? ?? 'tu congregación';

    if (type == 'membership' || type == 'church') {
      if (status == 'approved') {
        debugPrint(
          '🔔 [DeviceNotificationService] Notificación de membresía aprobada recibida. Actualizando perfil...',
        );
        if (userProvider != null) {
          try {
            await userProvider.refreshUserProfile();
            userProvider.notifyChurchStatusChanged(
              status: 'approved',
              churchName: userProvider.currentUser?.iglesiaActual ?? churchName,
              isApproved: true,
            );
          } catch (e) {
            debugPrint(
              '⚠️ [DeviceNotificationService] Error refrescando perfil tras push: $e',
            );
          }
        }
        final navState = navigatorKey?.currentState;
        if (navState != null) {
          navState.pushNamedAndRemoveUntil(
            InicioAtrioScreen.routeName,
            (route) => false,
          );
        }
      } else if (status != null && status.isNotEmpty) {
        debugPrint(
          '🔔 [DeviceNotificationService] Notificación de cambio de estado de congregación ($status). Actualizando...',
        );
        if (userProvider != null) {
          try {
            await userProvider.refreshUserProfile();
            userProvider.notifyChurchStatusChanged(
              status: status,
              churchName: userProvider.currentUser?.iglesiaActual ?? churchName,
              isApproved: status == 'approved',
            );
          } catch (e) {
            debugPrint(
              '⚠️ [DeviceNotificationService] Error refrescando perfil tras push: $e',
            );
          }
        }
      }
    }
  }
}
