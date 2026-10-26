import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/models/event_dto.dart';
import 'package:atrio/models/sermon_dto.dart';
import 'package:atrio/providers/admin_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/widgets/permission_guard.dart';

/// Fake AtrioApi para probar los flujos administrativos sin requerir red.
class FakeAdminAtrioApi extends AtrioApi {
  FakeAdminAtrioApi() : super(baseUrl: 'https://test.atrio.app');

  final List<Map<String, dynamic>> mockEvents = [];
  final List<Map<String, dynamic>> mockPosts = [];

  @override
  Future<Map<String, dynamic>> adminEvents({
    int limit = 50,
    int offset = 0,
    int? churchId,
  }) async {
    return {'events': mockEvents, 'total': mockEvents.length};
  }

  @override
  Future<Map<String, dynamic>> adminCreateEvent(
    Map<String, dynamic> eventData, {
    int? churchId,
  }) async {
    final created = Map<String, dynamic>.from(eventData);
    created['id'] = 999;
    mockEvents.insert(0, created);
    return {'event': created, 'status': 'success'};
  }

  @override
  Future<Map<String, dynamic>> adminUpdateEvent(
    int eventId,
    Map<String, dynamic> eventData, {
    int? churchId,
  }) async {
    final updated = Map<String, dynamic>.from(eventData);
    updated['id'] = eventId;
    return {'event': updated, 'status': 'success'};
  }

  @override
  Future<Map<String, dynamic>> adminDeleteEvent(
    int eventId, {
    int? churchId,
  }) async {
    mockEvents.removeWhere((e) => e['id'] == eventId);
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> adminPosts({
    int limit = 50,
    int offset = 0,
    int? churchId,
  }) async {
    return {'posts': mockPosts, 'total': mockPosts.length};
  }

  @override
  Future<Map<String, dynamic>> adminCreatePost(
    Map<String, dynamic> postData, {
    int? churchId,
  }) async {
    final created = Map<String, dynamic>.from(postData);
    created['id'] = 888;
    mockPosts.insert(0, created);
    return {'post': created, 'status': 'success'};
  }

  @override
  Future<Map<String, dynamic>> adminUpdatePost(
    int postId,
    Map<String, dynamic> postData, {
    int? churchId,
  }) async {
    final updated = Map<String, dynamic>.from(postData);
    updated['id'] = postId;
    return {'post': updated, 'status': 'success'};
  }

  @override
  Future<Map<String, dynamic>> adminDeletePost(
    int postId, {
    int? churchId,
  }) async {
    mockPosts.removeWhere((p) => p['id'] == postId);
    return {'success': true};
  }
}

void main() {
  Widget createTestWidget({
    required UserProvider userProvider,
    required Widget child,
  }) {
    return ChangeNotifierProvider<UserProvider>.value(
      value: userProvider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(body: child),
      ),
    );
  }

  group('Etapa 3 - AdminProvider Unit Tests', () {
    late FakeAdminAtrioApi fakeApi;
    late AdminProvider adminProvider;

    setUp(() {
      fakeApi = FakeAdminAtrioApi();
      adminProvider = AdminProvider(api: fakeApi);
    });

    test('loadAdminEvents y createEvent actualizan el estado reactivo', () async {
      final nuevoEvento = EventDto(
        titulo: 'Congreso de Jóvenes',
        descripcion: 'Encuentro anual de avivamiento juvenil',
        fechaInicio: DateTime.now(),
        fechaFin: DateTime.now().add(const Duration(hours: 3)),
        modalidad: EventModality.hibrido,
        enlaceUbicacionOStream: 'https://youtube.com/live/uE53d7_-Unc',
        cupoMaximo: 200,
      );

      final ok = await adminProvider.createEvent(nuevoEvento);
      expect(ok, isTrue);
      expect(adminProvider.adminEvents.length, equals(1));
      expect(adminProvider.adminEvents.first.id, equals(999));
      expect(adminProvider.adminEvents.first.titulo, equals('Congreso de Jóvenes'));
      expect(adminProvider.adminEvents.first.tieneStreaming, isTrue);
    });

    test('updateEvent y deleteEvent operan adecuadamente sobre la lista local', () async {
      final eventoInicial = EventDto(
        id: 10,
        titulo: 'Vigilia',
        descripcion: 'Oración',
        fechaInicio: DateTime.now(),
        fechaFin: DateTime.now().add(const Duration(hours: 2)),
      );

      await adminProvider.createEvent(eventoInicial);

      final eventoModificado = eventoInicial.copyWith(
        id: 999,
        titulo: 'Vigilia General Actualizada',
      );

      final okUpdate = await adminProvider.updateEvent(eventoModificado);
      expect(okUpdate, isTrue);
      expect(adminProvider.adminEvents.first.titulo, equals('Vigilia General Actualizada'));

      final okDelete = await adminProvider.deleteEvent(999);
      expect(okDelete, isTrue);
      expect(adminProvider.adminEvents, isEmpty);
    });

    test('createSermon y deleteSermon para Prédicas y Streaming', () async {
      final nuevaPredica = SermonDto(
        titulo: 'Viviendo por Fe',
        predicador: 'Pastor Carlos',
        fecha: DateTime.now(),
        esEnVivo: true,
        plataforma: StreamingPlatform.youtube,
        urlOIdVideo: 'https://www.youtube.com/watch?v=uE53d7_-Unc',
      );

      final ok = await adminProvider.createSermon(nuevaPredica);
      expect(ok, isTrue);
      expect(adminProvider.adminSermons.length, equals(1));
      expect(adminProvider.adminSermons.first.id, equals(888));
      expect(adminProvider.adminSermons.first.esEnVivo, isTrue);
      expect(adminProvider.adminSermons.first.youtubeId, equals('uE53d7_-Unc'));

      final okDel = await adminProvider.deleteSermon(888);
      expect(okDel, isTrue);
      expect(adminProvider.adminSermons, isEmpty);
    });
  });

