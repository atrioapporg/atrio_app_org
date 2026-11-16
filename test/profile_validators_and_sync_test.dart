import 'dart:convert';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/servicios/token_storage_service.dart';
import 'package:atrio/utils/profile_validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryTokenStorage extends TokenStorageService {
  String? _access = 'token_123';
  String? _refresh = 'refresh_123';

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _access;

  @override
  Future<String?> getRefreshToken() async => _refresh;

  @override
  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
  }

  @override
  Future<void> clearAll() async {
    _access = null;
    _refresh = null;
  }

  @override
  Future<bool> hasToken() async => _access != null && _access!.isNotEmpty;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProfileValidators', () {
    test('valida correos electrónicos estrictamente', () {
      expect(ProfileValidators.isValidEmail('lenin-linares@hotmail.com'), isTrue);
      expect(ProfileValidators.isValidEmail('usuario.test+1@icloud.com'), isTrue);
      expect(ProfileValidators.isValidEmail('nombre@yahoo.com'), isTrue);

      expect(ProfileValidators.isValidEmail(''), isFalse);
      expect(ProfileValidators.isValidEmail('sin_arroba.com'), isFalse);
      expect(ProfileValidators.isValidEmail('usuario@dominio'), isFalse);
      expect(ProfileValidators.isValidEmail('usuario@dom..com'), isFalse);
      expect(ProfileValidators.isValidEmail('usuario@dom.c'), isFalse);
      expect(ProfileValidators.isValidEmail('usuario con@espacio.com'), isFalse);
    });

    test('valida teléfonos celulares de República Dominicana (809, 829, 849)', () {
      expect(ProfileValidators.isValidDominicanPhone('8095551234'), isTrue);
      expect(ProfileValidators.isValidDominicanPhone('829-555-1234'), isTrue);
      expect(ProfileValidators.isValidDominicanPhone('(849) 555-1234'), isTrue);
      expect(ProfileValidators.isValidDominicanPhone('+1 809 555 1234'), isTrue);

      // Prefijos no permitidos o longitud incorrecta
      expect(ProfileValidators.isValidDominicanPhone('8005551234'), isFalse);
      expect(ProfileValidators.isValidDominicanPhone('3055551234'), isFalse);
      expect(ProfileValidators.isValidDominicanPhone('809555123'), isFalse);
      expect(ProfileValidators.isValidDominicanPhone('80955512345'), isFalse);
      expect(ProfileValidators.isValidDominicanPhone(''), isFalse);
    });

    test('formatea teléfonos RD a 809-555-1234', () {
      expect(
        ProfileValidators.formatDominicanPhone('+1 (829) 444 9876'),
        equals('829-444-9876'),
      );
    });

    test('applyEmailDomain completa o reemplaza el dominio correctamente', () {
      expect(
        ProfileValidators.applyEmailDomain('lenin.linares', '@icloud.com'),
        equals('lenin.linares@icloud.com'),
      );
      expect(
        ProfileValidators.applyEmailDomain('lenin.linares@', '@yahoo.com'),
        equals('lenin.linares@yahoo.com'),
      );
      expect(
        ProfileValidators.applyEmailDomain('lenin.linares@gm', '@gmail.com'),
        equals('lenin.linares@gmail.com'),
      );
    });
  });

  group('UserProvider.actualizarPerfilUsuario', () {
    test('envía PUT /me a Odoo y actualiza usuario y SharedPreferences', () async {
      Map<String, dynamic>? sentBody;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/me') && request.method == 'PUT') {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'success': true}), 200);
        }
        if (request.url.path.endsWith('/me') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'user': {
                'id': 7,
                'name': 'Lenin Linares',
                'email': 'lenin@icloud.com',
                'phone': '809-555-1234',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final storage = _InMemoryTokenStorage();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'token_123',
        refreshToken: 'refresh_123',
        storageService: storage,
        client: mockClient,
      );
      final userProvider = UserProvider(api: api, storageService: storage);
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 7,
          nombre: 'Lenin',
          email: 'lenin@hotmail.com',
          iglesiaActual: 'Iglesia Central',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'L',
          esMiembroVerificado: true,
        ),
      );

      final ok = await userProvider.actualizarPerfilUsuario(
        nombre: 'Lenin Linares',
        email: 'lenin@icloud.com',
        telefono: '809-555-1234',
      );

      expect(ok, isTrue);
      expect(sentBody, isNotNull);
      expect(sentBody!['name'], equals('Lenin Linares'));
      expect(sentBody!['email'], equals('lenin@icloud.com'));
      expect(sentBody!['phone'], equals('809-555-1234'));
      expect(userProvider.currentUser?.nombre, equals('Lenin Linares'));
      expect(userProvider.currentUser?.email, equals('lenin@icloud.com'));
      expect(userProvider.currentUser?.telefono, equals('809-555-1234'));
    });

    test('retorna false y expone error si Odoo rechaza la actualización', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/me') && request.method == 'PUT') {
          return http.Response(
            jsonEncode({'error': 'El correo ya está en uso', 'code': 'email_taken'}),
            409,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 200);
      });

      final storage = _InMemoryTokenStorage();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'token_123',
        refreshToken: 'refresh_123',
        storageService: storage,
        client: mockClient,
      );
      final userProvider = UserProvider(api: api, storageService: storage);
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 7,
          nombre: 'Lenin',
          email: 'lenin@hotmail.com',
          iglesiaActual: 'Iglesia Central',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'L',
          esMiembroVerificado: true,
        ),
      );

      final ok = await userProvider.actualizarPerfilUsuario(
        nombre: 'Lenin',
        email: 'otro@gmail.com',
        telefono: '829-555-0000',
      );

      expect(ok, isFalse);
      expect(userProvider.errorMessage, contains('correo ya está en uso'));
      expect(userProvider.currentUser?.email, equals('lenin@hotmail.com'));
    });
  });
}
