import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/widgets/permission_guard.dart';
import 'package:atrio/widgets/read_only_banner.dart';

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

  group('PermissionGuard Widget Tests', () {
    testWidgets('Muestra el widget hijo si el usuario tiene el permiso requerido',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 1,
          nombre: 'Pastor David',
          email: 'pastor@atrio.org',
          iglesiaActual: 'Iglesia Central',
          iglesiaId: 10,
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'PD',
          esMiembroVerificado: true,
          role: UserRole.churchAdmin,
          permissions: const {'manage_announcements'},
          isReadOnly: false,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          userProvider: userProvider,
          child: const PermissionGuard(
            requiredPermission: 'manage_announcements',
            child: Text('BOTON_PUBLICAR_AVISO'),
          ),
        ),
      );

      expect(find.text('BOTON_PUBLICAR_AVISO'), findsOneWidget);
    });

    testWidgets('Oculta el widget hijo si el usuario no tiene el permiso requerido',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 2,
          nombre: 'Usuario Regular',
          email: 'user@atrio.org',
          iglesiaActual: 'Iglesia Central',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'UR',
          esMiembroVerificado: false,
          role: UserRole.user,
          permissions: const {},
          isReadOnly: false,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          userProvider: userProvider,
          child: const PermissionGuard(
            requiredPermission: 'manage_announcements',
            child: Text('BOTON_PUBLICAR_AVISO'),
          ),
        ),
      );

      expect(find.text('BOTON_PUBLICAR_AVISO'), findsNothing);
    });

    testWidgets('Oculta contenido cuando disallowReadOnly es true y el usuario es read_only',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 3,
          nombre: 'Auditor Global',
          email: 'auditor@atrio.org',
          iglesiaActual: 'Todas',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'AG',
          esMiembroVerificado: true,
          role: UserRole.platformAdmin,
          permissions: const {'manage_announcements'},
          isReadOnly: true,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          userProvider: userProvider,
          child: const PermissionGuard(
            requiredPermission: 'manage_announcements',
            disallowReadOnly: true,
            fallback: Text('MODO_SOLO_LECTURA_FALLBACK'),
            child: Text('BOTON_MUTACION_CONTENIDO'),
          ),
        ),
      );

      expect(find.text('BOTON_MUTACION_CONTENIDO'), findsNothing);
      expect(find.text('MODO_SOLO_LECTURA_FALLBACK'), findsOneWidget);
    });
  });

  group('ReadOnlyBanner Widget Tests', () {
    testWidgets('No renderiza banner cuando isReadOnly es false', (tester) async {
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 1,
          nombre: 'Usuario Normal',
          email: 'normal@atrio.org',
          iglesiaActual: 'Iglesia',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'UN',
          esMiembroVerificado: true,
          role: UserRole.member,
          isReadOnly: false,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          userProvider: userProvider,
          child: const ReadOnlyBanner(),
        ),
      );

      expect(find.byType(ReadOnlyBanner), findsOneWidget);
      // El banner debe renderizar SizedBox.shrink() cuando no es read_only
      expect(find.byIcon(Icons.lock_clock_outlined), findsNothing);
    });

    testWidgets('Renderiza banner visible con advertencia cuando isReadOnly es true',
        (tester) async {
      final userProvider = UserProvider();
      userProvider.setCurrentUserForTesting(
        UserModel(
          id: 1,
          nombre: 'Usuario Solo Lectura',
          email: 'readonly@atrio.org',
          iglesiaActual: 'Iglesia',
          fechaRegistro: '2026-01-01',
          avatarIniciales: 'SL',
          esMiembroVerificado: true,
          role: UserRole.platformAdmin,
          isReadOnly: true,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          userProvider: userProvider,
          child: const ReadOnlyBanner(),
        ),
      );

      expect(find.byIcon(Icons.lock_clock_outlined), findsOneWidget);
      expect(
        find.text(
          'Modo de solo lectura activado. Las funciones de publicación y registro están deshabilitadas.',
        ),
        findsOneWidget,
      );
    });
  });
}
