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
import 'package:atrio/screens/nueva_solicitud_screen.dart';
import 'package:atrio/screens/perfil_screen.dart';
import 'package:atrio/screens/seguimiento_solicitud_screen.dart';
import 'package:atrio/screens/tipos_solicitud_screen.dart';
import 'package:atrio/servicios/token_storage_service.dart';
import 'package:atrio/widgets/change_pending_banner.dart';
import 'package:atrio/widgets/modal_restriccion_solicitud.dart';

class MockTokenStorageService extends TokenStorageService {
  String? _fakeToken = 'fake_valid_token';

  @override
  Future<String?> getAccessToken() async => _fakeToken;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<DateTime?> getTokenExpiry() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    _fakeToken = accessToken;
  }

  @override
  Future<void> saveAccessToken(String accessToken, {DateTime? expiresAt}) async {
    _fakeToken = accessToken;
  }

  @override
  Future<void> clearTokens() async {
    _fakeToken = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Separación de Estados: Miembro Activo vs Solicitud de Cambio de Iglesia', () {
    test('Miembro activo con solicitud de cambio en curso mantiene su iglesia activa y acceso pleno', () {
      final user = UserModel(
        id: 42,
        nombre: 'El Placer Motel',
        email: 'elplacer@correo.com',
        iglesiaActual: 'Parroquia Nuestra Señora del Amparo',
        iglesiaId: 10,
        membershipStatus: 'change_pending',
        requestedChurchId: 25,
        requestedChurchData: {
          'id': 25,
          'name': 'Parroquia Nuestra Señora del Perpetuo Socorro',
        },
        fechaRegistro: '2026-01-01',
        avatarIniciales: 'EP',
        esMiembroVerificado: true,
        role: UserRole.member,
      );

      // Verificación de propiedades del modelo
      expect(user.iglesiaActual, equals('Parroquia Nuestra Señora del Amparo'));
      expect(user.iglesiaId, equals(10));
      expect(user.requestedChurchId, equals(25));
      expect(user.hasChurchAssigned, isTrue);
      expect(user.isMember, isTrue);
      expect(user.isChangePending, isTrue);
      expect(user.isMembershipPending, isFalse);
      expect(user.isChurchApproved, isTrue);
    });

    test('resolveStage devuelve AppStage.memberHome cuando status es change_pending', () {
      final payload = {
        'role': 'member',
        'membership_status': 'change_pending',
        'church': {
          'id': 10,
          'name': 'Parroquia Nuestra Señora del Amparo',
          'has_active_subscription': true,
        },
        'requested_church_id': 25,
        'requested_church': {
          'id': 25,
          'name': 'Parroquia Nuestra Señora del Perpetuo Socorro',
        },
      };

      final stage = resolveStage(payload);
      expect(stage, equals(AppStage.memberHome));
    });

    test('UserProvider.solicitarMembresia preserva la iglesia activa cuando el usuario ya es miembro', () async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'valid_bearer_token',
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);

      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 42,
          nombre: 'El Placer Motel',
          email: 'elplacer@correo.com',
          iglesiaActual: 'Parroquia Nuestra Señora del Amparo',
          iglesiaId: 10,
          membershipStatus: 'approved',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'EP',
          esMiembroVerificado: true,
          role: UserRole.member,
        ),
      );

      expect(userProvider.isChurchApproved, isTrue);
      expect(userProvider.canSubmitSolicitud, isTrue);
      expect(userProvider.currentUser?.iglesiaActual, equals('Parroquia Nuestra Señora del Amparo'));

      // El usuario solicita cambio a una nueva iglesia
      await userProvider.solicitarMembresia(
        churchId: 25,
        churchName: 'Parroquia Nuestra Señora del Perpetuo Socorro',
      );

      // La iglesia activa NO se debe sobrescribir
      expect(userProvider.currentUser?.iglesiaActual, equals('Parroquia Nuestra Señora del Amparo'));
      expect(userProvider.currentUser?.iglesiaId, equals(10));
      expect(userProvider.currentUser?.membershipStatus, equals('change_pending'));
      expect(userProvider.currentUser?.requestedChurchId, equals(25));
      expect(
        userProvider.currentUser?.requestedChurchData?['name'],
        equals('Parroquia Nuestra Señora del Perpetuo Socorro'),
      );
      expect(userProvider.isChangePending, isTrue);
      expect(userProvider.isMembershipPending, isFalse);
      expect(userProvider.isChurchApproved, isTrue);
      expect(userProvider.canSubmitSolicitud, isTrue);
    });

    testWidgets(
        'ModalRestriccionSolicitud.verificarAcceso autoriza a miembros con cambio de iglesia en curso sin mostrar diálogo restrictivo',
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
          id: 42,
          nombre: 'El Placer Motel',
          email: 'elplacer@correo.com',
          iglesiaActual: 'Parroquia Nuestra Señora del Amparo',
          iglesiaId: 10,
          membershipStatus: 'change_pending',
          requestedChurchId: 25,
          requestedChurchData: {
            'id': 25,
            'name': 'Parroquia Nuestra Señora del Perpetuo Socorro',
          },
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'EP',
          esMiembroVerificado: true,
          role: UserRole.member,
        ),
      );

      bool accesoConcedido = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: userProvider,
          child: MaterialApp(
            navigatorKey: MyApp.navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    accesoConcedido = ModalRestriccionSolicitud.verificarAcceso(
                      context: ctx,
                    );
                  },
                  child: const Text('PROBAR_ACCESO'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('PROBAR_ACCESO'));
      await tester.pumpAndSettle();

      // Debe conceder acceso pleno
      expect(accesoConcedido, isTrue);

      // NO debe mostrar el diálogo restrictivo de membresía pendiente
      expect(find.text('Membresía pendiente de aprobación'), findsNothing);
      expect(find.textContaining('Perpetuo Socorro'), findsNothing);
    });

    testWidgets(
        'PerfilScreen y SeguimientoSolicitudScreen muestran contexto correcto para miembro con cambio pendiente',
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

      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 42,
          nombre: 'El Placer Motel',
          email: 'elplacer@correo.com',
          iglesiaActual: 'Parroquia Nuestra Señora del Amparo',
          iglesiaId: 10,
          membershipStatus: 'change_pending',
          requestedChurchId: 25,
          requestedChurchData: {
            'id': 25,
            'name': 'Parroquia Nuestra Señora del Perpetuo Socorro',
          },
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'EP',
          esMiembroVerificado: true,
          role: UserRole.member,
        ),
        rawMeData: {
          'role': 'member',
          'membership_status': 'change_pending',
          'church': {
            'id': 10,
            'name': 'Parroquia Nuestra Señora del Amparo',
            'has_active_subscription': true,
          },
          'requested_church_id': 25,
          'requested_church': {
            'id': 25,
            'name': 'Parroquia Nuestra Señora del Perpetuo Socorro',
          },
        },
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
              SeguimientoSolicitudScreen.routeName: (_) =>
                  const SeguimientoSolicitudScreen(),
              TiposSolicitudScreen.routeName: (_) => const TiposSolicitudScreen(),
              NuevaSolicitudScreen.routeName: (_) => const NuevaSolicitudScreen(),
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

      // 1. PerfilScreen debe mostrar su congregación activa: Parroquia Nuestra Señora del Amparo
      expect(find.text('Parroquia Nuestra Señora del Amparo'), findsWidgets);
      expect(find.text('Iglesia aprobada'), findsOneWidget);
      expect(find.text('Congregación activa'), findsOneWidget);
      expect(find.text('Aprobada'), findsOneWidget);

      // 2. Debe mostrar el banner de cambio de congregación pendiente
      expect(find.byType(ChangePendingBanner), findsWidgets);
      expect(
        find.textContaining('Has solicitado cambio de iglesia'),
        findsOneWidget,
      );

      // 3. Al pulsar 'Mis solicitudes', debe navegar sin mostrar error de membresía pendiente
      await tester.ensureVisible(find.text('Mis solicitudes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mis solicitudes'));
      await tester.pumpAndSettle();

      // Estamos en SeguimientoSolicitudScreen
      expect(find.text('Mis solicitudes'), findsOneWidget);
      expect(find.text('Membresía pendiente de aprobación'), findsNothing);

      // 4. Al pulsar el botón de crear solicitud, NO debe bloquearse
      final botonNueva = find.text('Nueva solicitud');
      if (botonNueva.evaluate().isNotEmpty) {
        await tester.tap(botonNueva);
        await tester.pumpAndSettle();
        expect(find.text('Membresía pendiente de aprobación'), findsNothing);
      }
    });
  });
}
