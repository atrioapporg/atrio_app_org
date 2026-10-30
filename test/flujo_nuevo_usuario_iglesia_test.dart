import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/ajustes_provider.dart';
import 'package:atrio/providers/explorar_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/tradicion_cristiana_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';
import 'package:atrio/screens/seleccionar_iglesia_screen.dart';
import 'package:atrio/widgets/church_welcome_modal.dart';

Widget createTestApp({
  required Widget child,
  required UserProvider userProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ChangeNotifierProvider<IglesiaProvider>(create: (_) => IglesiaProvider()),
      ChangeNotifierProvider<AjustesProvider>(create: (_) => AjustesProvider()),
      ChangeNotifierProvider<ExplorarProvider>(create: (_) => ExplorarProvider()),
      ChangeNotifierProvider<TradicionCristianaProvider>(
        create: (_) => TradicionCristianaProvider(),
      ),
    ],
    child: MaterialApp(
      home: child,
      routes: {
        SeleccionarIglesiaScreen.routeName: (_) =>
            const Scaffold(body: Text('Seleccionar Iglesia Pantalla')),
        InicioAtrioScreen.routeName: (_) =>
            const Scaffold(body: Text('Inicio Atrio Pantalla')),
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Flujo Optimizado de Registro y Enrutamiento a SeleccionarIglesiaScreen', () {
    test('1. user.selectedChurch es null para usuarios nuevos y no-null con iglesia', () {
      final nuevoUsuario = UserModel(
        id: 10,
        nombre: 'Carlos Nuevo',
        email: 'carlos@ejemplo.com',
        iglesiaActual: 'Sin iglesia seleccionada',
        fechaRegistro: '2026-10-30',
        avatarIniciales: 'CN',
        esMiembroVerificado: false,
        role: UserRole.user,
        membershipStatus: 'none',
      );

      expect(nuevoUsuario.selectedChurch, isNull);
      expect(nuevoUsuario.hasSelectedOrLinkedChurch, isFalse);

      final usuarioConIglesia = UserModel(
        id: 11,
        nombre: 'Maria Vinculada',
        email: 'maria@ejemplo.com',
        iglesiaActual: 'Iglesia Cristiana Central',
        iglesiaId: 45,
        fechaRegistro: '2026-10-30',
        avatarIniciales: 'MV',
        esMiembroVerificado: true,
        role: UserRole.member,
        membershipStatus: 'approved',
      );

      expect(usuarioConIglesia.selectedChurch, equals('Iglesia Cristiana Central'));
      expect(usuarioConIglesia.hasSelectedOrLinkedChurch, isTrue);
    });

    test('2. Enrutamiento post login/registro redirige a SeleccionarIglesiaScreen si no tiene iglesia', () {
      // Simular lógica de resolución post login para un usuario nuevo
      String determinarRutaPostLogin({required UserModel user}) {
        if (user.selectedChurch != null || user.hasSelectedOrLinkedChurch) {
          return InicioAtrioScreen.routeName;
        }
        return SeleccionarIglesiaScreen.routeName;
      }

      final nuevoUser = UserModel(
        id: 12,
        nombre: 'David',
        email: 'david@correo.com',
        iglesiaActual: '',
        fechaRegistro: '2026-10-30',
        avatarIniciales: 'D',
        esMiembroVerificado: false,
        role: UserRole.user,
        membershipStatus: 'none',
      );

      expect(nuevoUser.selectedChurch, isNull);
      expect(determinarRutaPostLogin(user: nuevoUser), equals(SeleccionarIglesiaScreen.routeName));

      final userConIglesia = UserModel(
        id: 13,
        nombre: 'Esteban',
        email: 'esteban@correo.com',
        iglesiaActual: 'Iglesia Gracia',
        iglesiaId: 9,
        fechaRegistro: '2026-10-30',
        avatarIniciales: 'E',
        esMiembroVerificado: true,
        role: UserRole.member,
      );

      expect(userConIglesia.selectedChurch, isNotNull);
      expect(determinarRutaPostLogin(user: userConIglesia), equals(InicioAtrioScreen.routeName));
    });

    test('3. AppStage.chooseChurch resuelve a SeleccionarIglesiaScreen como destino', () {
      final meSinIglesia = {
        'id': 14,
        'name': 'Lucas',
        'role': 'user',
        'membership_status': 'none',
      };

      final stage = resolveStage(meSinIglesia);
      expect(stage, equals(AppStage.chooseChurch));

      String obtenerRutaSegunStage(AppStage st) {
        switch (st) {
          case AppStage.chooseChurch:
            return SeleccionarIglesiaScreen.routeName;
          case AppStage.waitingApproval:
          case AppStage.churchPendingActivation:
          case AppStage.welcome:
          case AppStage.memberHome:
          case AppStage.adminHome:
          case AppStage.platformAdmin:
            return InicioAtrioScreen.routeName;
        }
      }

      expect(obtenerRutaSegunStage(stage), equals(SeleccionarIglesiaScreen.routeName));
    });
  });

  group('Bandera de Condición y Persistencia (has_seen_church_welcome_modal)', () {
    test('Bandera por defecto es false y se persiste como true tras marcarla', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getBool(ChurchWelcomeModal.prefsKey), isNull);
      expect(await ChurchWelcomeModal.haVistoModal(), isFalse);

      await ChurchWelcomeModal.marcarComoVisto();

      expect(prefs.getBool(ChurchWelcomeModal.prefsKey), isTrue);
      expect(await ChurchWelcomeModal.haVistoModal(), isTrue);

      // Reseteo
      await ChurchWelcomeModal.resetearBandera();
      expect(await ChurchWelcomeModal.haVistoModal(), isFalse);
    });
  });

  group('Modal UI/UX Informativo de Bienvenida (ChurchWelcomeModal)', () {
    testWidgets('Muestra el diálogo con el texto exacto requerido y botón de acción', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => ChurchWelcomeModal.mostrar(ctx),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Verificar que el diálogo se muestra
      expect(find.byType(ChurchWelcomeDialog), findsOneWidget);
      expect(find.text('¡Bienvenido a ATRIO!'), findsOneWidget);

      // Verificar el texto exacto requerido por especificación
      expect(
        find.text(
          'Conéctate a tu iglesia local para acceder a devocionales, eventos, oraciones y la vida de tu comunidad',
        ),
        findsOneWidget,
      );

      // Verificar presencia de botón de acción clara
      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);

      // Pulsar "Continuar" para cerrar el modal
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.byType(ChurchWelcomeDialog), findsNothing);
    });

    testWidgets('mostrarSiEsPrimeraVez solo abre el diálogo una vez y persiste la bandera', (tester) async {
      SharedPreferences.setMockInitialValues({});

      bool seMostroPrimeraVez = false;
      bool seMostroSegundaVez = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        seMostroPrimeraVez =
                            await ChurchWelcomeModal.mostrarSiEsPrimeraVez(ctx);
                      },
                      child: const Text('Intento 1'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        seMostroSegundaVez =
                            await ChurchWelcomeModal.mostrarSiEsPrimeraVez(ctx);
                      },
                      child: const Text('Intento 2'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Primer intento: Debe mostrarse
      await tester.tap(find.text('Intento 1'));
      await tester.pumpAndSettle();

      expect(find.byType(ChurchWelcomeDialog), findsOneWidget);

      // Cerrar modal
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.byType(ChurchWelcomeDialog), findsNothing);
      expect(seMostroPrimeraVez, isTrue);

      // Segundo intento: La bandera ya está en true, NO debe mostrarse
      await tester.tap(find.text('Intento 2'));
      await tester.pumpAndSettle();

      expect(seMostroSegundaVez, isFalse);
      expect(find.byType(ChurchWelcomeDialog), findsNothing);

      // Verificar persistencia en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(ChurchWelcomeModal.prefsKey), isTrue);
    });
  });
}
