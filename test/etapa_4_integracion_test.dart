import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/ajustes_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/widgets/change_pending_banner.dart';
import 'package:atrio/screens/crear_cuenta_screen.dart';
import 'package:atrio/screens/elegir_camino_iglesia_screen.dart';
import 'package:atrio/screens/esperando_aprobacion_screen.dart';
import 'package:atrio/screens/iglesia_pendiente_activacion_screen.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';

Widget createTestApp({
  required Widget child,
  required UserProvider userProvider,
  IglesiaProvider? iglesiaProvider,
  AjustesProvider? ajustesProvider,
  RouteSettings? initialSettings,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ChangeNotifierProvider<IglesiaProvider>.value(
        value: iglesiaProvider ?? IglesiaProvider(),
      ),
      ChangeNotifierProvider<AjustesProvider>.value(
        value: ajustesProvider ?? AjustesProvider(),
      ),
    ],
    child: MaterialApp(
      home: child,
      routes: {
        ElegirCaminoIglesiaScreen.routeName: (_) => const ElegirCaminoIglesiaScreen(),
        EsperandoAprobacionScreen.routeName: (_) => const EsperandoAprobacionScreen(),
        IglesiaPendienteActivacionScreen.routeName: (_) =>
            const IglesiaPendienteActivacionScreen(),
        InicioAtrioScreen.routeName: (_) => const Scaffold(body: Text('Inicio Atrio Mock')),
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Etapa 4 - Integración en Pantallas Existentes', () {
    testWidgets('ChangePendingBanner se oculta cuando isChangePending es false', (tester) async {
      final userProvider = UserProvider(api: AtrioApi(baseUrl: 'https://test.atrioapp.org'));
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 1,
          nombre: 'Juan',
          email: 'juan@atrio.org',
          iglesiaActual: 'Iglesia Central',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'J',
          esMiembroVerificado: true,
          role: UserRole.user,
          membershipStatus: 'approved',
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(body: ChangePendingBanner()),
          userProvider: userProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Has solicitado cambio de iglesia'),
        findsNothing,
      );
    });

    testWidgets('ChangePendingBanner se muestra cuando isChangePending es true', (tester) async {
      final userProvider = UserProvider(api: AtrioApi(baseUrl: 'https://test.atrioapp.org'));
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 2,
          nombre: 'María',
          email: 'maria@atrio.org',
          iglesiaActual: 'Iglesia Anterior',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'M',
          esMiembroVerificado: true,
          role: UserRole.user,
          membershipStatus: 'change_pending',
          requestedChurchId: 25,
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(body: ChangePendingBanner()),
          userProvider: userProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Has solicitado cambio de iglesia. Tu solicitud está en revisión por la nueva congregación.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    });

    testWidgets('CrearCuentaScreen exige mínimo 8 caracteres de contraseña', (tester) async {
      final userProvider = UserProvider(api: AtrioApi(baseUrl: 'https://test.atrioapp.org'));

      await tester.pumpWidget(
        createTestApp(
          child: const CrearCuentaScreen(),
          userProvider: userProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Completar campos con clave de 6 caracteres (inválida según Odoo 19)
      final nombreField = find.byType(TextField).at(0);
      final emailField = find.byType(TextField).at(1);
      final telField = find.byType(TextField).at(2);
      final passField = find.byType(TextField).at(3);
      final confirmPassField = find.byType(TextField).at(4);

      await tester.enterText(nombreField, 'Carlos López');
      await tester.enterText(emailField, 'carlos@prueba.com');
      await tester.enterText(telField, '8095551234');
      await tester.enterText(passField, '123456');
      await tester.enterText(confirmPassField, '123456');

      // Tocar el botón de registro
      final botonRegistrar = find.text('Crear cuenta');
      await tester.ensureVisible(botonRegistrar);
      await tester.tap(botonRegistrar);
      await tester.pumpAndSettle();

      expect(
        find.text('La contraseña debe tener al menos 8 caracteres.'),
        findsOneWidget,
      );
    });

    test('resolveStage mapea correctamente todas las etapas para enrutador de login', () {
      // 1. Usuario nuevo sin iglesia
      final stageChoose = resolveStage({
        'role': 'user',
        'membership_status': 'none',
        'church': null,
      });
      expect(stageChoose, AppStage.chooseChurch);

      // 2. Solicitud de membresía pendiente
      final stageWaiting = resolveStage({
        'role': 'user',
        'membership_status': 'membership_pending',
        'requested_church_id': 12,
      });
      expect(stageWaiting, AppStage.waitingApproval);

      // 3. Admin de iglesia sin activar
      final stagePendingAct = resolveStage({
        'role': 'church_admin',
        'church': {'id': 5, 'name': 'Nueva Luz', 'has_active_subscription': false},
      });
      expect(stagePendingAct, AppStage.churchPendingActivation);

      // 4. Miembro regular activo
      final stageMember = resolveStage({
        'role': 'user',
        'membership_status': 'approved',
        'church': {'id': 5, 'name': 'Nueva Luz', 'has_active_subscription': true},
      });
      expect(stageMember, AppStage.memberHome);
    });
  });
}
