import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/main.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/admin_provider.dart';
import 'package:atrio/providers/ajustes_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/esperando_aprobacion_screen.dart';
import 'package:atrio/screens/perfil_screen.dart';
import 'package:atrio/screens/seguimiento_solicitud_screen.dart';
import 'package:atrio/servicios/token_storage_service.dart';

class MockTokenStorageService extends TokenStorageService {
  String? _fakeToken = 'fake_valid_token';

  @override
  Future<String?> getAccessToken() async => _fakeToken;

  @override
  Future<void> saveAccessToken(String accessToken) async {
    _fakeToken = accessToken;
  }

  @override
  Future<void> clearTokens() async {
    _fakeToken = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Flujo UX PerfilScreen y SeguimientoSolicitudScreen con Iglesia Pendiente', () {
    testWidgets('PerfilScreen muestra aviso amigable al pulsar Mis solicitudes si la iglesia está pendiente',
        (tester) async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'valid_bearer_token',
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);

      // Usuario con membresía pendiente de aprobación
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 101,
          nombre: 'David Pendiente',
          email: 'david@correo.com',
          iglesiaActual: 'Sin iglesia',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'DP',
          esMiembroVerificado: false,
          role: UserRole.user,
          membershipStatus: 'membership_pending',
          requestedChurchId: 77,
          requestedChurchData: {'name': 'Iglesia Monte de Sion'},
        ),
        rawMeData: {
          'role': 'user',
          'membership_status': 'membership_pending',
          'requested_church_id': 77,
          'requested_church': {'name': 'Iglesia Monte de Sion'},
        },
      );

      expect(userProvider.isChurchApproved, isFalse);
      expect(userProvider.isMembershipPending, isTrue);

      final iglesiaProvider = IglesiaProvider();
      final ajustesProvider = AjustesProvider();
      final adminProvider = AdminProvider(api: api);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<IglesiaProvider>.value(value: iglesiaProvider),
            ChangeNotifierProvider<AjustesProvider>.value(value: ajustesProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ],
          child: MaterialApp(
            navigatorKey: MyApp.navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            routes: {
              EsperandoAprobacionScreen.routeName: (_) =>
                  const Scaffold(body: Text('Esperando Aprobacion Mock')),
              SeguimientoSolicitudScreen.routeName: (_) =>
                  const SeguimientoSolicitudScreen(),
            },
            home: const Scaffold(
              body: PerfilScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verificar que el menú muestra 'Mis solicitudes' con badge 'Pendiente'
      expect(find.text('Mis solicitudes'), findsOneWidget);
      expect(find.text('Pendiente'), findsWidgets);

      // Asegurar visibilidad y tocar en 'Mis solicitudes'
      await tester.ensureVisible(find.text('Mis solicitudes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mis solicitudes'));
      await tester.pumpAndSettle();

      // Debe abrirse el aviso amigable (Bottom Sheet) sin errores técnicos
      expect(find.text('Iglesia en revisión'), findsOneWidget);
      expect(
        find.textContaining(
          'Tu iglesia se encuentra actualmente en proceso de revisión por parte de la administración. Una vez aprobada, podrás gestionar y ver el historial de tus solicitudes y peticiones pastorales.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ver estado de solicitud'), findsWidgets);

      // NO debe haber saltado directamente a error de conexión
      expect(find.text('Error de conexión con el servidor'), findsNothing);
    });

    testWidgets('SeguimientoSolicitudScreen muestra Empty State amigable cuando la iglesia está en revisión',
        (tester) async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'valid_bearer_token',
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);

      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 102,
          nombre: 'Sara Espera',
          email: 'sara@correo.com',
          iglesiaActual: 'Sin iglesia',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'SE',
          esMiembroVerificado: false,
          role: UserRole.user,
          membershipStatus: 'membership_pending',
          requestedChurchId: 88,
          requestedChurchData: {'name': 'Iglesia Emanuel'},
        ),
        rawMeData: {
          'role': 'user',
          'membership_status': 'membership_pending',
          'requested_church_id': 88,
        },
      );

      expect(userProvider.isChurchApproved, isFalse);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: MaterialApp(
            navigatorKey: MyApp.navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            routes: {
              EsperandoAprobacionScreen.routeName: (_) =>
                  const Scaffold(body: Text('Esperando Aprobacion Mock')),
            },
            home: const SeguimientoSolicitudScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Debe mostrar el Empty State amigable
      expect(find.text('Iglesia en revisión'), findsOneWidget);
      expect(
        find.textContaining('Tu iglesia se encuentra actualmente en proceso de revisión'),
        findsOneWidget,
      );
      expect(find.text('Ver estado de solicitud'), findsOneWidget);

      // NO debe mostrar el mensaje técnico de error de conexión
      expect(find.text('Error de conexión con el servidor'), findsNothing);
      expect(find.text('Reintentar conexión con el servidor'), findsNothing);
    });

    testWidgets('PerfilScreen muestra SIEMPRE el estado de la iglesia a simple vista y notifica inmediatamente su aprobación',
        (tester) async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'valid_bearer_token',
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);
      final iglesiaProvider = IglesiaProvider();
      final ajustesProvider = AjustesProvider();
      final adminProvider = AdminProvider(api: api);

      // Usuario con iglesia pendiente de aprobación
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 301,
          nombre: 'David Pendiente',
          email: 'david@correo.com',
          iglesiaActual: 'Comunidad de Gracia',
          iglesiaId: 10,
          membershipStatus: 'membership_pending',
          fechaRegistro: '2026-10-25',
          avatarIniciales: 'DP',
          esMiembroVerificado: false,
          role: UserRole.user,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<IglesiaProvider>.value(value: iglesiaProvider),
            ChangeNotifierProvider<AjustesProvider>.value(value: ajustesProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ],
          child: MaterialApp(
            navigatorKey: MyApp.navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            routes: {
              EsperandoAprobacionScreen.routeName: (_) =>
                  const Scaffold(body: Text('Esperando Aprobacion Mock')),
            },
            home: const Scaffold(
              body: PerfilScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Estado visible a simple vista cuando está pendiente:
      // En el header:
      expect(find.text('Pendiente de aprobación'), findsOneWidget);
      // En la tarjeta dedicada de congregación:
      expect(find.text('Solicitud de membresía'), findsOneWidget);
      expect(find.text('En revisión'), findsOneWidget);
      expect(find.text('Comunidad de Gracia'), findsWidgets);

      // 2. Simular que la iglesia es aprobada inmediatamente en el backend
      userProvider.notifyChurchStatusChanged(
        status: 'approved',
        churchName: 'Comunidad de Gracia',
        isApproved: true,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Debe llegarle la notificación inmediatamente en pantalla
      expect(find.text('¡Tu iglesia ha sido aprobada!'), findsOneWidget);
      expect(
        find.textContaining('Ya eres miembro activo de Comunidad de Gracia'),
        findsOneWidget,
      );

      // 3. Al cambiar reactivamente el usuario a aprobado:
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 301,
          nombre: 'David Aprobado',
          email: 'david@correo.com',
          iglesiaActual: 'Comunidad de Gracia',
          iglesiaId: 10,
          membershipStatus: 'approved',
          fechaRegistro: '2026-10-25',
          avatarIniciales: 'DA',
          esMiembroVerificado: true,
          role: UserRole.member,
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar a simple vista el estado "Aprobada" tanto en header como en la tarjeta
      expect(find.text('Iglesia aprobada'), findsOneWidget);
      expect(find.text('Congregación activa'), findsOneWidget);
      expect(find.text('Aprobada'), findsOneWidget);
      expect(find.text('Ver detalles de iglesia'), findsOneWidget);
    });

    testWidgets('Usuario nuevo con iglesia seleccionada y aprobación pendiente en Odoo no muestra Sin congregación ni sugiere unirse a otra iglesia',
        (tester) async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'valid_bearer_token',
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);
      final iglesiaProvider = IglesiaProvider();
      final ajustesProvider = AjustesProvider();
      final adminProvider = AdminProvider(api: api);

      // Usuario exactamente como el caso reportado (ej. 'El Placer Motel' con 'Parroquia Nuestra Señora del Amparo')
      // pero aún sin aprobación por el backend de Odoo
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 501,
          nombre: 'El Placer Motel',
          email: 'elplacer@correo.com',
          iglesiaActual: 'Parroquia Nuestra Señora del Amparo',
          iglesiaId: 42,
          membershipStatus: 'none', // Backend aún no actualizó o está en revisión
          fechaRegistro: '2026-10-25',
          avatarIniciales: 'EP',
          esMiembroVerificado: false,
          role: UserRole.user,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<IglesiaProvider>.value(value: iglesiaProvider),
            ChangeNotifierProvider<AjustesProvider>.value(value: ajustesProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ],
          child: MaterialApp(
            navigatorKey: MyApp.navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            routes: {
              EsperandoAprobacionScreen.routeName: (_) =>
                  const Scaffold(body: Text('Esperando Aprobacion Mock')),
            },
            home: const Scaffold(
              body: PerfilScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Debe reconocer que el usuario SÍ tiene iglesia seleccionada en estado 'pendiente de aprobación'
      // El badge superior NUNCA debe decir 'Sin congregación'
      expect(find.text('Pendiente de aprobación'), findsOneWidget);
      expect(find.text('Sin congregación'), findsNothing);

      // 2. La tarjeta de estado debe mostrar el nombre exacto de la iglesia
      expect(find.text('Parroquia Nuestra Señora del Amparo'), findsWidgets);
      expect(find.text('En revisión'), findsOneWidget);
      expect(find.text('Sin vincular'), findsNothing);

      // 3. El texto informativo debe ser empático y exacto
      expect(
        find.textContaining('Perteneces a la Parroquia Nuestra Señora del Amparo, pero tu aprobación se encuentra actualmente pendiente por parte de la administración.'),
        findsOneWidget,
      );

      // 4. Queda PROHIBIDO sugerir buscar y unirse a otra iglesia
      expect(find.text('Buscar y unirse a una iglesia'), findsNothing);
      expect(find.text('Ver estado de solicitud'), findsOneWidget);

      // 5. Al pulsar en 'Mis solicitudes', el Bottom Sheet también debe ser empático
      await tester.ensureVisible(find.text('Mis solicitudes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mis solicitudes'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Perteneces a la Parroquia Nuestra Señora del Amparo, pero tu aprobación se encuentra actualmente pendiente por parte de la administración.'),
        findsWidgets,
      );
      expect(find.text('Ver estado de solicitud'), findsWidgets);
    });
  });
}
