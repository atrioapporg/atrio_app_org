import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/servicios/device_notification_service.dart';
import 'package:atrio/screens/elegir_camino_iglesia_screen.dart';
import 'package:atrio/screens/esperando_aprobacion_screen.dart';
import 'package:atrio/screens/iglesia_pendiente_activacion_screen.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';

class MockAtrioApi extends AtrioApi {
  MockAtrioApi() : super(baseUrl: 'https://test.atrioapp.org');
  int meCallCount = 0;

  @override
  bool get isAuthenticated => true;

  @override
  Future<Map<String, dynamic>> me() async {
    meCallCount++;
    return {
      'id': 1,
      'name': 'Usuario Test',
      'email': 'test@atrio.org',
      'role': 'member',
      'membership_status': 'approved',
      'church': {
        'id': 10,
        'name': 'Iglesia Test',
        'has_active_subscription': true,
      },
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Etapa 5 - Enrutamiento Inicial, Ciclo de Vida y Notificaciones Push', () {
    test('Resolución de ruta según stage para el arranque inicial', () {
      String getRouteForStage(AppStage stage) {
        switch (stage) {
          case AppStage.chooseChurch:
            return ElegirCaminoIglesiaScreen.routeName;
          case AppStage.waitingApproval:
            return EsperandoAprobacionScreen.routeName;
          case AppStage.churchPendingActivation:
            return IglesiaPendienteActivacionScreen.routeName;
          case AppStage.welcome:
          case AppStage.memberHome:
          case AppStage.adminHome:
          case AppStage.platformAdmin:
            return InicioAtrioScreen.routeName;
        }
      }

      expect(getRouteForStage(AppStage.chooseChurch), ElegirCaminoIglesiaScreen.routeName);
      expect(getRouteForStage(AppStage.waitingApproval), EsperandoAprobacionScreen.routeName);
      expect(getRouteForStage(AppStage.churchPendingActivation), IglesiaPendienteActivacionScreen.routeName);
      expect(getRouteForStage(AppStage.memberHome), InicioAtrioScreen.routeName);
      expect(getRouteForStage(AppStage.adminHome), InicioAtrioScreen.routeName);
      expect(getRouteForStage(AppStage.platformAdmin), InicioAtrioScreen.routeName);
    });

    testWidgets('DeviceNotificationService procesa push de membresía aprobada', (tester) async {
      final mockApi = MockAtrioApi();
      final userProvider = UserProvider(api: mockApi);
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 1,
          nombre: 'Hermano Pedro',
          email: 'pedro@correo.com',
          iglesiaActual: 'Sin iglesia',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'P',
          esMiembroVerificado: false,
          role: UserRole.user,
          membershipStatus: 'membership_pending',
        ),
      );

      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: MaterialApp(
            navigatorKey: navKey,
            home: const Scaffold(body: Text('Pantalla Espera')),
            routes: {
              InicioAtrioScreen.routeName: (_) =>
                  const Scaffold(body: Text('Inicio Atrio - Membresía Activa')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Espera'), findsOneWidget);

      // Simular llegada de notificación push de Odoo 19: membership approved
      await DeviceNotificationService.instance.handlePushMessage(
        {
          'type': 'membership',
          'status': 'approved',
        },
        userProvider: userProvider,
        navigatorKey: navKey,
      );

      await tester.pumpAndSettle();

      // Debe haber invocado refreshUserProfile (me() en mockApi)
      expect(mockApi.meCallCount, 1);
      // Debe haber navegado a InicioAtrioScreen
      expect(find.text('Inicio Atrio - Membresía Activa'), findsOneWidget);
    });

    test('DeviceNotificationService ignora push de otros tipos sin romper el flujo', () async {
      final mockApi = MockAtrioApi();
      final userProvider = UserProvider(api: mockApi);
      await Future.delayed(const Duration(milliseconds: 50));
      final initialCalls = mockApi.meCallCount;

      await DeviceNotificationService.instance.handlePushMessage(
        {
          'type': 'general_announcement',
          'title': 'Culto especial',
        },
        userProvider: userProvider,
      );

      // No debe haber disparado llamadas adicionales a me()
      expect(mockApi.meCallCount, initialCalls);
    });
  });
}
