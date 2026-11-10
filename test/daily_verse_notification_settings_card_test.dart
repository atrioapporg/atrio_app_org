import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/providers/ajustes_provider.dart';
import 'package:atrio/widgets/daily_verse_notification_settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest(AjustesProvider provider) {
    return ChangeNotifierProvider<AjustesProvider>.value(
      value: provider,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('es', 'DO'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DailyVerseNotificationSettingsCard(),
          ),
        ),
      ),
    );
  }

  testWidgets('DailyVerseNotificationSettingsCard renders switch and updates state',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = AjustesProvider();

    await tester.pumpWidget(createWidgetUnderTest(provider));
    await tester.pumpAndSettle();

    // 1. Debe mostrar el título principal
    expect(find.text('Notificaciones del Versículo del Día'), findsOneWidget);

    // 2. Debe mostrar la primera notificación matutina predeterminada
    expect(find.text('Primera notificación (Mañana)'), findsOneWidget);

    // 3. El switch de doble notificación debe encontrarse y estar desactivado por defecto
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    Switch switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isFalse);

    // 4. Al activar el switch, conmuta el estado en el Provider
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(provider.isDoubleNotificationEnabled, isTrue);
    switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, isTrue);

    // 5. Debe mostrar el tile de la segunda notificación (Tarde/Noche)
    expect(find.text('Segunda notificación (Tarde/Noche)'), findsOneWidget);
  });
}
