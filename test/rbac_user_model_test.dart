import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/modelos/user_model.dart';

void main() {
  group('UserModel RBAC y Roles Odoo 19', () {
    test(
      'Deserializa correctamente usuario church_admin con permisos y church_id',
      () {
        final odooJson = {
          'id': 101,
          'name': 'Pastor Juan Pérez',
          'email': 'pastor@iglesia.org',
          'church_id': 15,
          'role': 'church_admin',
          'permissions': ['manage_posts', 'manage_events', 'manage_requests'],
          'read_only': false,
          'is_member': true,
        };

        final user = UserModel.fromOdooJson(odooJson);

        expect(user.id, 101);
        expect(user.nombre, 'Pastor Juan Pérez');
        expect(user.email, 'pastor@iglesia.org');
        expect(user.iglesiaId, 15);
        expect(user.role, UserRole.churchAdmin);
        expect(user.isChurchAdmin, isTrue);
        expect(user.isPlatformAdmin, isFalse);
        expect(user.isReadOnly, isFalse);
        expect(user.canWrite, isTrue);
        expect(user.hasPermission(AppPermissions.managePosts), isTrue);
        expect(user.hasPermission(AppPermissions.manageEvents), isTrue);
        expect(user.hasPermission('manage_donations'), isFalse);
      },
    );

    test('Deserializa payload anidado user: { ... } con platform_admin en modo auditoría (read_only)', () {
      final odooJson = {
        'user': {
          'id': 1,
          'name': 'Auditor Global',
          'email': 'admin@atrio.com',
          'role': 'platform_admin',
          'permissions': ['view_all', 'audit'],
          'read_only': true,
        },
      };

      final user = UserModel.fromOdooJson(odooJson);

      expect(user.id, 1);
      expect(user.role, UserRole.platformAdmin);
      expect(user.isPlatformAdmin, isTrue);
      expect(user.isChurchAdmin, isFalse);
      expect(user.isReadOnly, isTrue);
      // En modo solo lectura, canWrite debe ser false sin importar el rol
      expect(user.canWrite, isFalse);
      expect(user.hasPermission('audit'), isTrue);
    });

    test('Usuario regular sin iglesia y sin permisos administrativos', () {
      final odooJson = {
        'id': 99,
        'name': 'Carlos Nuevo',
        'email': 'carlos@gmail.com',
        'role': 'user',
        'read_only': false,
      };

      final user = UserModel.fromOdooJson(odooJson);

      expect(user.role, UserRole.user);
      expect(user.isChurchAdmin, isFalse);
      expect(user.isPlatformAdmin, isFalse);
      expect(user.isReadOnly, isFalse);
      // Un usuario regular (no miembro / no admin) no puede escribir según canWrite
      expect(user.canWrite, isFalse);
      expect(user.iglesiaId, isNull);
      expect(user.permissions, isEmpty);
      expect(user.hasPermission(AppPermissions.managePosts), isFalse);
    });

    test('Serialización y deserialización conservan datos RBAC', () {
      final original = UserModel(
        id: 77,
        nombre: 'Hermana María',
        email: 'maria@iglesia.org',
        iglesiaActual: 'Iglesia Central',
        iglesiaId: 10,
        fechaRegistro: '2026-01-01',
        avatarIniciales: 'HM',
        esMiembroVerificado: true,
        role: UserRole.member,
        permissions: const {'create_requests', 'view_events'},
        isReadOnly: false,
      );

      final json = original.toJson();
      final reconstruido = UserModel.fromOdooJson(json);

      expect(reconstruido.id, original.id);
      expect(reconstruido.role, UserRole.member);
      expect(reconstruido.isMember, isTrue);
      expect(reconstruido.iglesiaId, 10);
      expect(reconstruido.hasPermission('create_requests'), isTrue);
      expect(reconstruido.isReadOnly, isFalse);
    });

    test('Validación de canDonate: invitado y rol user NO pueden donar', () {
      bool canUserDonate(UserModel? u) {
        if (u == null) return false;
        return !u.isReadOnly &&
            (u.role == UserRole.member || u.role == UserRole.churchAdmin) &&
            u.hasChurchAssigned;
      }

      // 1. Invitado / Sin sesión
      expect(canUserDonate(null), isFalse);

      // 2. Rol user (recién registrado, pendiente de aprobación o membresía)
      final userPendiente = UserModel(
        id: 50,
        nombre: 'Nuevo Creyente',
        email: 'nuevo@atrio.app',
        iglesiaActual: 'Sin Congregación',
        fechaRegistro: '2026-03-01',
        avatarIniciales: 'NC',
        role: UserRole.user,
        iglesiaId: 10,
        esMiembroVerificado: false,
      );
      expect(canUserDonate(userPendiente), isFalse);

      // 3. Platform admin con read_only
      final platformAdminReadOnly = UserModel(
        id: 1,
        nombre: 'Superadmin Auditor',
        email: 'super@atrio.app',
        iglesiaActual: 'Sede Central',
        fechaRegistro: '2026-01-01',
        avatarIniciales: 'SA',
        role: UserRole.platformAdmin,
        isReadOnly: true,
        iglesiaId: 10,
        esMiembroVerificado: true,
      );
      expect(canUserDonate(platformAdminReadOnly), isFalse);

      // 4. Miembro regular asignado a iglesia
      final miembroValido = UserModel(
        id: 20,
        nombre: 'Hermano Miembro',
        email: 'miembro@atrio.app',
        iglesiaActual: 'Iglesia Central',
        fechaRegistro: '2026-02-01',
        avatarIniciales: 'HM',
        role: UserRole.member,
        iglesiaId: 10,
        esMiembroVerificado: true,
      );
      expect(canUserDonate(miembroValido), isTrue);

      // 5. Miembro sin iglesia asignada
      final miembroSinIglesia = UserModel(
        id: 21,
        nombre: 'Miembro Flotante',
        email: 'flotante@atrio.app',
        iglesiaActual: '',
        fechaRegistro: '2026-02-15',
        avatarIniciales: 'MF',
        role: UserRole.member,
        iglesiaId: null,
        esMiembroVerificado: true,
      );
      expect(canUserDonate(miembroSinIglesia), isFalse);
    });

    test('AppPermissions contiene las constantes y conjuntos canónicos oficiales de Pablo Oliveros', () {
      // 1. Constantes canónicas individuales
      expect(AppPermissions.viewContent, 'view_content');
      expect(AppPermissions.registerEvents, 'register_events');
      expect(AppPermissions.createOfferings, 'create_offerings');
      expect(AppPermissions.createRequests, 'create_requests');
      expect(AppPermissions.manageProfile, 'manage_profile');
      expect(AppPermissions.shop, 'shop');
      expect(AppPermissions.donate, 'donate');
      expect(AppPermissions.managePosts, 'manage_posts');
      expect(AppPermissions.manageEvents, 'manage_events');
      expect(AppPermissions.manageAnnouncements, 'manage_announcements');
      expect(AppPermissions.manageAds, 'manage_ads');
      expect(AppPermissions.manageRequests, 'manage_requests');
      expect(AppPermissions.viewStats, 'view_stats');
      expect(AppPermissions.viewAdminNotifications, 'view_admin_notifications');
      expect(AppPermissions.viewAllChurches, 'view_all_churches');
      expect(AppPermissions.viewAdminContent, 'view_admin_content');
      expect(AppPermissions.readOnly, 'read_only');

      // 2. Conjunto de Miembro (Pág. 3)
      expect(AppPermissions.memberOfficialPermissions, {
        'view_content',
        'register_events',
        'create_offerings',
        'create_requests',
        'manage_profile',
        'shop',
        'donate',
      });

      // 3. Conjunto adicional de Administrador de Iglesia (Pág. 4)
      expect(AppPermissions.churchAdminAdditionalPermissions, {
        'manage_posts',
        'manage_events',
        'manage_announcements',
        'manage_ads',
        'view_admin_notifications',
        'manage_requests',
        'view_stats',
      });

      // 4. Conjunto de Super Admin (Pág. 5)
      expect(AppPermissions.platformAdminOfficialPermissions, {
        'view_all_churches',
        'view_content',
        'view_admin_content',
        'read_only',
      });
    });

    test(
      'Usuario rol member con church_id relacional tipo Odoo ([id, name]) preserva iglesia asignada',
      () {
        final odooJson = {
          'user': {
            'id': 50,
            'name': 'Hermano Lenin',
            'email': 'leningrado777@demo.app',
            'role': 'member',
            'church_id': [12, 'Iglesia Bautista de la Gracia'],
          },
          'permissions': ['view_content', 'create_offerings'],
        };

        final user = UserModel.fromOdooJson(odooJson);

        expect(user.id, 50);
        expect(user.role, UserRole.member);
        expect(user.isMember, isTrue);
        expect(user.iglesiaId, 12);
        expect(user.iglesiaActual, 'Iglesia Bautista de la Gracia');
        expect(user.hasChurchAssigned, isTrue);
      },
    );

    test('Usuario rol member con payload plano church_name y church_id', () {
      final odooJson = {
        'id': 51,
        'name': 'Hermano Lenin Plano',
        'email': 'leningrado777@demo.app',
        'role': 'member',
        'church_id': 14,
        'church_name': 'Comunidad de Fe Central',
      };

      final user = UserModel.fromOdooJson(odooJson);

      expect(user.id, 51);
      expect(user.role, UserRole.member);
      expect(user.isMember, isTrue);
      expect(user.iglesiaId, 14);
      expect(user.iglesiaActual, 'Comunidad de Fe Central');
      expect(user.hasChurchAssigned, isTrue);
    });

    test('Usuario sin iglesia asociada (church_id null) indica hasChurchAssigned == false', () {
      final odooJson = {
        'user': {
          'id': 99,
          'name': 'Visitante Nuevo',
          'email': 'visitante@demo.app',
          'role': 'user',
        },
      };

      final user = UserModel.fromOdooJson(odooJson);

      expect(user.id, 99);
      expect(user.role, UserRole.user);
      expect(user.isMember, isFalse);
      expect(user.hasChurchAssigned, isFalse);
    });
  });
}


