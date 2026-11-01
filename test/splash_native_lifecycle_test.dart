import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atrio/screens/splash_screen.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';
import 'package:atrio/screens/intro_encuentra_screen.dart';
import 'package:atrio/screens/inicio_sesion_screen.dart';
import 'package:atrio/servicios/connectivity_service.dart';
import 'package:atrio/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auditoría y Validación de Splash Screen y Ciclo de Vida Nativo', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async => null,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (call) async => <String>['wifi'],
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (call) async => null,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.tekartik.sqflite'),
        (call) async {
          if (call.method == 'getDatabasesPath') return '.';
          return null;
        },
      );
    });

    tearDown(() {
      ConnectivityService.instance.dispose();
    });

    testWidgets('SplashScreen no impone delay artificial y navega a Intro si no se ha visto la inducción', (tester) async {
      SharedPreferences.setMockInitialValues({
        'intro_vista': false,
        'isLoggedIn': false,
      });

      String? rutaNavegada;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SplashScreen(),
          routes: {
            IntroEncuentraScreen.routeName: (_) {
              rutaNavegada = IntroEncuentraScreen.routeName;
              return const Scaffold(body: Text('Intro Mock'));
            },
            InicioSesionScreen.routeName: (_) {
              rutaNavegada = InicioSesionScreen.routeName;
              return const Scaffold(body: Text('Login Mock'));
            },
            InicioAtrioScreen.routeName: (_) {
              rutaNavegada = InicioAtrioScreen.routeName;
              return const Scaffold(body: Text('Home Mock'));
            },
          },
        ),
      );

      // Verificamos que se renderiza el SplashScreen con su branding institucional
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(SplashBackgroundView), findsOneWidget);

      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(rutaNavegada, equals(IntroEncuentraScreen.routeName));
      expect(find.text('Intro Mock'), findsOneWidget);
    });

    testWidgets('SplashScreen navega a InicioSesionScreen para usuarios sin sesión activa que ya vieron la intro', (tester) async {
      SharedPreferences.setMockInitialValues({
        'intro_vista': true,
        'isLoggedIn': false,
      });

      String? rutaNavegada;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SplashScreen(),
          routes: {
            IntroEncuentraScreen.routeName: (_) {
              rutaNavegada = IntroEncuentraScreen.routeName;
              return const Scaffold(body: Text('Intro Mock'));
            },
            InicioSesionScreen.routeName: (_) {
              rutaNavegada = InicioSesionScreen.routeName;
              return const Scaffold(body: Text('Login Mock'));
            },
            InicioAtrioScreen.routeName: (_) {
              rutaNavegada = InicioAtrioScreen.routeName;
              return const Scaffold(body: Text('Home Mock'));
            },
          },
        ),
      );

      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(rutaNavegada, equals(InicioSesionScreen.routeName));
      expect(find.text('Login Mock'), findsOneWidget);
    });

    testWidgets('SplashScreen no redirige al login cuando el usuario ya cuenta con sesión iniciada', (tester) async {
      SharedPreferences.setMockInitialValues({
        'intro_vista': true,
        'isLoggedIn': true,
        'iglesia_guardada': 'Iglesia Central de Prueba',
      });

      String? rutaNavegada;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SplashScreen(),
          routes: {
            IntroEncuentraScreen.routeName: (_) {
              rutaNavegada = IntroEncuentraScreen.routeName;
              return const Scaffold(body: Text('Intro Mock'));
            },
            InicioSesionScreen.routeName: (_) {
              rutaNavegada = InicioSesionScreen.routeName;
              return const Scaffold(body: Text('Login Mock'));
            },
            InicioAtrioScreen.routeName: (_) {
              rutaNavegada = InicioAtrioScreen.routeName;
              return const Scaffold(body: Text('Home Mock'));
            },
          },
        ),
      );

      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Debe ir directo a InicioAtrioScreen (Home), jamás a InicioSesionScreen
      expect(rutaNavegada, isNot(equals(InicioSesionScreen.routeName)));
      expect(rutaNavegada, equals(InicioAtrioScreen.routeName));
      expect(find.text('Home Mock'), findsOneWidget);
    });

    testWidgets('SplashBackgroundView utiliza el color azul oficial continuo #072B4F del Splash de Android 12+', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SplashBackgroundView(),
          ),
        ),
      );

      final coloredBoxFinder = find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == const Color(0xFF072B4F),
      );
      expect(coloredBoxFinder, findsWidgets);
    });
  });
}
