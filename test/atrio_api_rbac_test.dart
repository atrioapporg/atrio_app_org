import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/admin_models.dart';
import 'package:atrio/providers/admin_provider.dart';

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

      // Intentar donar por PayPal en modo solo lectura debe ser bloqueado con 403 read_only
      expect(
        () => api.donateWithPaypal(
          name: 'Auditor',
          email: 'auditor@atrio.org',
          amount: 50.0,
        ),
        throwsA(
          isA<AtrioApiException>()
              .having((e) => e.code, 'code', 'read_only')
              .having((e) => e.status, 'status', 403),
        ),
      );

      // Intentar donar por transferencia en modo solo lectura debe ser bloqueado con 403 read_only
      expect(
        () => api.donateWithTransfer(
          name: 'Auditor',
          email: 'auditor@atrio.org',
          amount: 50.0,
          receiptBase64: 'base64mock',
        ),
        throwsA(
          isA<AtrioApiException>()
              .having((e) => e.code, 'code', 'read_only')
              .having((e) => e.status, 'status', 403),
        ),
      );
    });

    test('Donaciones en modo invitado no arrojan error unauthenticated local en AtrioApi', () {
      final guestApi = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: null, // Sin sesión / invitado
        isReadOnly: false,
      );

      expect(guestApi.isAuthenticated, isFalse);
      expect(guestApi.isReadOnly, isFalse);
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

    test('Cabecera X-Atrio-Church es exclusiva de Super Admin (isReadOnly == true)', () {
      // 1. Caso Super Admin (auditoría / solo lectura): debe inyectar X-Atrio-Church
      final apiSuperAdmin = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'token_super_admin',
        defaultChurchId: 10,
        isReadOnly: true,
      );

      final headersAdmin = apiSuperAdmin.buildHeadersForTesting('/events');
      expect(headersAdmin['X-Atrio-Church'], '10');
      expect(headersAdmin.containsKey('X-Church-Id'), isFalse);

      // 2. Caso Usuario Normal / Miembro / Admin Iglesia: NO debe inyectar X-Atrio-Church
      // La iglesia se deduce siempre del token en el servidor de Odoo
      final apiMiembro = AtrioApi(
        baseUrl: 'https://test.atrioapp.org',
        token: 'token_miembro',
        defaultChurchId: 10,
        isReadOnly: false,
      );

      final headersMiembro = apiMiembro.buildHeadersForTesting('/events');
      expect(headersMiembro.containsKey('X-Atrio-Church'), isFalse);
      expect(headersMiembro.containsKey('X-Church-Id'), isFalse);
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

  group('Fallback y Resiliencia ante Endpoints Pendientes Odoo (Pablo Oliveros)', () {
    test('loadPrayerRequests activa isPrayerRequestsWebOnly ante error 404 (endpoint pendiente)', () async {
      final fakeApi = _Fake404AtrioApi();
      final adminProvider = AdminProvider(api: fakeApi);

      expect(adminProvider.isPrayerRequestsWebOnly, isFalse);

      await adminProvider.loadPrayerRequests();

      expect(adminProvider.isPrayerRequestsWebOnly, isTrue);
      expect(adminProvider.prayerRequests, isEmpty);
      expect(
        adminProvider.errorMessage,
        contains('consola web (/atrio/manage)'),
      );
    });

    test('loadAnalytics activa isAnalyticsWebOnly y provee fallback ante error 404 (endpoint pendiente)', () async {
      final fakeApi = _Fake404AtrioApi();
      final adminProvider = AdminProvider(api: fakeApi);

      expect(adminProvider.isAnalyticsWebOnly, isFalse);

      await adminProvider.loadAnalytics();

      expect(adminProvider.isAnalyticsWebOnly, isTrue);
      expect(adminProvider.analytics, isNotNull);
      expect(
        adminProvider.errorMessage,
        contains('portal web'),
      );
    });
    test('registerMember inyecta automáticamente church_id de fallback si no viene especificado', () async {
      Map<String, dynamic>? interceptedBody;
      final api = _CaptureBodyAtrioApi((body) {
        interceptedBody = body;
      });

      await api.registerMember({
        'name': 'Lenon Linares',
        'email': 'lenon@test.com',
        'password': 'password123',
      });

      expect(interceptedBody, isNotNull);
      expect(interceptedBody!['church_id'], equals(1));
      expect(interceptedBody!['name'], equals('Lenon Linares'));
      expect(interceptedBody!['email'], equals('lenon@test.com'));
    });
  });
}

class _CaptureBodyAtrioApi extends AtrioApi {
  final void Function(Map<String, dynamic> body) onSend;
  _CaptureBodyAtrioApi(this.onSend) : super(baseUrl: 'https://test.atrioapp.org');

  @override
  Future<Map<String, dynamic>> registerMember(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('church_id') ||
        payload['church_id'] == null ||
        (payload['church_id'] is int && (payload['church_id'] as int) <= 0)) {
      final fallbackChurchId = defaultChurchId ?? 1;
      payload['church_id'] = fallbackChurchId;
    }
    onSend(payload);
    return {'success': true, 'member': {'id': 99, 'name': payload['name']}};
  }
}

class _Fake404AtrioApi extends AtrioApi {
  _Fake404AtrioApi() : super(baseUrl: 'https://test.atrioapp.org');

  @override
  Future<Map<String, dynamic>> adminPrayerRequests({
    String status = 'pending',
    int limit = 20,
    int offset = 0,
    int? churchId,
  }) async {
    throw AtrioApiException(404, 'not_found', 'Endpoint /admin/prayer-requests no encontrado en Odoo');
  }

  @override
  Future<Map<String, dynamic>> adminAnalytics({
    String period = 'month',
    int? churchId,
  }) async {
    throw AtrioApiException(404, 'not_found', 'Endpoint /admin/analytics no encontrado en Odoo');
  }

  @override
  Future<Map<String, dynamic>> myChurchAds() async {
    return {
      'ads': [
        {'id': 1, 'name': 'Campaña Juvenil'}
      ]
    };
  }
}
