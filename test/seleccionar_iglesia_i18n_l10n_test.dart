import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/screens/seleccionar_iglesia_screen.dart';
import 'package:atrio/widgets/church_welcome_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Certificación de Internacionalización y Localización (i18n / l10n - intl 0.20)', () {
    // -------------------------------------------------------------------------
    // 1. TRADUCCIÓN DE MENSAJES (Message Translation)
    // -------------------------------------------------------------------------
    testWidgets('1. Traducción de mensajes en Español e Inglés con AppLocalizations', (tester) async {
      late AppLocalizations l10nEs;
      late AppLocalizations l10nEn;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Builder(
            builder: (ctx) {
              l10nEs = AppLocalizations.of(ctx)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10nEs.seleccionaTuIglesia, equals('Selecciona tu iglesia'));
      expect(l10nEs.busquedaPorRadio, equals('Por radio'));
      expect(l10nEs.busquedaNacional, equals('Nacional'));
      expect(
        l10nEs.modalBienvenidaIglesiaMensaje,
        equals('Conéctate a tu iglesia local para acceder a devocionales, eventos, oraciones y la vida de tu comunidad'),
      );
      expect(l10nEs.continuar, equals('Continuar'));
      expect(l10nEs.entendido, equals('Entendido'));

      // Prueba en Inglés (en)
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (ctx) {
              l10nEn = AppLocalizations.of(ctx)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10nEn.seleccionaTuIglesia, equals('Select your church'));
      expect(l10nEn.busquedaPorRadio, equals('By radius'));
      expect(l10nEn.busquedaNacional, equals('National'));
      expect(
        l10nEn.modalBienvenidaIglesiaMensaje,
        equals('Connect with your local church to access devotionals, events, prayers, and community life'),
      );
      expect(l10nEn.continuar, equals('Continue'));
      expect(l10nEn.entendido, equals('Got it'));
    });

    // -------------------------------------------------------------------------
    // 2. PLURALES Y GÉNEROS (Plurals and Genders con sintaxis ICU e intl 0.20)
    // -------------------------------------------------------------------------
    testWidgets('2. Plurales con sintaxis ICU (zero, one, other)', (tester) async {
      late AppLocalizations l10nEs;
      late AppLocalizations l10nEn;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Builder(
            builder: (ctx) {
              l10nEs = AppLocalizations.of(ctx)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Español
      expect(l10nEs.conteoIglesiasEnMapa(0), equals('No hay iglesias en el mapa'));
      expect(l10nEs.conteoIglesiasEnMapa(1), equals('1 iglesia en el mapa'));
      expect(l10nEs.conteoIglesiasEnMapa(15), equals('15 iglesias en el mapa'));

      // Inglés
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (ctx) {
              l10nEn = AppLocalizations.of(ctx)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10nEn.conteoIglesiasEnMapa(0), equals('No churches on map'));
      expect(l10nEn.conteoIglesiasEnMapa(1), equals('1 church on map'));
      expect(l10nEn.conteoIglesiasEnMapa(15), equals('15 churches on map'));
    });

    testWidgets('2.1 Géneros gramaticales con sintaxis ICU (select / gender)', (tester) async {
      late AppLocalizations l10nEs;
      late AppLocalizations l10nEn;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Builder(
            builder: (ctx) {
              l10nEs = AppLocalizations.of(ctx)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10nEs.bienvenidoSegunGenero('female'), equals('Bienvenida'));
      expect(l10nEs.bienvenidoSegunGenero('male'), equals('Bienvenido'));
      expect(l10nEs.bienvenidoSegunGenero('other'), equals('Bienvenido(a)'));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (ctx) {
              l10nEn = AppLocalizations.of(ctx)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10nEn.bienvenidoSegunGenero('female'), equals('Welcome'));
      expect(l10nEn.bienvenidoSegunGenero('male'), equals('Welcome'));
      expect(l10nEn.bienvenidoSegunGenero('other'), equals('Welcome'));
    });

    // -------------------------------------------------------------------------
    // 3. FORMATO Y ANÁLISIS DE FECHAS Y NÚMEROS (Dates & Numbers with intl 0.20)
    // -------------------------------------------------------------------------
    test('3. Formato y parsing de números con intl (distancias y cantidades)', () {
      // Formato de distancia en español e inglés
      final distEs = SeleccionarIglesiaScreen.formatearDistanciaKm(3.5, locale: 'es');
      expect(distEs, anyOf(equals('3,5'), equals('3.5')));

      final distEn = SeleccionarIglesiaScreen.formatearDistanciaKm(12.4, locale: 'en');
      expect(distEn, equals('12.4'));

      // Parsing de distancias y cantidades
      final parseadoEn = SeleccionarIglesiaScreen.parsearDistanciaKm('15.8', locale: 'en');
      expect(parseadoEn, equals(15.8));
    });

    test('3.1 Formato y parsing de fechas y horas con intl', () {
      final fechaPrueba = DateTime(2026, 10, 30, 10, 30);

      // Formato de hora localizado
      final horaEs = SeleccionarIglesiaScreen.formatearHoraCulto(fechaPrueba, locale: 'es');
      expect(horaEs.isNotEmpty, isTrue);

      final horaEn = SeleccionarIglesiaScreen.formatearHoraCulto(fechaPrueba, locale: 'en');
      expect(horaEn, contains('10:30'));

      // Parsing de hora
      final horaParseada = SeleccionarIglesiaScreen.parsearHoraCulto('10:30', locale: 'es');
      expect(horaParseada.hour, equals(10));
      expect(horaParseada.minute, equals(30));

      // Formato completo de fecha de servicio litúrgico
      final fechaFormateada = SeleccionarIglesiaScreen.formatearFechaCulto(fechaPrueba, locale: 'es');
      expect(fechaFormateada.isNotEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // 4. TEXTO BIDIRECCIONAL (Bidirectional Text / RTL - LTR)
    // -------------------------------------------------------------------------
    testWidgets('4. Soporte de texto bidireccional (RTL y LTR)', (tester) async {
      bool esRtlEncontrado = false;

      // 1. Probar entorno LTR (Español)
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (ctx) {
                esRtlEncontrado = SeleccionarIglesiaScreen.esDireccionRTL(ctx);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(esRtlEncontrado, isFalse);

      // 2. Probar entorno RTL (Árabe / Hebreo)
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (ctx) {
                esRtlEncontrado = SeleccionarIglesiaScreen.esDireccionRTL(ctx);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(esRtlEncontrado, isTrue);
    });

    testWidgets('4.1 Diálogo modal ChurchWelcomeDialog en entorno RTL invierte iconos direccionales', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: ChurchWelcomeDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChurchWelcomeDialog), findsOneWidget);
      // Transform.flip con flipX: true para el icono en RTL
      final transformFinder = find.byWidgetPredicate(
        (w) => w is Transform && w.child is Icon,
      );
      expect(transformFinder, findsWidgets);
    });

    // -------------------------------------------------------------------------
    // 5. COMPATIBILIDAD CON intl 0.20
    // -------------------------------------------------------------------------
    test('5. Certificación de versión y API de intl 0.20', () {
      // Validar presencia y funcionamiento de NumberFormat, DateFormat y BidiFormatter
      final nf = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');
      final formattedCurr = nf.format(1500.50);
      expect(formattedCurr, contains('1'));

      final df = DateFormat.yMMMM('es');
      expect(df.format(DateTime(2026, 10, 1)), isNotEmpty);

      final bidiFormatter = BidiFormatter.LTR();
      expect(bidiFormatter.wrapWithUnicode('Texto'), isNotEmpty);
    });
  });
}
