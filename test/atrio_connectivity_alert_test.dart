import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/widgets/atrio_connectivity_alert.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AtrioConnectivityAlert.dismiss();
  });

  group('AtrioConnectivityAlert - Posicionamiento Centrado y Tipografía', () {
    testWidgets('Alerta se renderiza en el centro de la pantalla con tipografía agrandada ~30%',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AtrioConnectivityAlert.show(
                        context,
                        title: 'Sin conexión',
                        message: 'Verifica tu red Wi-Fi o datos móviles.',
                      );
                    },
                    child: const Text('Disparar Alerta'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Abrir la alerta
      await tester.tap(find.text('Disparar Alerta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350)); // animación de entrada

      // 1. Verificar presencia de título y mensaje
      final titleFinder = find.text('Sin conexión');
      final messageFinder = find.text('Verifica tu red Wi-Fi o datos móviles.');
      expect(titleFinder, findsOneWidget);
      expect(messageFinder, findsOneWidget);

      // 2. Verificar tamaño de fuentes (+30% para mayor legibilidad)
      final Text titleText = tester.widget<Text>(titleFinder);
      final Text messageText = tester.widget<Text>(messageFinder);

      expect(titleText.style?.fontSize, 18.0);
      expect(messageText.style?.fontSize, 15.5);

      // 3. Verificar que la tarjeta está centrada en la pantalla
      final alertBoxFinder = find.ancestor(
        of: titleFinder,
        matching: find.byType(FadeTransition),
      );
      expect(alertBoxFinder, findsOneWidget);

      final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
      final alertCenter = tester.getCenter(alertBoxFinder);

      // Tolerancia mínima de centrado vertical y horizontal respecto a la pantalla
      expect((alertCenter.dx - (screenSize.width / 2)).abs(), lessThan(5.0));
      expect((alertCenter.dy - (screenSize.height / 2)).abs(), lessThan(5.0));

      AtrioConnectivityAlert.dismiss();
      await tester.pumpAndSettle();
    });

    testWidgets('Pulsar en el telón de fondo exterior descarta la alerta centrada',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AtrioConnectivityAlert.show(
                        context,
                        title: 'Sin conexión',
                        message: 'Prueba de descarte.',
                      );
                    },
                    child: const Text('Disparar Alerta'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disparar Alerta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Sin conexión'), findsOneWidget);

      // Tocar en la esquina superior izquierda (fuera de la tarjeta centrada)
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // animación de salida

      expect(find.text('Sin conexión'), findsNothing);
    });

    testWidgets('Botón Reintentar aparece debajo del mensaje y ejecuta el callback onRetry',
        (tester) async {
      bool reintentado = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AtrioConnectivityAlert.show(
                        context,
                        title: 'Sin conexión',
                        message: 'Mensaje de prueba con reintento.',
                        onRetry: () {
                          reintentado = true;
                        },
                      );
                    },
                    child: const Text('Disparar Alerta'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disparar Alerta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final messageFinder = find.text('Mensaje de prueba con reintento.');
      final retryFinder = find.text('Reintentar');

      expect(messageFinder, findsOneWidget);
      expect(retryFinder, findsOneWidget);

      // Verificar que el botón de reintentar está posicionado verticalmente debajo del mensaje
      final messageBottom = tester.getBottomLeft(messageFinder).dy;
      final retryTop = tester.getTopLeft(retryFinder).dy;
      expect(retryTop, greaterThan(messageBottom));

      // Tocar reintentar
      await tester.tap(retryFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(reintentado, isTrue);
    });
  });
}
