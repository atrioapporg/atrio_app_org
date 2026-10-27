import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/elegir_camino_iglesia_screen.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';

Widget createTestApp(Widget child, UserProvider userProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
    ],
    child: MaterialApp(
      home: child,
      routes: {
        InicioAtrioScreen.routeName: (_) =>
            const Scaffold(body: Text('HomeScreen Destino')),
        ElegirCaminoIglesiaScreen.routeName: (_) =>
            const ElegirCaminoIglesiaScreen(),
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bypass de Navegación y Auditoría de Iglesia Previa', () {
    test('UserModel.hasSelectedOrLinkedChurch detecta iglesias asignadas, pendientes o guardadas', () {
      // 1. Usuario sin iglesia
      final userSinIglesia = UserModel(
        id: 1,
        nombre: 'Usuario Libre',
        email: 'libre@test.com',
        iglesiaActual: 'Sin iglesia seleccionada',
        fechaRegistro: '2026-01-01',
        avatarIniciales: 'U',
        esMiembroVerificado: false,
        role: UserRole.user,
      );
      expect(userSinIglesia.hasSelectedOrLinkedChurch, isFalse);

      // 2. Usuario con iglesia asignada (iglesiaId > 0)
      final userConIglesia = userSinIglesia.copyWith(iglesiaId: 10, iglesiaActual: 'Iglesia Central');
      expect(userConIglesia.hasSelectedOrLinkedChurch, isTrue);

      // 3. Usuario con solicitud pendiente de membresía
      final userPendiente = userSinIglesia.copyWith(
        membershipStatus: 'membership_pending',
        requestedChurchId: 25,
      );
      expect(userPendiente.hasSelectedOrLinkedChurch, isTrue);

      // 4. Usuario con solicitud de cambio pendiente
      final userCambio = userSinIglesia.copyWith(
        membershipStatus: 'change_pending',
      );
      expect(userCambio.hasSelectedOrLinkedChurch, isTrue);
    });

    test('resolveStage retorna memberHome si el payload contiene iglesia vinculada (evita chooseChurch)', () {
      // Usuario autenticado con rol 'user' pero que ya tiene una iglesia vinculada en Odoo
      final meConIglesia = {
        'id': 100,
        'name': 'Hermano Prueba',
        'role': 'user',
        'church': {
          'id': 42,
          'name': 'Iglesia Buenas Nuevas',
          'has_active_subscription': false,
        },
      };

      final stage = resolveStage(meConIglesia);
      expect(stage, AppStage.memberHome);
    });

    testWidgets(
      'ElegirCaminoIglesiaScreen ejecuta bypass automático a InicioAtrioScreen si el usuario ya tiene iglesia',
      (tester) async {
        final userProvider = UserProvider(
          api: AtrioApi(baseUrl: 'https://test.atrioapp.org'),
        );
        userProvider.setCurrentUserForTesting(
          UserModel(
            id: 2,
            nombre: 'Juan',
            email: 'juan@correo.com',
            iglesiaActual: 'Iglesia Monte Sion',
            iglesiaId: 15,
            fechaRegistro: '2026-01-01',
            avatarIniciales: 'J',
            esMiembroVerificado: true,
            role: UserRole.member,
          ),
        );

        await tester.pumpWidget(
          createTestApp(const ElegirCaminoIglesiaScreen(), userProvider),
        );
        // Procesar postFrameCallback y navegación por pushReplacementNamed
        await tester.pumpAndSettle();

        expect(find.text('HomeScreen Destino'), findsOneWidget);
        expect(find.text('Unirme a una iglesia'), findsNothing);
      },
    );

    testWidgets(
      'ElegirCaminoIglesiaScreen ejecuta bypass automático si el usuario tiene solicitud pendiente de aprobación',
      (tester) async {
        final userProvider = UserProvider(
          api: AtrioApi(baseUrl: 'https://test.atrioapp.org'),
        );
        userProvider.setCurrentUserForTesting(
          UserModel(
            id: 3,
            nombre: 'Ana',
            email: 'ana@correo.com',
            iglesiaActual: 'Sin iglesia seleccionada',
            membershipStatus: 'membership_pending',
            requestedChurchId: 77,
            fechaRegistro: '2026-01-01',
            avatarIniciales: 'A',
            esMiembroVerificado: false,
            role: UserRole.user,
          ),
        );

        await tester.pumpWidget(
          createTestApp(const ElegirCaminoIglesiaScreen(), userProvider),
        );
        await tester.pumpAndSettle();

        expect(find.text('HomeScreen Destino'), findsOneWidget);
        expect(find.text('Unirme a una iglesia'), findsNothing);
      },
    );
  });
}
