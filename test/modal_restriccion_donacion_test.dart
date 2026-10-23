import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/main.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/inicio_sesion_screen.dart';
import 'package:atrio/widgets/modal_restriccion_donacion.dart';

void main() {
  Widget createTestWidget({
    required UserProvider userProvider,
    required Widget child,
  }) {
    return ChangeNotifierProvider<UserProvider>.value(
      value: userProvider,
      child: MaterialApp(
        navigatorKey: MyApp.navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        routes: {
          InicioSesionScreen.routeName: (_) => const Scaffold(
                body: Text('PANTALLA_INICIO_SESION'),
              ),
        },
        home: Scaffold(body: child),
      ),
    );
  }

  group('ModalRestriccionDonacion Resiliencia de Contexto y Navegación', () {
    testWidgets(
        'Muestra modal en modo invitado y pulsar Iniciar Sesión no arroja error de contexto desactivado',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(null); // Modo invitado

      await tester.pumpWidget(
        createTestWidget(
          userProvider: userProvider,
          child: Builder(
            builder: (ctx) {
              return ElevatedButton(
                onPressed: () {
                  ModalRestriccionDonacion.mostrar(context: ctx);
                },
                child: const Text('ABRIR_MODAL'),
              );
            },
          ),
        ),
      );

      // Abrir el modal
      await tester.tap(find.text('ABRIR_MODAL'));
      await tester.pumpAndSettle();

      expect(find.text('Inicio de sesión requerido'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);

      // Pulsar "Iniciar sesión"
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      // Certificar que navegó sin excepciones y muestra la pantalla de inicio de sesión
      expect(find.text('PANTALLA_INICIO_SESION'), findsOneWidget);
    });

    testWidgets(
        'verificarDonacionGeneral bloquea y muestra modal cuando isReadOnly es true',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.api.token = 'test_jwt_token';
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 99,
          nombre: 'Superadmin Odoo',
          email: 'super@odoo.com',
          iglesiaActual: 'Catedral',
          iglesiaId: 1,
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'SO',
          esMiembroVerificado: true,
          role: UserRole.platformAdmin,
          isReadOnly: true,
        ),
      );

      bool? resultadoPermiso;

      await tester.pumpWidget(
        createTestWidget(
          userProvider: userProvider,
          child: Builder(
            builder: (ctx) {
              return ElevatedButton(
                onPressed: () {
                  resultadoPermiso =
                      ModalRestriccionDonacion.verificarDonacionGeneral(
                    context: ctx,
                  );
                },
                child: const Text('EVALUAR_DONACION'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('EVALUAR_DONACION'));
      await tester.pumpAndSettle();

      expect(resultadoPermiso, isFalse);
      expect(find.text('Solo lectura'), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(find.text('Solo lectura'), findsNothing);
    });
  });
}
