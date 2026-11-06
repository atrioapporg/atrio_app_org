import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Modelo de datos para notificaciones de la Palabra/Oración del día.
class DailyVerseNotificationItem {
  final int dayOffset; // 0 = hoy, 1 = mañana, etc.
  final String title;
  final String reference;
  final String body;
  final String bookId;
  final int chapter;
  final int verse;

  const DailyVerseNotificationItem({
    required this.dayOffset,
    required this.title,
    required this.reference,
    required this.body,
    required this.bookId,
    required this.chapter,
    required this.verse,
  });

  String toPayload() => jsonEncode({
        'type': 'daily_verse',
        'bookId': bookId,
        'chapter': chapter,
        'verse': verse,
        'reference': reference,
      });
}

/// Callback top-level obligatorio para procesar acciones de notificación en background
@pragma('vm:entry-point')
void dailyVerseNotificationTapBackground(NotificationResponse response) {
  debugPrint(
    '🔔 [DailyVerseNotification:Background] Acción: ${response.actionId} | Payload: ${response.payload}',
  );
}

/// Servicio encargado de la inicialización, programación recurrente y despliegue
/// de la Palabra y Oración del Día en la bandeja del sistema (System Tray) y Lock Screen.
class DailyVerseNotificationService {
  DailyVerseNotificationService._internal();
  static final DailyVerseNotificationService instance =
      DailyVerseNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'atrio_daily_word_channel';
  static const int baseNotificationId = 7000;

  bool _isInitialized = false;
  void Function(Map<String, dynamic> payloadData)? _onSelectPayload;

  /// 1. Inicialización del plugin, huso horario y canales de alta prioridad
  Future<void> initialize({
    required String channelName,
    required String channelDescription,
    required void Function(Map<String, dynamic> payloadData) onSelectPayload,
  }) async {
    _onSelectPayload = onSelectPayload;
    if (_isInitialized) return;

    // Configuración de Timezones en Dart puro (sin plugins nativos conflictivos con Kotlin/Gradle)
    tz.initializeTimeZones();
    _configureLocalTimeZone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          dailyVerseNotificationTapBackground,
    );

    // Creación explícita del canal con Importance.max en Android 8.0+
    if (!kIsWeb && Platform.isAndroid) {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }
    }

    // Verificar si la aplicación se abrió desde una notificación estando cerrada
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse != null) {
      _handleNotificationResponse(launchDetails.notificationResponse!);
    }

    _isInitialized = true;
  }

  /// 2. Solicitud de permisos en tiempo de ejecución (POST_NOTIFICATIONS, Exact Alarm, iOS)
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl == null) return false;

      final bool? notifGranted =
          await androidImpl.requestNotificationsPermission();

      // Android 12+ (API 31+): Verificar si requiere permiso de alarmas exactas
      final bool? canScheduleExact =
          await androidImpl.canScheduleExactNotifications();
      if (canScheduleExact == false) {
        await androidImpl.requestExactAlarmsPermission();
      }

      return notifGranted ?? false;
    }

    if (Platform.isIOS) {
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final bool? granted = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  /// 3. Programación matutina recurrente con BigTextStyleInformation y botón de acción
  Future<void> scheduleDailyMorningVerse({
    required DailyVerseNotificationItem item,
    required String channelName,
    required String channelDescription,
    required String actionAmenLabel,
    int hour = 7,
    int minute = 0,
  }) async {
    final bigTextStyle = BigTextStyleInformation(
      '${item.body}\n\n📖 ${item.reference}',
      htmlFormatBigText: false,
      contentTitle: '☀️ ${item.title}',
      htmlFormatContentTitle: false,
      summaryText: item.reference,
      htmlFormatSummaryText: false,
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigTextStyle,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      icon: 'ic_stat_atrio',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFF072B4F), // Azul institucional ATRIO
      colorized: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'amen_action',
          actionAmenLabel,
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    AndroidScheduleMode scheduleMode =
        AndroidScheduleMode.exactAllowWhileIdle;
    if (!kIsWeb && Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final bool? canExact =
          await androidImpl?.canScheduleExactNotifications();
      if (canExact == false) {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }

    final scheduledDate = _nextInstanceOfTime(
      hour: hour,
      minute: minute,
      dayOffset: item.dayOffset,
    );

    await _plugin.zonedSchedule(
      baseNotificationId + item.dayOffset,
      item.title,
      item.body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          item.dayOffset == 0 ? DateTimeComponents.time : null,
      payload: item.toPayload(),
    );
  }

  /// Cancela todas las notificaciones programadas
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Dispara una notificación de prueba instantánea (o con retraso de [delaySeconds] segundos)
  /// para validar el diseño visual exacto, botón "Amén ›" y navegación sin esperar a las 7:00 AM.
  Future<void> showTestNotificationImmediately({
    required DailyVerseNotificationItem item,
    required String channelName,
    required String channelDescription,
    required String actionAmenLabel,
    int delaySeconds = 3,
  }) async {
    final bigTextStyle = BigTextStyleInformation(
      '${item.body}\n\n📖 ${item.reference}',
      htmlFormatBigText: false,
      contentTitle: '☀️ ${item.title}',
      htmlFormatContentTitle: false,
      summaryText: item.reference,
      htmlFormatSummaryText: false,
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigTextStyle,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      icon: 'ic_stat_atrio',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFF072B4F),
      colorized: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'amen_action',
          actionAmenLabel,
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (delaySeconds <= 0) {
      await _plugin.show(
        9999,
        item.title,
        item.body,
        notificationDetails,
        payload: item.toPayload(),
      );
    } else {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));
      await _plugin.zonedSchedule(
        9999,
        item.title,
        item.body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: item.toPayload(),
      );
    }
  }

  /// Calcula la próxima instancia de la hora configurada
  tz.TZDateTime _nextInstanceOfTime({
    required int hour,
    required int minute,
    int dayOffset = 0,
  }) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate.add(Duration(days: dayOffset));
  }

  /// Resuelve el huso horario local del dispositivo en Dart puro a partir de su UTC offset,
  /// priorizando los mercados principales de ATRIO (República Dominicana UTC-4 y Honduras UTC-6).
  void _configureLocalTimeZone() {
    try {
      final Duration offset = DateTime.now().timeZoneOffset;
      if (offset.inHours == -4) {
        tz.setLocalLocation(tz.getLocation('America/Santo_Domingo'));
        return;
      }
      if (offset.inHours == -6) {
        tz.setLocalLocation(tz.getLocation('America/Tegucigalpa'));
        return;
      }
      final int offsetMs = offset.inMilliseconds;
      for (final location in tz.timeZoneDatabase.locations.values) {
        if (location.currentTimeZone.offset == offsetMs) {
          tz.setLocalLocation(location);
          return;
        }
      }
      tz.setLocalLocation(tz.getLocation('America/Santo_Domingo'));
    } catch (_) {}
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final String? rawPayload = response.payload;
    if (rawPayload == null || rawPayload.isEmpty) return;

    try {
      final Map<String, dynamic> data =
          jsonDecode(rawPayload) as Map<String, dynamic>;
      _onSelectPayload?.call(data);
    } catch (e) {
      debugPrint('⚠️ Error al parsear payload de notificación local: $e');
    }
  }
}

