import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/main.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/admin_provider.dart';
import 'package:atrio/providers/ajustes_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/perfil_screen.dart';
import 'package:atrio/servicios/token_storage_service.dart';

class _MockTokenStorage extends Fake implements TokenStorageService {
  @override
  Future<String?> getAccessToken() async => 'test_token';
  @override
  Future<String?> getRefreshToken() async => 'test_refresh';
  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {}
  @override
  Future<void> clearTokens() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AtrioApi api;
  late UserProvider userProvider;
  late IglesiaProvider iglesiaProvider;
  late AjustesProvider ajustesProvider;
  late AdminProvider adminProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final storage = _MockTokenStorage();
    api = AtrioApi(
      baseUrl: 'https://test.atrioapp.org',
      token: 'test_token',
      storageService: storage,
    );
    userProvider = UserProvider(api: api, storageService: storage);
    iglesiaProvider = IglesiaProvider();
    ajustesProvider = AjustesProvider();
    adminProvider = AdminProvider(api: api);
  });

  Widget buildTestPerfilWidget() {
    return MultiProvider(
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
        home: const Scaffold(
          body: PerfilScreen(),
        ),
      ),
    );
  }

  group('PerfilScreen - Soporte Offline y Modo Avión para Miembros Registrados', () {
    testWidgets(
      'Usuario miembro registrado mantiene estado "Iglesia aprobada" y "Congregación activa" sin cambiar a pendiente de aprobación offline',
      (WidgetTester tester) async {
        // Simular usuario miembro activo debidamente registrado
        final approvedUser = UserModel(
          id: 101,
          nombre: 'David Livingstone',
          email: 'david@atrioapp.org',
          iglesiaActual: 'Primera Iglesia Bautista de Santo Domingo',
          iglesiaId: 12,
          membershipStatus: 'approved',
          fechaRegistro: '2026-01-15',
          avatarIniciales: 'DL',
          esMiembroVerificado: true,
          role: UserRole.member,
        );

        userProvider.setCurrentUserForTesting(approvedUser);

        await tester.pumpWidget(buildTestPerfilWidget());
        await tester.pumpAndSettle();

        // 1. Debe mostrar que la iglesia está aprobada y activa
        expect(find.text('Iglesia aprobada'), findsOneWidget);
        expect(find.text('Congregación activa'), findsOneWidget);
        expect(find.text('Primera Iglesia Bautista de Santo Domingo'), findsWidgets);

        // 2. NUNCA debe mostrar 'Pendiente de aprobación' ni 'Solicitud de membresía'
        expect(find.text('Pendiente de aprobación'), findsNothing);
        expect(find.text('Solicitud de membresía'), findsNothing);
        expect(find.text('En revisión'), findsNothing);
        expect(find.text('Sin congregación'), findsNothing);
      },
    );

    testWidgets(
      'Usuario con membresía realmente pendiente muestra correctamente "Pendiente de aprobación" y "En revisión"',
      (WidgetTester tester) async {
        // Simular usuario aspirante con solicitud en curso
        final pendingUser = UserModel(
          id: 202,
          nombre: 'Nuevo Aspirante',
          email: 'aspirante@atrioapp.org',
          iglesiaActual: 'Iglesia Evangélica Central',
          iglesiaId: 5,
          membershipStatus: 'membership_pending',
          fechaRegistro: '2026-11-01',
          avatarIniciales: 'NA',
          esMiembroVerificado: false,
          role: UserRole.user,
        );

        userProvider.setCurrentUserForTesting(pendingUser);

        await tester.pumpWidget(buildTestPerfilWidget());
        await tester.pumpAndSettle();

        // 1. Debe mostrar el badge y tarjeta de solicitud pendiente
        expect(find.text('Pendiente de aprobación'), findsOneWidget);
        expect(find.text('En revisión'), findsOneWidget);
        expect(find.text('Solicitud de membresía'), findsOneWidget);
        expect(find.text('Iglesia aprobada'), findsNothing);
        expect(find.text('Congregación activa'), findsNothing);
      },
    );

    test(
      'Persistencia y Restauración offline de UserModel mediante SharedPreferences',
      () async {
        final sampleUser = UserModel(
          id: 303,
          nombre: 'María Gómez',
          email: 'maria@atrioapp.org',
          iglesiaActual: 'Catedral de la Fe',
          iglesiaId: 20,
          membershipStatus: 'approved',
          fechaRegistro: '2026-05-10',
          avatarIniciales: 'MG',
          esMiembroVerificado: true,
          role: UserRole.member,
        );

        // Guardar JSON serializado en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'cached_user_profile',
          jsonEncode(sampleUser.toJson()),
        );

        // Restaurar a través de fromJson
        final restoredJson = jsonDecode(prefs.getString('cached_user_profile')!)
            as Map<String, dynamic>;
        final restoredUser = UserModel.fromJson(restoredJson);

        expect(restoredUser.nombre, 'María Gómez');
        expect(restoredUser.iglesiaActual, 'Catedral de la Fe');
        expect(restoredUser.iglesiaId, 20);
        expect(restoredUser.membershipStatus, 'approved');
        expect(restoredUser.esMiembroVerificado, isTrue);
        expect(restoredUser.role, UserRole.member);
        expect(restoredUser.isChurchApproved, isTrue);
      },
    );
  });
}
