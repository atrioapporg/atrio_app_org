import 'package:flutter/widgets.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import '../modelos/ajustes_model.dart';
import 'daily_verse_notification_service.dart';

/// Entrada del catálogo rotativo de la Oración Matutina.
/// Los textos visibles se resuelven siempre vía [AppLocalizations].
class _DailyVerseEntry {
  final int bookId;
  final int totalChapters;
  final int chapter;
  final int verse;
  final int? verseEnd;
  final String Function(AppLocalizations l10n) reference;
  final String Function(AppLocalizations l10n) body;

  const _DailyVerseEntry({
    required this.bookId,
    required this.totalChapters,
    required this.chapter,
    required this.verse,
    this.verseEnd,
    required this.reference,
    required this.body,
  });
}

String _ref1(AppLocalizations l) => l.dailyPrayerRef1;
String _ref2(AppLocalizations l) => l.dailyPrayerRef2;
String _ref3(AppLocalizations l) => l.dailyPrayerRef3;
String _ref4(AppLocalizations l) => l.dailyPrayerRef4;
String _ref5(AppLocalizations l) => l.dailyPrayerRef5;
String _ref6(AppLocalizations l) => l.dailyPrayerRef6;
String _ref7(AppLocalizations l) => l.dailyPrayerRef7;
String _body1(AppLocalizations l) => l.dailyPrayerDefaultBody;
String _body2(AppLocalizations l) => l.dailyPrayerBody2;
String _body3(AppLocalizations l) => l.dailyPrayerBody3;
String _body4(AppLocalizations l) => l.dailyPrayerBody4;
String _body5(AppLocalizations l) => l.dailyPrayerBody5;
String _body6(AppLocalizations l) => l.dailyPrayerBody6;
String _body7(AppLocalizations l) => l.dailyPrayerBody7;

/// IDs de libro según el canon protestante (Génesis = 1 … Apocalipsis = 66).
const List<_DailyVerseEntry> _catalog = [
  _DailyVerseEntry(bookId: 50, totalChapters: 4, chapter: 4, verse: 6, verseEnd: 7, reference: _ref1, body: _body1),
  _DailyVerseEntry(bookId: 23, totalChapters: 66, chapter: 40, verse: 31, reference: _ref2, body: _body2),
  _DailyVerseEntry(bookId: 19, totalChapters: 150, chapter: 23, verse: 1, reference: _ref3, body: _body3),
  _DailyVerseEntry(bookId: 6, totalChapters: 24, chapter: 1, verse: 9, reference: _ref4, body: _body4),
  _DailyVerseEntry(bookId: 25, totalChapters: 5, chapter: 3, verse: 22, verseEnd: 23, reference: _ref5, body: _body5),
  _DailyVerseEntry(bookId: 20, totalChapters: 31, chapter: 3, verse: 5, verseEnd: 6, reference: _ref6, body: _body6),
  _DailyVerseEntry(bookId: 40, totalChapters: 28, chapter: 11, verse: 28, reference: _ref7, body: _body7),
];

/// Orquesta la programación del lote de Oraciones Matutinas a partir de los
/// ajustes del usuario (activado/desactivado, hora e idioma).
///
/// Es idempotente: puede llamarse en cada arranque, al reanudar la app y al
/// cambiar ajustes. Las llamadas concurrentes se serializan.
class DailyVerseScheduler {
  DailyVerseScheduler._();

  static Future<void> _cola = Future<void>.value();

  /// Reprograma (o cancela) el lote según [ajustes].
  static Future<void> sync(AjustesModel ajustes) {
    _cola = _cola.then((_) => _sync(ajustes)).catchError((Object e) {
      debugPrint('⚠️ [DailyVerseScheduler] Error al sincronizar: $e');
    });
    return _cola;
  }

