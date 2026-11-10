import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/servicios/token_storage_service.dart';
import 'package:atrio/widgets/change_pending_banner.dart';

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

  group('Cancelación de Solicitudes y Peticiones (UserProvider y UI)', () {
    late UserProvider userProvider;
    late MockTokenStorageService mockTokenStorage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockTokenStorage = MockTokenStorageService();
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'valid_bearer_token',
        storageService: mockTokenStorage,
      );
      userProvider = UserProvider(api: api, storageService: mockTokenStorage);
    });

    test('cancelarSolicitudCambioIglesia restaura estado a approved y preserva iglesia actual', () async {
      // 1. Simular usuario con cambio de iglesia en curso
      final user = UserModel(
        id: 77,
        nombre: 'Creyente Test',
        email: 'creyente@test.com',
        iglesiaActual: 'Parroquia San Lucas',
        iglesiaId: 10,
        membershipStatus: 'change_pending',
        requestedChurchId: 20,
        requestedChurchData: {
          'id': 20,
          'name': 'Catedral Santa María',
        },
        fechaRegistro: '2026-01-01',
        avatarIniciales: 'CT',
        esMiembroVerificado: true,
        role: UserRole.member,
      );

      userProvider.setCurrentUserForTesting(
        user,
        rawMeData: {
          'role': 'member',
          'membership_status': 'change_pending',
          'church': {'id': 10, 'name': 'Parroquia San Lucas'},
          'requested_church_id': 20,
          'requested_church': {'id': 20, 'name': 'Catedral Santa María'},
        },
      );

      expect(userProvider.isChangePending, isTrue);
      expect(userProvider.membershipStatus, equals('change_pending'));
      expect(userProvider.requestedChurchId, equals(20));
      expect(userProvider.currentUser?.iglesiaActual, equals('Parroquia San Lucas'));

      // 2. Ejecutar cancelación de cambio
      final resultado = await userProvider.cancelarSolicitudCambioIglesia();
      expect(resultado, isTrue);

      // 3. Verificar estado restaurado: sigue siendo miembro aprobado de su iglesia original
      expect(userProvider.isChangePending, isFalse);
      expect(userProvider.membershipStatus, equals('approved'));
      expect(userProvider.requestedChurchId == null || userProvider.requestedChurchId == 0, isTrue);
      expect(userProvider.requestedChurchData, isNull);
      expect(userProvider.currentUser?.iglesiaActual, equals('Parroquia San Lucas'));
      expect(userProvider.currentUser?.iglesiaId, equals(10));
    });

    test('cancelarSolicitudMembresia restablece estado a none para usuario sin iglesia previa', () async {
      final user = UserModel(
        id: 88,
        nombre: 'Nuevo Creyente',
        email: 'nuevo@test.com',
        iglesiaActual: 'Sin congregación asignada',
        iglesiaId: null,
        membershipStatus: 'pending',
        requestedChurchId: 30,
        requestedChurchData: {
          'id': 30,
          'name': 'Iglesia Central',
        },
        fechaRegistro: '2026-01-01',
        avatarIniciales: 'NC',
        esMiembroVerificado: false,
        role: UserRole.member,
      );

      userProvider.setCurrentUserForTesting(
        user,
        rawMeData: {
          'role': 'member',
          'membership_status': 'pending',
          'requested_church_id': 30,
        },
      );

      expect(userProvider.isMembershipPending, isTrue);

      final resultado = await userProvider.cancelarSolicitudMembresia();
      expect(resultado, isTrue);

      expect(userProvider.isMembershipPending, isFalse);
      expect(userProvider.membershipStatus, equals('none'));
      expect(userProvider.requestedChurchId == null || userProvider.requestedChurchId == 0, isTrue);
    });

    testWidgets('ChangePendingBanner muestra botón de cancelar y diálogo de confirmación', (tester) async {
      final user = UserModel(
        id: 99,
        nombre: 'Hermano Pedro',
        email: 'pedro@test.com',
        iglesiaActual: 'Iglesia Central',
        iglesiaId: 5,
        membershipStatus: 'change_pending',
        requestedChurchId: 15,
        requestedChurchData: {
          'id': 15,
          'name': 'Nueva Esperanza',
        },
        fechaRegistro: '2026-01-01',
        avatarIniciales: 'HP',
        esMiembroVerificado: true,
        role: UserRole.member,
      );

      userProvider.setCurrentUserForTesting(
        user,
        rawMeData: {
          'role': 'member',
          'membership_status': 'change_pending',
          'church': {'id': 5, 'name': 'Iglesia Central'},
          'requested_church_id': 15,
        },
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<IglesiaProvider>.value(
              value: IglesiaProvider(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('es'),
            home: Scaffold(
              body: ChangePendingBanner(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe visualizar el banner y el botón de cancelar
      expect(find.textContaining('Tu solicitud para trasladarte'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      // Al pulsar 'Cancelar', debe abrir el diálogo modal de confirmación
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar solicitud de cambio'), findsOneWidget);
      expect(find.text('Permanecer en mi iglesia'), findsOneWidget);
      expect(find.text('Continuar con el cambio'), findsOneWidget);

      // Confirmar cancelación pulsando 'Permanecer en mi iglesia'
      await tester.tap(find.text('Permanecer en mi iglesia'));
      await tester.pumpAndSettle();

      // El contenido del banner desaparece (renderiza SizedBox.shrink)
      expect(userProvider.isChangePending, isFalse);
      expect(userProvider.membershipStatus, equals('approved'));
      expect(find.textContaining('Tu solicitud para trasladarte'), findsNothing);
      expect(find.text('Cancelar'), findsNothing);
    });
  });
}
