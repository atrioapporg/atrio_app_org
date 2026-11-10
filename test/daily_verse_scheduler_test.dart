import 'package:atrio/servicios/daily_verse_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final es = DailyVerseScheduler.localizationsFor('es');
  final en = DailyVerseScheduler.localizationsFor('en');

  test('el mismo día siempre produce la misma oración (idempotente)', () {
    final a = DailyVerseScheduler.itemForDate(DateTime(2026, 11, 7, 7), es);
    final b = DailyVerseScheduler.itemForDate(DateTime(2026, 11, 7, 23, 59), es);
    expect(a.reference, b.reference);
    expect(a.body, b.body);
  });

  test('7 días consecutivos no repiten oración', () {
    final refs = {
      for (int i = 0; i < 7; i++)
        DailyVerseScheduler.itemForDate(DateTime(2026, 11, 7 + i), es).reference,
    };
    expect(refs.length, 7);
  });

  test('payload localizado y nombre de libro derivado de la referencia', () {
    final day = DateTime(2026, 11, 7);
    final itemEs = DailyVerseScheduler.itemForDate(day, es);
    final itemEn = DailyVerseScheduler.itemForDate(day, en);
    expect(itemEs.bookId, itemEn.bookId);
    expect(itemEs.reference, isNot(itemEn.reference));
    expect(itemEs.reference.startsWith(itemEs.bookName), isTrue);
    expect(itemEs.bookName.contains(':'), isFalse);
  });

  test('segunda notificación produce título vespertino y porción complementaria', () {
    final day = DateTime(2026, 11, 7);
    final morningEs = DailyVerseScheduler.itemForDate(day, es, isSecondNotification: false);
    final eveningEs = DailyVerseScheduler.itemForDate(day, es, isSecondNotification: true);
    final eveningEn = DailyVerseScheduler.itemForDate(day, en, isSecondNotification: true);

    expect(morningEs.title, es.dailyPrayerMorningTitle);
    expect(eveningEs.title, es.dailyPrayerEveningTitle);
    expect(eveningEn.title, en.dailyPrayerEveningTitle);

    // La segunda notificación del día ofrece una porción bíblica distinta a la matutina
    expect(morningEs.reference, isNot(eveningEs.reference));
  });
}

