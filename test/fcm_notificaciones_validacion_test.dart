import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';
import 'package:atrio/servicios/device_notification_service.dart';

class _MockFcmAtrioApi extends AtrioApi {
  int registerDeviceCallCount = 0;
  int unregisterDeviceCallCount = 0;
  int meCallCount = 0;
  Map<String, dynamic>? lastDevicePayload;

  _MockFcmAtrioApi() : super(baseUrl: 'https://test.atrioapp.org') {
    token = 'mock_jwt_token';
  }

  @override
  Future<Map<String, dynamic>> registerDevice(Map<String, dynamic> data) async {
    registerDeviceCallCount++;
    lastDevicePayload = Map<String, dynamic>.from(data);
    return {'success': true, 'message': 'Device registered'};
  }

  @override
  Future<Map<String, dynamic>> unregisterDevice(Map<String, dynamic> data) async {
    unregisterDeviceCallCount++;
    return {'success': true, 'message': 'Device unregistered'};
  }

  @override
  Future<Map<String, dynamic>> me() async {
    meCallCount++;
    return {
      'id': 10,
      'name': 'Usuario FCM Test',
      'email': 'fcm@test.com',
      'role': 'member',
      'membership_status': 'approved',
      'church': {
        'id': 7,
        'name': 'Iglesia Central de Fe',
        'has_active_subscription': true,
      },
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Validación Integral de Firebase Cloud Messaging (FCM)', () {
    test('1. Integridad de Archivos de Configuración Nativa', () {
      // 1.1 google-services.json en Android
      final googleServicesFile = File('android/app/google-services.json');
      expect(googleServicesFile.existsSync(), isTrue,
          reason: 'El archivo android/app/google-services.json debe existir.');

      final jsonContent = jsonDecode(googleServicesFile.readAsStringSync());
      expect(jsonContent, isA<Map<String, dynamic>>());
      expect(jsonContent['project_info'], isNotNull);
      expect(jsonContent['client'], isNotNull);

      // 1.2 AndroidManifest.xml con permisos de notificación y canal
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);
      final manifestContent = manifestFile.readAsStringSync();
      expect(
        manifestContent.contains('android.permission.POST_NOTIFICATIONS'),
        isTrue,
        reason: 'AndroidManifest debe declarar POST_NOTIFICATIONS para Android 13+.',
      );
      expect(
        manifestContent.contains('atrio_general_notifications'),
        isTrue,
        reason: 'AndroidManifest debe configurar el canal predeterminado de notificaciones.',
      );

      // 1.3 build.gradle.kts con plugin de Google Services
      final buildGradleFile = File('android/app/build.gradle.kts');
      expect(buildGradleFile.existsSync(), isTrue);
      final gradleContent = buildGradleFile.readAsStringSync();
      expect(
        gradleContent.contains('com.google.gms.google-services'),
        isTrue,
        reason: 'build.gradle.kts debe aplicar el plugin de Google Services.',
      );

      // 1.4 Info.plist en iOS con modos de fondo
      final infoPlistFile = File('ios/Runner/Info.plist');
      expect(infoPlistFile.existsSync(), isTrue);
      final plistContent = infoPlistFile.readAsStringSync();
      expect(
        plistContent.contains('remote-notification'),
        isTrue,
        reason: 'Info.plist debe declarar remote-notification en UIBackgroundModes.',
      );
    });

    test('2. Gestión de Tokens en DeviceNotificationService (getOrCreate y setFcmToken)', () async {
      final service = DeviceNotificationService.instance;

      // Generar o recuperar token inicial
      final tokenInicial = await service.getOrCreateDeviceToken();
      expect(tokenInicial, isNotEmpty);
      expect(tokenInicial.startsWith('atrio_'), isTrue);

      // Simular llegada de token real de FCM (ej. desde Firebase)
      const tokenFCMReal = 'fcm_mock_token_abc_123456789_xyz';
      await service.setFcmToken(tokenFCMReal);

      final tokenActualizado = await service.getOrCreateDeviceToken();
      expect(tokenActualizado, equals(tokenFCMReal));

      // Verificar persistencia en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('atrio_device_push_token'), equals(tokenFCMReal));
    });

    test('3. Sincronización de Dispositivo con Backend Odoo (POST /devices y DELETE /devices)', () async {
      final mockApi = _MockFcmAtrioApi();
      final service = DeviceNotificationService.instance;

      // 3.1 Registrar dispositivo
      const tokenPrueba = 'fcm_token_para_odoo_test';
      final okRegister = await service.registerDeviceWithBackend(
        mockApi,
        customToken: tokenPrueba,
      );

      expect(okRegister, isTrue);
      expect(mockApi.registerDeviceCallCount, equals(1));
      expect(mockApi.lastDevicePayload, isNotNull);
      expect(mockApi.lastDevicePayload!['token'], equals(tokenPrueba));
      expect(mockApi.lastDevicePayload!['platform'], equals(service.platformName));
      expect(mockApi.lastDevicePayload!['device_name'], contains('ATRIO Mobile App'));

      // 3.2 Idempotencia: el segundo llamado con el mismo token no genera peticiones redundantes
      final okRepetido = await service.registerDeviceWithBackend(
        mockApi,
        customToken: tokenPrueba,
      );
      expect(okRepetido, isTrue);
      expect(mockApi.registerDeviceCallCount, equals(1),
          reason: 'No debe llamar nuevamente si el token ya está sincronizado en sesión.');

      // 3.3 Desregistro de dispositivo (al hacer logout)
      final okUnregister = await service.unregisterDeviceFromBackend(mockApi);
      expect(okUnregister, isTrue);
      expect(mockApi.unregisterDeviceCallCount, equals(1));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('atrio_last_registered_push_token'), isNull,
          reason: 'Debe remover la bandera del token registrado al desasociar.');
    });

