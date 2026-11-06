import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Modelo de datos para notificaciones de la Palabra/Oración del día.
class DailyVerseNotificationItem {
  final String title;
  final String reference;
  final String body;

  /// ID numérico del libro (canon protestante 1-66, Génesis = 1, Filipenses = 50).
  final int bookId;

  /// Nombre localizado del libro (ej. "Filipenses" / "Philippians").
  final String bookName;
  final int totalChapters;
  final int chapter;
  final int verse;
  final int? verseEnd;

  const DailyVerseNotificationItem({
    required this.title,
    required this.reference,
    required this.body,
    required this.bookId,
    required this.bookName,
    required this.totalChapters,
    required this.chapter,
    required this.verse,
    this.verseEnd,
  });

  String toPayload() => jsonEncode({
        'type': 'daily_verse',
        'bookId': bookId,
        'bookName': bookName,
        'totalChapters': totalChapters,
        'chapter': chapter,
        'verse': verse,
        'verseEnd': verseEnd,
        'reference': reference,
        'body': body,
      });
}

/// Callback top-level obligatorio para procesar acciones de notificación en background
@pragma('vm:entry-point')
void dailyVerseNotificationTapBackground(NotificationResponse response) {
  debugPrint(
    '🔔 [DailyVerseNotification:Background] Acción: ${response.actionId} | Payload: ${response.payload}',
  );
}

/// Servicio encargado de la inicialización, programación y despliegue
/// de la Palabra y Oración del Día en la bandeja del sistema (System Tray) y Lock Screen.
///
/// Estrategia: en lugar de una notificación repetitiva (`matchDateTimeComponents`),
/// que mostraría siempre el mismo texto, se programa un **lote de notificaciones
/// únicas** (una por día, cada una con su propio contenido e ID). El lote se
/// reprograma completo cada vez que se abre/reanuda la app o cambian los ajustes,
/// de modo que siempre quedan [maxBatchDays] días cubiertos por delante.
class DailyVerseNotificationService {
  DailyVerseNotificationService._internal();
  static final DailyVerseNotificationService instance =
      DailyVerseNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'atrio_daily_word_channel';
  static const int baseNotificationId = 7000;

  /// Días cubiertos por lote. iOS limita a 64 notificaciones pendientes por app,
  /// por lo que se mantiene muy por debajo para no competir con otros avisos.
  static const int maxBatchDays = 14;

  static const int _testNotificationId = 9999;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
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

  /// 2. Solicitud de permisos en tiempo de ejecución (POST_NOTIFICATIONS, iOS).
  ///
  /// [requestExactAlarm]: en Android 12+ abre la pantalla de Ajustes del sistema
  /// para conceder "Alarmas y recordatorios". Por defecto es `false` para no
  /// sacar al usuario de la app en cada arranque; sin ese permiso las
  /// notificaciones se programan en modo inexacto (pueden llegar unos minutos tarde).
  Future<bool> requestPermissions({bool requestExactAlarm = false}) async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl == null) return false;

      final bool? notifGranted =
          await androidImpl.requestNotificationsPermission();

      if (requestExactAlarm) {
        final bool? canScheduleExact =
            await androidImpl.canScheduleExactNotifications();
        if (canScheduleExact == false) {
          await androidImpl.requestExactAlarmsPermission();
        }
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

  /// 3. Programa un lote de [days] notificaciones matutinas únicas (no repetitivas),
  /// una por día a la hora [hour]:[minute], comenzando en la próxima ocurrencia.
  ///
  /// [buildItem] recibe la fecha real de disparo para que el contenido dependa
  /// del calendario (y no del momento en que se abrió la app): reprogramar varias
  /// veces el mismo día produce exactamente el mismo resultado.
  ///
  /// Antes de programar se cancelan todas las notificaciones del lote anterior,
  /// incluida la antigua notificación repetitiva (ID [baseNotificationId]).
  Future<void> scheduleMorningBatch({
    required DailyVerseNotificationItem Function(tz.TZDateTime date) buildItem,
    required String channelName,
    required String channelDescription,
    required String actionAmenLabel,
    int days = maxBatchDays,
    int hour = 7,
    int minute = 0,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ [DailyVerse] scheduleMorningBatch antes de initialize()');
      return;
    }

    await cancelMorningVerses();

    final int total = days.clamp(0, maxBatchDays);
    final AndroidScheduleMode scheduleMode = await _resolveScheduleMode();
    final tz.TZDateTime first = _nextInstanceOfTime(hour: hour, minute: minute);

    for (int i = 0; i < total; i++) {
      // Se construye por componentes (día + i) en lugar de sumar Duration(days: i)
      // para que la hora de pared se mantenga estable ante cambios de horario (DST).
      final scheduledDate = tz.TZDateTime(
        tz.local,
        first.year,
        first.month,
        first.day + i,
        hour,
        minute,
      );
      final item = buildItem(scheduledDate);

      await _plugin.zonedSchedule(
        baseNotificationId + i,
        item.title,
        item.body,
        scheduledDate,
        _buildDetails(
          item: item,
          channelName: channelName,
          channelDescription: channelDescription,
          actionAmenLabel: actionAmenLabel,
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: item.toPayload(),
      );
    }

    debugPrint(
      '🔔 [DailyVerse] Lote programado: $total días desde $first ($scheduleMode)',
    );
  }

  /// Cancela solo las notificaciones matutinas de ATRIO (no afecta otros avisos locales).
  Future<void> cancelMorningVerses() async {
    if (!_isInitialized) return;
    for (int i = 0; i < maxBatchDays; i++) {
      await _plugin.cancel(baseNotificationId + i);
    }
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
    final notificationDetails = _buildDetails(
      item: item,
      channelName: channelName,
      channelDescription: channelDescription,
      actionAmenLabel: actionAmenLabel,
    );

    if (delaySeconds <= 0) {
      await _plugin.show(
        _testNotificationId,
        item.title,
        item.body,
        notificationDetails,
        payload: item.toPayload(),
      );
    } else {
      final scheduledDate =
          tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));
      await _plugin.zonedSchedule(
        _testNotificationId,
        item.title,
        item.body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: await _resolveScheduleMode(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: item.toPayload(),
      );
    }
  }

  /// Detalles visuales comunes (BigTextStyle, botón "Amén" e identidad ATRIO).
  NotificationDetails _buildDetails({
    required DailyVerseNotificationItem item,
    required String channelName,
    required String channelDescription,
    required String actionAmenLabel,
  }) {
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

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// Usa alarmas exactas si el sistema lo permite; si no (Android 14+ sin
  /// permiso "Alarmas y recordatorios"), cae a modo inexacto en lugar de fallar.
  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    if (!kIsWeb && Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final bool? canExact = await androidImpl?.canScheduleExactNotifications();
      if (canExact == false) {
        return AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }
    return AndroidScheduleMode.exactAllowWhileIdle;
  }

  /// Calcula la próxima instancia de la hora configurada (hoy o mañana).
  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        hour,
        minute,
      );
    }
    return scheduledDate;
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
