import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/admin_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/servicios/auth_service.dart';
import 'package:atrio/servicios/token_storage_service.dart';

class MockTokenStorageService extends TokenStorageService {
  String? _accessToken = 'test_access_token_123';
  String? _refreshToken = 'test_refresh_token_456';

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
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
  Future<void> clearAll() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<bool> hasToken() async => _accessToken != null && _accessToken!.isNotEmpty;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
      'user_email': 'usuario.prueba@atrioapp.org',
      'user_name': 'Usuario Test',
      'iglesia_guardada': '{"nombre":"Iglesia Central","direccion":"Calle 1"}',
      'intro_vista': true,
    });
  });

  group('Flujo de Eliminación de Cuenta y Datos Personales (Clean Architecture)', () {
    test('TokenStorageService.clearAll limpia todos los tokens cifrados', () async {
      final mockStorage = MockTokenStorageService();
      expect(await mockStorage.hasToken(), isTrue);

      await mockStorage.clearAll();
      expect(await mockStorage.hasToken(), isFalse);
      expect(await mockStorage.getAccessToken(), isNull);
      expect(await mockStorage.getRefreshToken(), isNull);
    });

    test('IglesiaProvider.limpiarIglesia restablece el estado virgen en memoria', () {
      final provider = IglesiaProvider();
      provider.limpiarIglesia();

      expect(provider.tieneIglesiaGuardada, isFalse);
      expect(provider.tieneIglesiaAsignada, isFalse);
      expect(provider.iglesiaActual, isNull);
      expect(provider.errorMessage, isNull);
    });

    test('AdminProvider.reset purga todos los modelos de administración en memoria', () {
      final api = AtrioApi(baseUrl: 'https://test.atrioapp.org');
      final adminProvider = AdminProvider(api: api);
      adminProvider.reset();

      expect(adminProvider.announcements, isEmpty);
      expect(adminProvider.groups, isEmpty);
      expect(adminProvider.prayerRequests, isEmpty);
      expect(adminProvider.adminEvents, isEmpty);
      expect(adminProvider.analytics, isNull);
      expect(adminProvider.errorMessage, isNull);
    });

    test('AuthService.revokeGoogleSession se ejecuta de forma segura sin excepciones', () async {
      // Verifica que aún si no hay sesión previa activa de Google, no lance excepciones no controladas
      expect(() async => await AuthService.revokeGoogleSession(), returnsNormally);
    });

    test('UserProvider.eliminarCuentaDefinitiva ejecuta purga de almacenamiento local, tokens y estado', () async {
      final mockStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'active_token',
        refreshToken: 'active_refresh',
        storageService: mockStorage,
      );
      final userProvider = UserProvider(api: api, storageService: mockStorage);

      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 42,
          nombre: 'Usuario Prueba Borrado',
          email: 'usuario.prueba@atrioapp.org',
          iglesiaActual: 'Comunidad de Gracia',
          fechaRegistro: '2026-10-28',
          avatarIniciales: 'UP',
          esMiembroVerificado: true,
        ),
      );

      expect(userProvider.isAuthenticated, isTrue);
      expect(userProvider.currentUser, isNotNull);

      // Ejecutar la eliminación definitiva
      final resultado = await userProvider.eliminarCuentaDefinitiva(razon: 'Solicitud del usuario');

      expect(resultado, isTrue);
      expect(userProvider.currentUser, isNull);
      expect(userProvider.isAuthenticated, isFalse);
      expect(api.token, isNull);
      expect(api.refreshToken, isNull);

      // Verificar que SharedPreferences haya sido completamente limpiado
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isLoggedIn'), isNull);
      expect(prefs.getString('user_email'), isNull);
      expect(prefs.getString('iglesia_guardada'), isNull);
      expect(prefs.getBool('intro_vista'), isNull);
    });
  });
}
