import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Máquina de Estados ATRIO - resolveStage', () {
    test('Sin datos (null o vacío) debe devolver AppStage.welcome', () {
      expect(resolveStage(null), equals(AppStage.welcome));
      expect(resolveStage({}), equals(AppStage.welcome));
    });

    test('Super Admin (platform_admin) debe devolver AppStage.platformAdmin', () {
      final me = {
        'role': 'platform_admin',
        'permissions': ['view_all_churches', 'manage_platform'],
        'read_only': true,
        'membership_status': 'none',
      };
      expect(resolveStage(me), equals(AppStage.platformAdmin));
    });

    test('Usuario con solicitud pendiente de aprobación debe devolver AppStage.waitingApproval', () {
      final me = {
        'role': 'user',
        'membership_status': 'membership_pending',
        'requested_church_id': 7,
        'church': null,
      };
      expect(resolveStage(me), equals(AppStage.waitingApproval));
    });

    test('Admin de iglesia sin activar (has_active_subscription == false) debe devolver AppStage.churchPendingActivation', () {
      final me = {
        'role': 'church_admin',
        'membership_status': 'approved',
        'church': {
          'id': 12,
          'name': 'Iglesia Vida Nueva',
          'has_active_subscription': false,
        },
      };
      expect(resolveStage(me), equals(AppStage.churchPendingActivation));
    });

    test('Admin de iglesia con suscripción activa debe devolver AppStage.adminHome', () {
      final me = {
        'role': 'church_admin',
        'membership_status': 'approved',
        'church': {
          'id': 12,
          'name': 'Iglesia Vida Nueva',
          'has_active_subscription': true,
        },
      };
      expect(resolveStage(me), equals(AppStage.adminHome));
    });

    test('Miembro activo con iglesia activa debe devolver AppStage.memberHome', () {
      final me = {
        'role': 'member',
        'membership_status': 'approved',
        'church': {
          'id': 5,
          'name': 'Catedral Central',
          'has_active_subscription': true,
        },
      };
      expect(resolveStage(me), equals(AppStage.memberHome));
    });

    test('Miembro con cambio de iglesia pendiente (change_pending) debe devolver AppStage.memberHome', () {
      final me = {
        'role': 'member',
        'membership_status': 'change_pending',
        'requested_church_id': 9,
        'church': {
          'id': 5,
          'name': 'Catedral Central',
          'has_active_subscription': true,
        },
      };
      expect(resolveStage(me), equals(AppStage.memberHome));
    });

    test('Usuario sin iglesia (role user, membership none) debe devolver AppStage.chooseChurch', () {
      final me = {
        'role': 'user',
        'membership_status': 'none',
        'requested_church_id': null,
        'church': null,
      };
      expect(resolveStage(me), equals(AppStage.chooseChurch));
    });
  });

  group('UserModel - Soporte Odoo 19 de Membresía y Suscripción', () {
    test('Parsea correctamente membership_status, requested_church_id y has_active_subscription desde JSON de Odoo', () {
      final odooJson = {
        'id': 42,
        'name': 'Carlos Santana',
        'email': 'carlos@santana.org',
        'role': 'user',
        'membership_status': 'membership_pending',
        'requested_church_id': 15,
        'church': {
          'id': 15,
          'name': 'Iglesia Gracia y Paz',
          'has_active_subscription': false,
        },
      };

      final user = UserModel.fromOdooJson(odooJson);

      expect(user.id, equals(42));
      expect(user.nombre, equals('Carlos Santana'));
      expect(user.membershipStatus, equals('membership_pending'));
      expect(user.isMembershipPending, isTrue);
      expect(user.requestedChurchId, equals(15));
      expect(user.hasActiveSubscription, isFalse);
    });

    test('copyWith y toJson preservan los nuevos campos', () {
      final user = UserModel(
        id: 1,
        nombre: 'Ana López',
        email: 'ana@lopez.com',
        iglesiaActual: 'Iglesia Vida',
        fechaRegistro: '2026-01-01',
        avatarIniciales: 'AL',
        esMiembroVerificado: true,
        role: UserRole.churchAdmin,
        membershipStatus: 'approved',
        hasActiveSubscription: true,
      );

      final copy = user.copyWith(membershipStatus: 'change_pending');
      expect(copy.membershipStatus, equals('change_pending'));
      expect(copy.hasActiveSubscription, isTrue);

      final json = copy.toJson();
      expect(json['membership_status'], equals('change_pending'));
      expect(json['has_active_subscription'], isTrue);
    });
  });

  group('UserProvider - currentStage reactivo', () {
    test('Refleja correctamente currentStage a partir de rawMeData', () {
      final provider = UserProvider();

      // Inicialmente sin usuario
      expect(provider.currentStage, equals(AppStage.welcome));

      // Asignamos usuario en espera de aprobación
      final userPending = UserModel(
        id: 10,
        nombre: 'Pedro',
        email: 'pedro@correo.com',
        iglesiaActual: 'Sin iglesia',
        fechaRegistro: '2026-01-01',
        avatarIniciales: 'P',
        esMiembroVerificado: false,
        role: UserRole.user,
        membershipStatus: 'membership_pending',
        requestedChurchId: 7,
      );

      provider.setCurrentUserForTesting(
        userPending,
        rawMeData: {
          'role': 'user',
          'membership_status': 'membership_pending',
          'requested_church_id': 7,
        },
      );

      expect(provider.currentStage, equals(AppStage.waitingApproval));
      expect(provider.isWaitingApproval, isTrue);
      expect(provider.isChurchPendingActivation, isFalse);
    });
  });
}
