import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/elegir_camino_iglesia_screen.dart';
import 'package:atrio/screens/esperando_aprobacion_screen.dart';
import 'package:atrio/screens/iglesia_pendiente_activacion_screen.dart';
import 'package:atrio/screens/crear_mi_iglesia_screen.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';
import 'package:atrio/screens/tradicion_cristiana_screen.dart';

Widget createTestApp(Widget child, UserProvider userProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
    ],
    child: MaterialApp(
      home: child,
      routes: {
        InicioAtrioScreen.routeName: (_) =>
            const Scaffold(body: Text('Inicio Atrio Mock')),
        ElegirCaminoIglesiaScreen.routeName: (_) =>
            const ElegirCaminoIglesiaScreen(),
        TradicionCristianaScreen.routeName: (_) =>
            const Scaffold(body: Text('Tradición Cristiana Mock')),
        EsperandoAprobacionScreen.routeName: (_) =>
            const EsperandoAprobacionScreen(),
        IglesiaPendienteActivacionScreen.routeName: (_) =>
            const IglesiaPendienteActivacionScreen(),
        CrearMiIglesiaScreen.routeName: (_) => const CrearMiIglesiaScreen(),
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Etapa 3 - Pantallas de Estado y Espera', () {
    testWidgets(
      'ElegirCaminoIglesiaScreen muestra saludo, opción de unirse y aviso web para líderes',
      (tester) async {
        final userProvider = UserProvider(
          api: AtrioApi(baseUrl: 'https://test.atrioapp.org'),
        );
        userProvider.setCurrentUserForTesting(
          UserModel(
            id: 1,
            nombre: 'Mateo',
            email: 'mateo@correo.com',
            iglesiaActual: 'Sin iglesia seleccionada',
            fechaRegistro: '2026-01-01',
            avatarIniciales: 'M',
            esMiembroVerificado: false,
            role: UserRole.user,
          ),
        );

        await tester.pumpWidget(
          createTestApp(const ElegirCaminoIglesiaScreen(), userProvider),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('¡Bienvenido a Atrio, Mateo!'),
          findsOneWidget,
        );
        expect(find.text('Unirme a una iglesia'), findsOneWidget);
        expect(find.text('Conectarme a mi iglesia'), findsOneWidget);
        expect(find.text('Mi iglesia no está en Atrio'), findsOneWidget);
        expect(find.text('Registrar mi iglesia'), findsNothing);
        expect(find.text('Crear congregación'), findsNothing);
      },
    );

    testWidgets(
      'ElegirCaminoIglesiaScreen navega a TradicionCristianaScreen al presionar Conectarme a mi iglesia',
      (tester) async {
        final userProvider = UserProvider(
          api: AtrioApi(baseUrl: 'https://test.atrioapp.org'),
        );
        userProvider.setCurrentUserForTesting(
          UserModel(
            id: 1,
            nombre: 'Mateo',
            email: 'mateo@correo.com',
            iglesiaActual: 'Sin iglesia seleccionada',
            fechaRegistro: '2026-01-01',
            avatarIniciales: 'M',
            esMiembroVerificado: false,
            role: UserRole.user,
          ),
        );

        await tester.pumpWidget(
          createTestApp(const ElegirCaminoIglesiaScreen(), userProvider),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Conectarme a mi iglesia'));
        await tester.pumpAndSettle();

        expect(find.text('Tradición Cristiana Mock'), findsOneWidget);
      },
    );

    testWidgets(
      'EsperandoAprobacionScreen muestra congregación solicitada y estado pendiente',
      (tester) async {
        final userProvider = UserProvider(
          api: AtrioApi(baseUrl: 'https://test.atrioapp.org'),
        );
        userProvider.setCurrentUserForTesting(
          UserModel(
            id: 2,
            nombre: 'Sara',
            email: 'sara@correo.com',
            iglesiaActual: 'Sin iglesia',
            fechaRegistro: '2026-01-01',
            avatarIniciales: 'S',
            esMiembroVerificado: false,
            role: UserRole.user,
            membershipStatus: 'membership_pending',
            requestedChurchId: 10,
            requestedChurchData: {'name': 'Iglesia Central de la Fe'},
          ),
          rawMeData: {
            'role': 'user',
            'membership_status': 'membership_pending',
            'requested_church_id': 10,
            'requested_church': {'name': 'Iglesia Central de la Fe'},
          },
        );

        await tester.pumpWidget(
          createTestApp(const EsperandoAprobacionScreen(), userProvider),
        );
        await tester.pumpAndSettle();

        expect(find.text('Solicitud en Revisión'), findsOneWidget);
        expect(find.text('Iglesia Central de la Fe'), findsOneWidget);
        expect(find.text('Pendiente'), findsOneWidget);
        expect(find.text('Ir al Inicio de Atrio'), findsOneWidget);
        expect(find.text('Comprobar estado'), findsOneWidget);
        expect(find.text('Inicio'), findsOneWidget);
      },
    );

    testWidgets(
      'EsperandoAprobacionScreen permite navegar al inicio de Atrio sin quedar en un limbo',
      (tester) async {
        final userProvider = UserProvider(
          api: AtrioApi(baseUrl: 'https://test.atrioapp.org'),
        );
        userProvider.setCurrentUserForTesting(
          UserModel(
            id: 5,
            nombre: 'Mateo',
            email: 'mateo@atrio.com',
            iglesiaActual: 'Sin iglesia',
            fechaRegistro: '2026-01-01',
            avatarIniciales: 'M',
            esMiembroVerificado: false,
            role: UserRole.user,
            membershipStatus: 'membership_pending',
            requestedChurchId: 10,
            requestedChurchData: {'name': 'Iglesia Central de la Fe'},
          ),
        );

        await tester.pumpWidget(
          createTestApp(const EsperandoAprobacionScreen(), userProvider),
        );
        await tester.pumpAndSettle();

        final irInicioBtn = find.text('Ir al Inicio de Atrio');
        expect(irInicioBtn, findsOneWidget);
        await tester.tap(irInicioBtn);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'IglesiaPendienteActivacionScreen muestra congregación registrada y aviso de activación',
      (tester) async {
        final userProvider = UserProvider(
          api: AtrioApi(baseUrl: 'https://test.atrioapp.org'),
        );
        userProvider.setCurrentUserForTesting(
          UserModel(
            id: 3,
            nombre: 'Pastor David',
            email: 'david@pastor.com',
            iglesiaActual: 'Iglesia El Buen Pastor',
            iglesiaId: 55,
            fechaRegistro: '2026-01-01',
            avatarIniciales: 'PD',
            esMiembroVerificado: true,
            role: UserRole.churchAdmin,
            hasActiveSubscription: false,
          ),
          rawMeData: {
            'role': 'church_admin',
            'church': {
              'id': 55,
              'name': 'Iglesia El Buen Pastor',
              'has_active_subscription': false,
            },
          },
        );

        await tester.pumpWidget(
          createTestApp(const IglesiaPendienteActivacionScreen(), userProvider),
        );
        await tester.pumpAndSettle();

        expect(find.text('Iglesia en Proceso de Activación'), findsOneWidget);
        expect(find.text('Iglesia El Buen Pastor'), findsOneWidget);
        expect(find.text('Por activar'), findsOneWidget);
        expect(
          find.textContaining('atrioapp.odoo19rd.com/atrio/manage'),
          findsOneWidget,
        );
        expect(find.text('Comprobar activación'), findsOneWidget);
      },
    );

    testWidgets('CrearMiIglesiaScreen valida nombre obligatorio', (
      tester,
    ) async {
      final userProvider = UserProvider(
        api: AtrioApi(baseUrl: 'https://test.atrioapp.org'),
      );

      await tester.pumpWidget(
        createTestApp(const CrearMiIglesiaScreen(), userProvider),
      );
      await tester.pumpAndSettle();

      final botonRegistrar = find.text('Registrar mi congregación');
      expect(botonRegistrar, findsOneWidget);

      await tester.ensureVisible(botonRegistrar);
      await tester.tap(botonRegistrar);
      await tester.pumpAndSettle();

      expect(
        find.text('El nombre de la iglesia es obligatorio'),
        findsOneWidget,
      );
    });
  });
}
