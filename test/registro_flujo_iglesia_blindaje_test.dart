import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/data/app_config.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/ajustes_provider.dart';
import 'package:atrio/screens/crear_cuenta_screen.dart';
import 'package:atrio/screens/seleccionar_iglesia_screen.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atrio/l10n/app_localizations.dart';

class _MockRegistrationAtrioApi extends AtrioApi {
  Map<String, dynamic>? lastRegisterPayload;
  Map<String, dynamic> registerResponse = {'success': true};
  Map<String, dynamic> loginResponse = {};

  _MockRegistrationAtrioApi({
    required super.baseUrl,
    Map<String, dynamic>? initialLoginResponse,
  }) {
    loginResponse = initialLoginResponse ?? {
      'token': 'mock_jwt_token',
      'user': {
        'id': 101,
        'name': 'Nuevo Creyente',
        'email': 'nuevo@test.com',
        'role': 'user',
        'membership_status': 'none',
      },
      'church': {
        'id': 1,
        'name': 'Atrio Demo',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> registerMember(Map<String, dynamic> data) async {
    lastRegisterPayload = Map<String, dynamic>.from(data);
    return registerResponse;
  }

  @override
  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    String deviceName = 'Flutter App',
  }) async {
    token = 'mock_jwt_token';
    return loginResponse;
  }

  @override
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String deviceName = 'Flutter App',
  }) async {
    token = 'mock_google_jwt_token';
    return {
      'created': true,
      'token': 'mock_google_jwt_token',
      'user': {
        'id': 105,
        'name': 'Google New User',
        'email': 'googlenew@test.com',
        'role': 'user',
        'membership_status': 'none',
      },
      'church': {
        'id': 1,
        'name': 'Atrio Demo',
      },
    };
  }
}

