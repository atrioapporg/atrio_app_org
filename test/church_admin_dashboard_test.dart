import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/modelos/admin_models.dart';

void main() {
  group('Pruebas Unitarias - Módulo Dashboard Pastoral Admin Odoo 19', () {
    test('1. Parseo de AdminChurchRequestModel desde payload real de Odoo 19', () {
      final json = {
        'id': 14,
        'type': 'ayuda',
        'title': 'Eros hac inceptos varid sollicit',
        'message': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        'state': 'respondida',
        'response': 'Bendiciones hermano, tu solicitud ha sido respondida.',
        'rejection_reason': null,
        'created_at': '2026-10-22T22:29:18Z',
        'updated_at': '2026-10-31T20:56:26Z',
        'requester_name': 'Lenin',
        'requester': {
          'id': 9,
          'name': 'Lenin',
          'email': 'leningrado777@demo.app',
          'phone': '18099581122',
        },
      };

      final req = AdminChurchRequestModel.fromJson(json);

      expect(req.id, 14);
      expect(req.type, 'ayuda');
      expect(req.title, 'Eros hac inceptos varid sollicit');
      expect(req.state, 'respondida');
      expect(req.isAnswered, isTrue);
      expect(req.isNew, isFalse);
      expect(req.response, contains('Bendiciones hermano'));
      expect(req.requesterName, 'Lenin');
      expect(req.requester?.email, 'leningrado777@demo.app');
      expect(req.requester?.phone, '18099581122');
    });

    test('2. Parseo de AdminChurchStatsModel desde /admin/stats de Odoo 19', () {
      final json = {
        'period': 'month',
        'since': '2026-10-01',
        'members': {'active': 8, 'pending': 2, 'new': 8},
        'posts': {'published': 2},
        'announcements': {'sent': 1},
        'events': {'held': 5, 'registrations': 5},
        'offerings': {
          'count': 1,
          'total': 50.0,
          'currency': {'code': 'DOP', 'symbol': 'RD\$'},
        },
      };

      final stats = AdminChurchStatsModel.fromJson(json);

      expect(stats.period, 'month');
      expect(stats.since, '2026-10-01');
      expect(stats.activeMembers, 8);
      expect(stats.pendingMembers, 2);
      expect(stats.newMembers, 8);
      expect(stats.publishedPosts, 2);
      expect(stats.sentAnnouncements, 1);
      expect(stats.heldEvents, 5);
      expect(stats.eventRegistrations, 5);
      expect(stats.offeringsCount, 1);
      expect(stats.offeringsTotal, 50.0);
      expect(stats.currencyCode, 'DOP');
      expect(stats.currencySymbol, 'RD\$');
    });

    test('3. Parseo de AdminNotificationItemModel desde /admin/notifications', () {
      final json = {
        'id': 156,
        'title': 'Prueba Publicidad',
        'message': 'Nueva campaña iniciada',
        'category': 'ad',
        'target_page': '/atrio/ad/7/click',
        'is_read': true,
        'created_at': '2026-10-31T04:01:25Z',
        'dismissed_at': null,
      };

      final notif = AdminNotificationItemModel.fromJson(json);

      expect(notif.id, 156);
      expect(notif.title, 'Prueba Publicidad');
      expect(notif.category, 'ad');
      expect(notif.isRead, isTrue);
      expect(notif.targetPage, '/atrio/ad/7/click');
    });

    test('4. copyWith en AdminChurchRequestModel para actualización reactiva en memoria', () {
      final original = AdminChurchRequestModel(
        id: 20,
        type: 'oracion',
        title: 'Petición salud',
        message: 'Oración por salud',
        state: 'nueva',
        createdAt: '2026-10-31T10:00:00Z',
        requesterName: 'Hermano Juan',
      );

      final updated = original.copyWith(
        state: 'respondida',
        response: 'El equipo pastoral está orando por ti.',
        updatedAt: '2026-10-31T11:00:00Z',
      );

      expect(updated.id, original.id);
      expect(updated.state, 'respondida');
      expect(updated.isAnswered, isTrue);
      expect(updated.response, 'El equipo pastoral está orando por ti.');
      expect(updated.updatedAt, '2026-10-31T11:00:00Z');
      expect(updated.requesterName, 'Hermano Juan');
    });
  });
}
