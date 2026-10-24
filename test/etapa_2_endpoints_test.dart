import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';

class MockErrorApi extends AtrioApi {
  final AtrioApiException exceptionToThrow;
  MockErrorApi(this.exceptionToThrow) : super(baseUrl: 'https://test.atrioapp.org');

  @override
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String deviceName = 'Flutter App',
  }) async {
    throw exceptionToThrow;
  }

  @override
  Future<Map<String, dynamic>> createMyChurch(Map<String, dynamic> churchData) async {
    throw exceptionToThrow;
  }
}

class MockSuccessApi extends AtrioApi {
  MockSuccessApi() : super(baseUrl: 'https://test.atrioapp.org');

  @override
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String deviceName = 'Flutter App',
  }) async {
    return {
      'token': 'google_jwt_token',
      'refresh_token': 'google_refresh_token',
      'created': true,
      'role': 'user',
      'membership_status': 'none',
      'user': {
        'id': 100,
        'name': 'Google User',
        'email': 'user@gmail.com',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> createMyChurch(Map<String, dynamic> churchData) async {
    return {
      'role': 'church_admin',
      'membership_status': 'approved',
      'church': {
        'id': 88,
        'name': churchData['name'] ?? 'Nueva Iglesia',
        'has_active_subscription': false,
      },
      'user': {
        'id': 100,
        'name': 'Pastor Admin',
        'email': 'pastor@nuevaiglesia.org',
      },
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Etapa 2 - Cabeceras de Autenticación y Endpoints Odoo 19', () {
    test('/auth/google es endpoint público y omite cabecera Authorization', () {
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'token_viejo_o_expirado',
      );

      final headers = api.buildHeadersForTesting('/auth/google');
      expect(headers.containsKey('Authorization'), isFalse);
      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['Accept'], equals('application/json'));
    });

    test('/me/church es endpoint privado y exige cabecera Bearer Token', () {
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'jwt_activo_usuario',
      );

      final headers = api.buildHeadersForTesting('/me/church');
      expect(headers['Authorization'], equals('Bearer jwt_activo_usuario'));
    });

    test('/membership/request exige cabecera Bearer Token', () {
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'jwt_activo_usuario',
      );

      final headers = api.buildHeadersForTesting('/membership/request');
      expect(headers['Authorization'], equals('Bearer jwt_activo_usuario'));
    });
  });

  group('Etapa 2 - UserProvider: loginWithGoogle y createMyChurch', () {
    test('loginWithGoogle exitoso actualiza estado, stage y devuelve payload con created: true', () async {
      final provider = UserProvider(api: MockSuccessApi());

      final res = await provider.loginWithGoogle(idToken: 'fake_valid_google_id_token');
      expect(res, isNotNull);
      expect(res!['created'], isTrue);
      expect(provider.currentUser?.nombre, equals('Google User'));
      expect(provider.currentStage, equals(AppStage.chooseChurch));
      expect(provider.isChooseChurch, isTrue);
    });

    test('createMyChurch transiciona al usuario a church_admin con churchPendingActivation', () async {
      final provider = UserProvider(api: MockSuccessApi());

      final res = await provider.createMyChurch({'name': 'Iglesia Monte Sion'});
      expect(res, isNotNull);
      expect(provider.currentUser?.isChurchAdmin, isTrue);
      expect(provider.currentUser?.hasActiveSubscription, isFalse);
      expect(provider.currentStage, equals(AppStage.churchPendingActivation));
      expect(provider.isChurchPendingActivation, isTrue);
    });

    test('Traduce account_exists de Google a mensaje amigable', () async {
      final mockApi = MockErrorApi(AtrioApiException(409, 'account_exists', 'Conflict'));
      final provider = UserProvider(api: mockApi);

      final res = await provider.loginWithGoogle(idToken: 'fake_token');
      expect(res, isNull);
      expect(provider.errorMessage, contains('Ya tienes una cuenta registrada con este correo'));
    });

    test('Traduce email_not_verified de Google a mensaje amigable', () async {
      final mockApi = MockErrorApi(AtrioApiException(400, 'email_not_verified', 'Unverified'));
      final provider = UserProvider(api: mockApi);

      final res = await provider.loginWithGoogle(idToken: 'fake_token');
      expect(res, isNull);
      expect(provider.errorMessage, contains('Tu cuenta de Google no tiene el correo electrónico verificado'));
    });

    test('Traduce weak_password y email_taken de registro', () async {
      final mockApi = MockErrorApi(AtrioApiException(400, 'weak_password', 'Password too short'));
      final provider = UserProvider(api: mockApi);

      try {
        await provider.createMyChurch({'name': 'Test'});
        fail('Debería haber lanzado AtrioApiException');
      } catch (e) {
        expect(e, isA<AtrioApiException>());
      }
      expect(provider.errorMessage, contains('mínimo de 8 caracteres'));
    });
  });
}