  group('Etapa 3 - PermissionGuard UI & RBAC Tests', () {
    testWidgets(
        'Muestra botón "+ Evento" exclusivamente a church_admin con permiso manage_events',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 1,
          nombre: 'Pastor Principal',
          email: 'pastor@atrio.org',
          iglesiaActual: 'Iglesia Central',
          iglesiaId: 10,
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'PP',
          esMiembroVerificado: true,
          role: UserRole.churchAdmin,
          permissions: const {AppPermissions.manageEvents},
          isReadOnly: false,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          userProvider: userProvider,
          child: const PermissionGuard(
            requireChurchAdmin: true,
            requiredPermission: AppPermissions.manageEvents,
            disallowReadOnly: true,
            child: Text('BTN_NUEVO_EVENTO'),
          ),
        ),
      );

      expect(find.text('BTN_NUEVO_EVENTO'), findsOneWidget);
    });

    testWidgets(
        'Muestra botón "+ Prédica" a church_admin con permiso manage_posts',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 2,
          nombre: 'Líder Multimedia',
          email: 'media@atrio.org',
          iglesiaActual: 'Iglesia Central',
          iglesiaId: 10,
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'LM',
          esMiembroVerificado: true,
          role: UserRole.churchAdmin,
          permissions: const {AppPermissions.managePosts},
          isReadOnly: false,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          userProvider: userProvider,
          child: const PermissionGuard(
            requireChurchAdmin: true,
            requiredPermission: AppPermissions.managePosts,
            disallowReadOnly: true,
            child: Text('BTN_NUEVA_PREDICA'),
          ),
        ),
      );

      expect(find.text('BTN_NUEVA_PREDICA'), findsOneWidget);
    });

    testWidgets(
        'Oculta botones de administración para usuario con rol regular member',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 3,
          nombre: 'Hermano Juan',
          email: 'juan@atrio.org',
          iglesiaActual: 'Iglesia Central',
          iglesiaId: 10,
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'HJ',
          esMiembroVerificado: true,
          role: UserRole.member,
          permissions: const {AppPermissions.viewContent, AppPermissions.registerEvents},
          isReadOnly: false,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          userProvider: userProvider,
          child: Column(
            children: const [
              PermissionGuard(
                requireChurchAdmin: true,
                requiredPermission: AppPermissions.manageEvents,
                disallowReadOnly: true,
                child: Text('BTN_NUEVO_EVENTO'),
              ),
              PermissionGuard(
                requireChurchAdmin: true,
                requiredPermission: AppPermissions.managePosts,
                disallowReadOnly: true,
                child: Text('BTN_NUEVA_PREDICA'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('BTN_NUEVO_EVENTO'), findsNothing);
      expect(find.text('BTN_NUEVA_PREDICA'), findsNothing);
    });

    testWidgets(
        'Oculta botones de creación si la cuenta está en modo solo lectura (read_only: true)',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 4,
          nombre: 'Auditor Global',
          email: 'auditor@atrio.org',
          iglesiaActual: 'Iglesia Central',
          iglesiaId: 10,
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'AG',
          esMiembroVerificado: true,
          role: UserRole.churchAdmin,
          permissions: const {AppPermissions.manageEvents, AppPermissions.managePosts},
          isReadOnly: true, // Modo solo lectura
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          userProvider: userProvider,
          child: Column(
            children: const [
              PermissionGuard(
                requireChurchAdmin: true,
                requiredPermission: AppPermissions.manageEvents,
                disallowReadOnly: true,
                child: Text('BTN_NUEVO_EVENTO'),
              ),
              PermissionGuard(
                requireChurchAdmin: true,
                requiredPermission: AppPermissions.managePosts,
                disallowReadOnly: true,
                child: Text('BTN_NUEVA_PREDICA'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('BTN_NUEVO_EVENTO'), findsNothing);
      expect(find.text('BTN_NUEVA_PREDICA'), findsNothing);
    });
  });
}
