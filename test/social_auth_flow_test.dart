import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/ajustes_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/perfil_screen.dart';
import 'package:atrio/servicios/token_storage_service.dart';

/// Implementación en memoria de TokenStorageService para pruebas herméticas
class MockTokenStorageService extends TokenStorageService {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> saveAccessToken(String accessToken) async {
    _accessToken = accessToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<bool> hasToken() async => _accessToken != null && _accessToken!.isNotEmpty;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Flujo OAuth & Social Login (Google Sign-In) y Persistencia', () {
    test('AtrioApi.loginWithSocial persiste tokens en TokenStorageService', () async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        storageService: mockStorage,
      );

      expect(api.isAuthenticated, isFalse);

      final result = await api.loginWithSocial(
        provider: 'google',
        email: 'leningrado.google@gmail.com',
        name: 'Lenin Google Test',
        idToken: 'mock_google_id_token_12345',
        accessToken: 'mock_google_access_token_abcde',
      );

      // Verificamos que los tokens se hayan guardado en memoria y en el almacenamiento seguro
      expect(api.isAuthenticated, isTrue);
      expect(api.token, isNotNull);
      expect(await mockStorage.getAccessToken(), isNotNull);
      expect(await mockStorage.getRefreshToken(), isNotNull);
      expect(result['user'], isNotNull);
      expect(result['user']['email'], 'leningrado.google@gmail.com');
    });

    test('UserProvider.loginWithSocial actualiza el estado global reactivo', () async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);

      expect(userProvider.isAuthenticated, isFalse);
      expect(userProvider.currentUser, isNull);

      final ok = await userProvider.loginWithSocial(
        provider: 'google',
        email: 'juan.social@gmail.com',
        nombre: 'Juan Social Google',
        idToken: 'token_google_999',
        iglesiaActual: 'Comunidad de Gracia',
      );

      expect(ok, isTrue);
      expect(userProvider.isAuthenticated, isTrue);
      expect(userProvider.currentUser, isNotNull);
      expect(userProvider.currentUser!.nombre, 'Juan Social Google');
      expect(userProvider.currentUser!.email, 'juan.social@gmail.com');
      expect(userProvider.currentUser!.iglesiaActual, 'Comunidad de Gracia');
      expect(userProvider.role, UserRole.user);

      // Verificar que SharedPreferences guardó la sesión
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isLoggedIn'), isTrue);
      expect(prefs.getString('userEmail'), 'juan.social@gmail.com');
    });

    test('UserProvider.updateUserProfile inicializa UserModel si era null (resiliencia)', () {
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(null);
      expect(userProvider.currentUser, isNull);

      userProvider.updateUserProfile(
        nombre: 'Carlos Resiliente',
        email: 'carlos@demo.com',
        telefono: '8095551234',
        iglesiaActual: 'Iglesia Central',
      );

      expect(userProvider.currentUser, isNotNull);
      expect(userProvider.currentUser!.nombre, 'Carlos Resiliente');
      expect(userProvider.currentUser!.email, 'carlos@demo.com');
      expect(userProvider.currentUser!.avatarIniciales, 'C');
    });

    testWidgets('PerfilScreen refleja la sesión activa de Google y no cae en modo invitado',
        (tester) async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'valid_bearer_token',
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);

      // Simulamos el usuario autenticado vía Google
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 55,
          nombre: 'Lenin Google',
          email: 'leningrado.google@gmail.com',
          iglesiaActual: 'Iglesia Atrio Central',
          iglesiaId: 1,
          fechaRegistro: '2026-10-23',
          avatarIniciales: 'LG',
          esMiembroVerificado: true,
          role: UserRole.user,
          permissions: const {'view_content', 'manage_profile'},
          isReadOnly: false,
        ),
      );

      expect(userProvider.isAuthenticated, isTrue);

      final iglesiaProvider = IglesiaProvider();
      final ajustesProvider = AjustesProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<IglesiaProvider>.value(value: iglesiaProvider),
            ChangeNotifierProvider<AjustesProvider>.value(value: ajustesProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('es'),
            home: Scaffold(
              body: PerfilScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Debe mostrar el nombre del usuario autenticado por Google
      expect(find.text('Lenin Google'), findsOneWidget);

      // 2. NO debe mostrar "Usuario invitado"
      expect(find.text('Usuario invitado'), findsNothing);

      // 3. NO debe mostrar el banner amarillo de advertencia de modo invitado
      expect(
        find.textContaining('Estás navegando en modo invitado'),
        findsNothing,
      );

      // 4. Debe mostrar el botón de Cerrar sesión (no el de Iniciar sesión)
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('PerfilScreen muestra modo invitado cuando no hay sesión activa',
        (tester) async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: null, // Sin token
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);
      userProvider.setCurrentUserForTesting(null); // Sin usuario

      expect(userProvider.isAuthenticated, isFalse);

      final iglesiaProvider = IglesiaProvider();
      final ajustesProvider = AjustesProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<IglesiaProvider>.value(value: iglesiaProvider),
            ChangeNotifierProvider<AjustesProvider>.value(value: ajustesProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('es'),
            home: Scaffold(
              body: PerfilScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Debe mostrar "Usuario invitado" y el banner de modo invitado
      expect(find.text('Usuario invitado'), findsOneWidget);
      expect(
        find.textContaining('Estás navegando en modo invitado'),
        findsOneWidget,
      );
      expect(find.text('Iniciar sesión'), findsWidgets);
    });
  });
}
