import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/main.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/esperando_aprobacion_screen.dart';
import 'package:atrio/screens/nueva_solicitud_screen.dart';
import 'package:atrio/screens/tipos_solicitud_screen.dart';
import 'package:atrio/screens/tradicion_cristiana_screen.dart';
import 'package:atrio/widgets/alerta_auto_dismiss.dart';

void main() {
  UserModel createTestUser({
    int id = 1,
    String nombre = 'Test User',
    String email = 'test@atrio.org',
    String iglesiaActual = 'Iglesia Atrio',
    int? iglesiaId,
    String fechaRegistro = '2026-01-01',
    String avatarIniciales = 'TU',
    bool esMiembroVerificado = true,
    UserRole role = UserRole.user,
    Set<String> permissions = const {},
    bool isReadOnly = false,
    String membershipStatus = 'none',
    int? requestedChurchId,
  }) {
    return UserModel(
      id: id,
      nombre: nombre,
      email: email,
      iglesiaActual: iglesiaActual,
      iglesiaId: iglesiaId,
      fechaRegistro: fechaRegistro,
      avatarIniciales: avatarIniciales,
      esMiembroVerificado: esMiembroVerificado,
      role: role,
      permissions: permissions,
      isReadOnly: isReadOnly,
      membershipStatus: membershipStatus,
      requestedChurchId: requestedChurchId,
    );
  }

  Widget buildTestApp({
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
          TiposSolicitudScreen.routeName: (_) => const TiposSolicitudScreen(),
          NuevaSolicitudScreen.routeName: (_) => const NuevaSolicitudScreen(),
          EsperandoAprobacionScreen.routeName: (_) => const Scaffold(
                body: Text('PANTALLA_ESPERANDO_APROBACION'),
              ),
          TradicionCristianaScreen.routeName: (_) => const Scaffold(
                body: Text('PANTALLA_SELECCIONAR_IGLESIA'),
              ),
        },
        home: Scaffold(body: child),
      ),
    );
  }

  group('Manejo de Estado del Provider - Validación de Iglesia Aprobada', () {
    test('UserModel getters reflejan churchStatus e isChurchApproved', () {
      final userPendiente = createTestUser(
        id: 1,
        nombre: 'Hermano Pendiente',
        email: 'pendiente@atrio.org',
        iglesiaActual: 'Comunidad Gracia',
        iglesiaId: 10,
        membershipStatus: 'membership_pending',
      );

      expect(userPendiente.churchStatus, equals('membership_pending'));
      expect(userPendiente.isMembershipPending, isTrue);
      expect(userPendiente.hasChurchAssigned, isTrue);
      expect(userPendiente.isChurchApproved, isFalse);

      final userAprobado = createTestUser(
        id: 2,
        nombre: 'Hermano Aprobado',
        email: 'aprobado@atrio.org',
        iglesiaActual: 'Comunidad Gracia',
        iglesiaId: 10,
        membershipStatus: 'approved',
        role: UserRole.member,
      );

      expect(userAprobado.churchStatus, equals('approved'));
      expect(userAprobado.isMembershipPending, isFalse);
      expect(userAprobado.hasChurchAssigned, isTrue);
      expect(userAprobado.isChurchApproved, isTrue);

      final userSinIglesia = createTestUser(
        id: 3,
        nombre: 'Visitante',
        email: 'visitante@atrio.org',
        membershipStatus: 'none',
        iglesiaId: null,
      );

      expect(userSinIglesia.hasChurchAssigned, isFalse);
      expect(userSinIglesia.isChurchApproved, isFalse);
    });

    test('UserProvider evalúa canSubmitSolicitud e isChurchApproved reactivamente', () {
      final userProvider = UserProvider();
      userProvider.api.token = 'valid_token';

      // 1. Usuario con membresía pendiente
      userProvider.setCurrentUserForTesting(
        createTestUser(
          id: 101,
          nombre: 'Carlos Google',
          email: 'carlos@gmail.com',
          iglesiaId: 5,
          membershipStatus: 'membership_pending',
        ),
      );

      expect(userProvider.churchStatus, equals('membership_pending'));
      expect(userProvider.isMembershipPending, isTrue);
      expect(userProvider.isChurchApproved, isFalse);
      expect(userProvider.canSubmitSolicitud, isFalse);

      // 2. Usuario con membresía aprobada
      userProvider.setCurrentUserForTesting(
        createTestUser(
          id: 102,
          nombre: 'Ana Miembro',
          email: 'ana@gmail.com',
          iglesiaId: 5,
          membershipStatus: 'approved',
          role: UserRole.member,
        ),
      );

      expect(userProvider.isChurchApproved, isTrue);
      expect(userProvider.canSubmitSolicitud, isTrue);

      // 3. Usuario en modo solo lectura
      userProvider.setCurrentUserForTesting(
        createTestUser(
          id: 103,
          nombre: 'Auditor',
          email: 'auditor@gmail.com',
          iglesiaId: 5,
          membershipStatus: 'approved',
          role: UserRole.member,
          isReadOnly: true,
        ),
      );

      expect(userProvider.canSubmitSolicitud, isFalse);
    });
  });

  group('ModalRestriccionSolicitud y Validación en Vistas', () {
    testWidgets(
        'TiposSolicitudScreen: Bloquea navegación a nueva_solicitud_screen cuando iglesia está pendiente de aprobación',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.api.token = 'test_token';
      userProvider.setCurrentUserForTesting(
        createTestUser(
          id: 50,
          nombre: 'Usuario Pendiente',
          email: 'user@gmail.com',
          iglesiaId: 12,
          membershipStatus: 'membership_pending',
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          userProvider: userProvider,
          child: const TiposSolicitudScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Pulsar la primera opción de solicitud ('Oración')
      final opcionOracion = find.text('Petición de oración');
      expect(opcionOracion, findsOneWidget);
      await tester.tap(opcionOracion);
      await tester.pumpAndSettle();

      // Verificar que se mostró el diálogo restrictivo de membresía pendiente
      expect(find.text('Membresía pendiente de aprobación'), findsOneWidget);
      expect(find.text('Ver estado de solicitud'), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);

      // Pulsar "Ver estado de solicitud" para redirigir a EsperandoAprobacionScreen
      await tester.tap(find.text('Ver estado de solicitud'));
      await tester.pumpAndSettle();

      expect(find.text('PANTALLA_ESPERANDO_APROBACION'), findsOneWidget);
    });

    testWidgets(
        'TiposSolicitudScreen: Muestra alerta con auto-dismiss cuando el usuario no tiene iglesia asignada',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.api.token = 'test_token';
      userProvider.setCurrentUserForTesting(
        createTestUser(
          id: 51,
          nombre: 'Usuario Sin Iglesia',
          email: 'user2@gmail.com',
          membershipStatus: 'none',
          iglesiaId: null,
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          userProvider: userProvider,
          child: const TiposSolicitudScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Pulsar una opción de solicitud
      final opcionOracion = find.text('Petición de oración');
      await tester.tap(opcionOracion);
      await tester.pump(); // Render SnackBar

      // Verificar que muestra la advertencia requerida
      expect(
        find.text(
          'Debes tener una iglesia asignada para enviar solicitudes o peticiones pastorales.',
        ),
        findsOneWidget,
      );
      expect(find.text('Seleccionar iglesia'), findsOneWidget);

      // Avanzar el temporizador para verificar que la alerta se desvanece automáticamente (auto-dismiss)
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Debes tener una iglesia asignada para enviar solicitudes o peticiones pastorales.',
        ),
        findsNothing,
      );
    });

    testWidgets(
        'AlertaAutoDismiss: Se desvanece automáticamente tras el tiempo especificado (auto-dismiss)',
        (tester) async {
      bool desvanecido = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertaAutoDismiss(
              mensaje: 'Alerta de prueba',
              duracion: const Duration(seconds: 1),
              onDismissed: () {
                desvanecido = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Alerta de prueba'), findsOneWidget);
      expect(desvanecido, isFalse);

      // Avanzar el tiempo más allá de la duración para activar el auto-dismiss
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(desvanecido, isTrue);
    });

    testWidgets(
        'NuevaSolicitudScreen: Al entrar directamente con iglesia pendiente se muestra diálogo y bloquea acceso',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.api.token = 'test_token';
      userProvider.setCurrentUserForTesting(
        createTestUser(
          id: 55,
          nombre: 'Directo Pendiente',
          email: 'directo@gmail.com',
          iglesiaId: 10,
          membershipStatus: 'membership_pending',
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          userProvider: userProvider,
          child: Builder(
            builder: (ctx) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(ctx, NuevaSolicitudScreen.routeName);
                },
                child: const Text('ABRIR_SOLICITUD'),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('ABRIR_SOLICITUD'));
      await tester.pumpAndSettle();

      // Debe mostrar el diálogo de membresía pendiente
      expect(find.text('Membresía pendiente de aprobación'), findsOneWidget);

      // Al cerrar el diálogo (pulsar Entendido), la pantalla de formulario se cierra (pop)
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      // Regresó a la pantalla previa, el formulario no se mantiene abierto
      expect(find.text('ABRIR_SOLICITUD'), findsOneWidget);
    });
  });
}
