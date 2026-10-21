import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/admin_models.dart';

void main() {
  group('AtrioApi RBAC, Cabeceras y Modo Solo Lectura (Odoo 19)', () {
    test('Bloquea mutaciones en cliente cuando isReadOnly es true', () async {
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'token_prueba_jwt',
        isReadOnly: true,
      );

      // Intentar publicar aviso debe lanzar AtrioApiException con código read_only sin llamar red
      expect(
        () => api.adminCreateAnnouncement(
          title: 'Aviso Test',
          content: 'Contenido',
        ),
        throwsA(
          isA<AtrioApiException>()
              .having((e) => e.code, 'code', 'read_only')
              .having((e) => e.status, 'status', 403),
        ),
      );

      // Intentar moderar petición debe lanzar AtrioApiException con código read_only
      expect(
        () => api.adminModeratePrayerRequest(
          requestId: 99,
          action: 'approve',
        ),
        throwsA(
          isA<AtrioApiException>()
              .having((e) => e.code, 'code', 'read_only'),
        ),
      );

      // Intentar registrar a evento debe ser bloqueado en cliente
      expect(
        () => api.registerToEvent(5),
        throwsA(
          isA<AtrioApiException>()
              .having((e) => e.code, 'code', 'read_only'),
        ),
      );
    });

    test('defaultChurchId se configura y sincroniza en AtrioApi', () {
      final api = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'token_valido',
        defaultChurchId: 25,
      );

      expect(api.defaultChurchId, 25);
      expect(api.isAuthenticated, isTrue);

      api.defaultChurchId = 42;
      expect(api.defaultChurchId, 42);
    });
  });

  group('Modelos Administrativos Odoo 19 (/admin/*)', () {
    test('AdminAnnouncementModel deserializa y limpia HTML en plainContent', () {
      final json = {
        'id': 10,
        'title': 'Vigilia Especial',
        'content': '<p>Vigilia este <strong>viernes</strong> a las 8pm.&nbsp;</p>',
        'target_group_ids': [1, 2],
        'pinned': true,
        'author_name': 'Secretaría Pastoral',
      };

      final aviso = AdminAnnouncementModel.fromJson(json);

      expect(aviso.id, 10);
      expect(aviso.title, 'Vigilia Especial');
      expect(aviso.isPinned, isTrue);
      expect(aviso.targetGroupIds, [1, 2]);
      expect(aviso.plainContent, 'Vigilia este viernes a las 8pm.');
    });

    test('AdminAnnouncementModel deserializa payload Odoo 19 con message y group_ids', () {
      final json = {
        'id': 4,
        'title': 'Aviso Odoo 19',
        'message': '<p>Contenido oficial con formato <b>Odoo</b>.</p>',
        'group_ids': [5, 8],
        'pinned': false,
        'sent_date': '2026-10-21T20:15:00Z',
      };

      final aviso = AdminAnnouncementModel.fromJson(json);

      expect(aviso.id, 4);
      expect(aviso.title, 'Aviso Odoo 19');
      expect(aviso.content, '<p>Contenido oficial con formato <b>Odoo</b>.</p>');
      expect(aviso.plainContent, 'Contenido oficial con formato Odoo.');
      expect(aviso.targetGroupIds, [5, 8]);
      expect(aviso.createDate, '2026-10-21T20:15:00Z');
    });

    test('AdminGroupModel deserializa audiencias correctamente', () {
      final json = {
        'id': 3,
        'name': 'Líderes de Jóvenes',
        'code': 'jovenes_lideres',
        'member_count': 24,
        'description': 'Grupo de coordinación juvenil',
      };

      final grupo = AdminGroupModel.fromJson(json);

      expect(grupo.id, 3);
      expect(grupo.name, 'Líderes de Jóvenes');
      expect(grupo.memberCount, 24);
      expect(grupo.code, 'jovenes_lideres');
    });

    test('AdminPrayerRequestModel maneja estados y banderas de moderación', () {
      final json = {
        'id': 50,
        'title': 'Salud de familiar',
        'description': 'Oración por pronta recuperación de mi madre',
        'applicant_name': 'Hermano Roberto',
        'state': 'pending',
        'is_anonymous': false,
        'date': '2026-10-21',
      };

      final req = AdminPrayerRequestModel.fromJson(json);

      expect(req.id, 50);
      expect(req.isPending, isTrue);
      expect(req.isApproved, isFalse);
      expect(req.isRejected, isFalse);
      expect(req.applicantName, 'Hermano Roberto');
    });

    test('AdminAnalyticsModel procesa métricas consolidadas', () {
      final json = {
        'period': 'month',
        'metrics': {
          'total_members': 340,
          'new_members': 12,
          'active_groups': 8,
          'prayer_requests_total': 45,
          'pending_moderation': 3,
          'total_offerings': 12500.50,
          'event_registrations': 88,
        },
      };

      final analytics = AdminAnalyticsModel.fromJson(json);

      expect(analytics.period, 'month');
      expect(analytics.totalMembers, 340);
      expect(analytics.newMembersThisMonth, 12);
      expect(analytics.pendingModerationCount, 3);
      expect(analytics.totalOfferingsAmount, 12500.50);
      expect(analytics.eventRegistrationsCount, 88);
    });
  });
}