    testWidgets('4. Procesamiento Reactivo de Notificación Push de Membresía Aprobada', (tester) async {
      final mockApi = _MockFcmAtrioApi();
      final userProvider = UserProvider(api: mockApi);
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 5,
          nombre: 'Hermano Aprobación',
          email: 'hermano@atrio.org',
          iglesiaActual: 'Sin iglesia seleccionada',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'H',
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
            home: const Scaffold(body: Text('Pantalla Esperando Aprobación')),
            routes: {
              InicioAtrioScreen.routeName: (_) =>
                  const Scaffold(body: Text('Pantalla InicioAtrioScreen Destino')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Esperando Aprobación'), findsOneWidget);

      // Simular llegada de push message FCM de Odoo 19
      await DeviceNotificationService.instance.handlePushMessage(
        {
          'type': 'membership',
          'status': 'approved',
          'church_name': 'Iglesia Central de Fe',
        },
        userProvider: userProvider,
        navigatorKey: navKey,
      );

      await tester.pumpAndSettle();

      // Debe haber refrescado el perfil en Odoo
      expect(mockApi.meCallCount, equals(1));
      // Debe haber navegado reactivamente al HomeScreen
      expect(find.text('Pantalla InicioAtrioScreen Destino'), findsOneWidget);
    });

    test('5. Resiliencia ante Push con Datos Incompletos o Desconocidos', () async {
      final mockApi = _MockFcmAtrioApi();
      final userProvider = UserProvider(api: mockApi);
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 10,
          nombre: 'Test User',
          email: 'test@atrio.org',
          iglesiaActual: 'Iglesia Central',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'T',
          esMiembroVerificado: true,
          role: UserRole.member,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final llamadasIniciales = mockApi.meCallCount;

      // Notificación desconocida o sin tipo
      await DeviceNotificationService.instance.handlePushMessage(
        {
          'type': 'custom_unknown_notification',
          'data': 'payload_arbitrario',
        },
        userProvider: userProvider,
      );

      // No debe disparar refresco forzado ni romper la ejecución
      expect(mockApi.meCallCount, equals(llamadasIniciales));
    });
  });
}