Widget createTestApp({
  required Widget child,
  required UserProvider userProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ChangeNotifierProvider<IglesiaProvider>(create: (_) => IglesiaProvider()),
      ChangeNotifierProvider<AjustesProvider>(create: (_) => AjustesProvider()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: child,
      routes: {
        SeleccionarIglesiaScreen.routeName: (_) =>
            const Scaffold(body: Text('Pantalla SeleccionarIglesiaScreen')),
        InicioAtrioScreen.routeName: (_) =>
            const Scaffold(body: Text('Pantalla HomeScreen Destino')),
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Auditoría y Blindaje del Flujo de Registro por Correo y Clave', () {
    test('1. Auditoría: registerMember y UserProvider.register NO inyectan iglesia demo por defecto', () async {
      final mockApi = _MockRegistrationAtrioApi(baseUrl: 'https://test.atrioapp.org');
      final userProvider = UserProvider(api: mockApi);

      await userProvider.register(
        nombre: 'Nuevo Miembro',
        email: 'nuevo@atrio.org',
        password: 'Password123!',
        telefono: '8095551234',
      );

      expect(mockApi.lastRegisterPayload, isNotNull);
      // Aseguramos que NO se envíe 'church_id' por defecto
      expect(mockApi.lastRegisterPayload!.containsKey('church_id'), isFalse);
      expect(mockApi.lastRegisterPayload!['name'], equals('Nuevo Miembro'));
      expect(mockApi.lastRegisterPayload!['email'], equals('nuevo@atrio.org'));
    });

    test('2. Lógica de Estado: UserModel.fromOdooJson filtra "Atrio Demo" e iglesias default para usuarios nuevos', () {
      // Simulación de respuesta de Odoo 19 donde backend asigna iglesia 1 ("Atrio Demo") a nuevo usuario
      final odooPayload = {
        'token': 'tok_123',
        'user': {
          'id': 200,
          'name': 'Carlos Perez',
          'email': 'carlos@test.com',
          'role': 'user',
          'membership_status': 'none',
          'church_id': 1,
          'church_name': 'Atrio Demo',
        },
        'church': {
          'id': 1,
          'name': 'Atrio Demo',
        },
      };

      final user = UserModel.fromOdooJson(odooPayload);

      // Verificaciones críticas de aislamiento de iglesia
      expect(user.iglesiaId, isNull);
      expect(user.iglesiaActual, equals('Sin iglesia seleccionada'));
      expect(user.hasChurchAssigned, isFalse);
      expect(user.hasSelectedOrLinkedChurch, isFalse);
      expect(user.selectedChurch, isNull);
      expect(UserModel.isDefaultOrDemoChurchName('Atrio Demo'), isTrue);
      expect(UserModel.isDefaultOrDemoChurchName('Iglesia Atrio'), isTrue);
      expect(UserModel.isDefaultOrDemoChurchName('Sin iglesia seleccionada'), isTrue);
      expect(UserModel.isDefaultOrDemoChurchName('Iglesia Monte Calvario'), isFalse);
    });

    test('3. Máquina de Estados: resolveStage retorna chooseChurch y bloquea memberHome ante iglesias demo', () {
      final meDemo = {
        'id': 200,
        'role': 'user',
        'membership_status': 'none',
        'church': {
          'id': AppConfig.defaultPlatformChurchId,
          'name': 'Atrio Demo',
          'has_active_subscription': false,
        },
      };

      final stage = resolveStage(meDemo);
      expect(stage, equals(AppStage.chooseChurch));
    });

    testWidgets('4. Blindaje de Enrutamiento: CrearCuentaScreen navega estrictamente a SeleccionarIglesiaScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockApi = _MockRegistrationAtrioApi(baseUrl: 'https://test.atrioapp.org');
      final userProvider = UserProvider(api: mockApi);

      await tester.pumpWidget(
        createTestApp(
          child: const CrearCuentaScreen(),
          userProvider: userProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Completar formulario con los 5 TextFields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(5));

      await tester.enterText(textFields.at(0), 'Usuario Prueba');
      await tester.enterText(textFields.at(1), 'prueba@atrio.org');
      await tester.enterText(textFields.at(2), '8091234567');
      await tester.enterText(textFields.at(3), 'ClaveSegura123');
      await tester.enterText(textFields.at(4), 'ClaveSegura123');

      // Aceptar términos checkbox
      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Presionar botón Crear cuenta
      final crearBtn = find.widgetWithText(ElevatedButton, 'Crear cuenta');
      await tester.ensureVisible(crearBtn);
      await tester.tap(crearBtn);
      await tester.pumpAndSettle();

      // Debe aparecer el modal de Cuenta Registrada
      expect(find.text('¡Cuenta Registrada!'), findsOneWidget);

      // Presionar Iniciar sesión ahora
      final loginNowBtn = find.widgetWithText(ElevatedButton, 'Iniciar sesión ahora');
      expect(loginNowBtn, findsOneWidget);
      await tester.tap(loginNowBtn);
      await tester.pumpAndSettle();

      // BLINDAJE: Debe estar en SeleccionarIglesiaScreen y NO en HomeScreen Destino
      expect(find.text('Pantalla SeleccionarIglesiaScreen'), findsOneWidget);
      expect(find.text('Pantalla HomeScreen Destino'), findsNothing);
    });

    test('5. Consistencia: loginWithGoogle con usuario nuevo (created == true) y church demo deja church libre', () async {
      final mockApi = _MockRegistrationAtrioApi(baseUrl: 'https://test.atrioapp.org');
      final userProvider = UserProvider(api: mockApi);

      final res = await userProvider.loginWithGoogle(idToken: 'mock_token');
      expect(res?['created'], isTrue);

      final user = userProvider.currentUser;
      expect(user, isNotNull);
      expect(user!.iglesiaId, isNull);
      expect(user.iglesiaActual, equals('Sin iglesia seleccionada'));
      expect(user.hasChurchAssigned, isFalse);
      expect(user.hasSelectedOrLinkedChurch, isFalse);
      expect(user.selectedChurch, isNull);
      expect(userProvider.currentStage, equals(AppStage.chooseChurch));
    });
  });
}