  static Future<void> _sync(AjustesModel ajustes) async {
    final service = DailyVerseNotificationService.instance;
    if (!service.isInitialized) return;

    if (!ajustes.notifVersiculoDia) {
      await service.cancelAllDailyVerses();
      return;
    }

    final l10n = localizationsFor(ajustes.idiomaCodigo);
    final (morningHour, morningMinute) = _parseHora(ajustes.horaNotifDevocional);

    // 1. Programación de la notificación matutina principal
    await service.scheduleMorningBatch(
      buildItem: (date) => itemForDate(date, l10n, isSecondNotification: false),
      channelName: l10n.dailyWordChannelName,
      channelDescription: l10n.dailyWordChannelDescription,
      actionAmenLabel: l10n.dailyPrayerAmenAction,
      hour: morningHour,
      minute: morningMinute,
    );

    // 2. Programación de la segunda notificación o cancelación según el switch
    if (ajustes.dobleNotifVersiculoDia) {
      final (secondHour, secondMinute) =
          _parseHora(ajustes.segundaHoraNotifDevocional);
      await service.scheduleSecondDailyBatch(
        buildItem: (date) => itemForDate(date, l10n, isSecondNotification: true),
        channelName: l10n.dailyWordChannelName,
        channelDescription: l10n.dailyWordChannelDescription,
        actionAmenLabel: l10n.dailyPrayerAmenAction,
        hour: secondHour,
        minute: secondMinute,
      );
    } else {
      await service.cancelSecondDailyVerses();
    }
  }

  /// Contenido determinista para una fecha: el mismo día siempre recibe la
  /// misma oración, sin importar cuántas veces se reprograme el lote.
  /// [isSecondNotification] permite variar la porción y el título para la segunda hora diaria.
  static DailyVerseNotificationItem itemForDate(
    DateTime date,
    AppLocalizations l10n, {
    bool isSecondNotification = false,
  }) {
    final int dayNumber =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;
    final int catalogIndex = isSecondNotification
        ? (dayNumber + 3) % _catalog.length
        : dayNumber % _catalog.length;
    final entry = _catalog[catalogIndex];
    final reference = entry.reference(l10n);

    return DailyVerseNotificationItem(
      title: isSecondNotification
          ? l10n.dailyPrayerEveningTitle
          : l10n.dailyPrayerMorningTitle,
      reference: reference,
      body: entry.body(l10n),
      bookId: entry.bookId,
      bookName: _bookNameFromReference(reference),
      totalChapters: entry.totalChapters,
      chapter: entry.chapter,
      verse: entry.verse,
      verseEnd: entry.verseEnd,
    );
  }

  /// Dispara una notificación de prueba con el contenido de hoy.
  static Future<void> showTest(
    AjustesModel ajustes, {
    int delaySeconds = 4,
    bool isSecondNotification = false,
  }) {
    final l10n = localizationsFor(ajustes.idiomaCodigo);
    return DailyVerseNotificationService.instance.showTestNotificationImmediately(
      item: itemForDate(
        tz.TZDateTime.now(tz.local),
        l10n,
        isSecondNotification: isSecondNotification,
      ),
      channelName: l10n.dailyWordChannelName,
      channelDescription: l10n.dailyWordChannelDescription,
      actionAmenLabel: l10n.dailyPrayerAmenAction,
      delaySeconds: delaySeconds,
    );
  }

  /// Resuelve las traducciones sin depender de un BuildContext (los textos de
  /// la notificación quedan fijados en el idioma activo al momento de programar).
  static AppLocalizations localizationsFor(String idiomaCodigo) {
    final bool soportado = AppLocalizations.supportedLocales
        .any((l) => l.languageCode == idiomaCodigo);
    return lookupAppLocalizations(Locale(soportado ? idiomaCodigo : 'es'));
  }

  /// "07:00" → (7, 0). Valores inválidos vuelven a las 7:00.
  static (int, int) _parseHora(String hora) {
    final partes = hora.split(':');
    final int h = int.tryParse(partes.first) ?? 7;
    final int m = partes.length > 1 ? int.tryParse(partes[1]) ?? 0 : 0;
    if (h < 0 || h > 23 || m < 0 || m > 59) return (7, 0);
    return (h, m);
  }

  /// "2 Corintios 5:7" → "2 Corintios"; "Filipenses 4:6-7" → "Filipenses".
  static String _bookNameFromReference(String reference) =>
      reference.replaceFirst(RegExp(r'\s+\d+:[\d\-–,]+$'), '').trim();
}
