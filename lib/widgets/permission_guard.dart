import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modelos/user_model.dart';
import '../providers/user_provider.dart';

/// Extensiones de conveniencia sobre [BuildContext] para evaluar
/// roles y permisos de forma limpia y reactiva en cualquier widget.
extension PermissionContextX on BuildContext {
  UserProvider get userProvider => read<UserProvider>();
  UserProvider get watchUserProvider => watch<UserProvider>();
  UserModel? get currentUser => watchUserProvider.currentUser;

  bool hasPermission(String permission) =>
      watchUserProvider.hasPermission(permission);

  bool hasAnyPermission(Iterable<String> perms) =>
      watchUserProvider.hasAnyPermission(perms);

  bool hasAllPermissions(Iterable<String> perms) =>
      watchUserProvider.hasAllPermissions(perms);

  bool get isChurchAdmin => watchUserProvider.isChurchAdmin;
  bool get isPlatformAdmin => watchUserProvider.isPlatformAdmin;
  bool get isMember => watchUserProvider.isMember;
  bool get isReadOnly => watchUserProvider.isReadOnly;
  bool get canWrite => watchUserProvider.canWrite;
}

/// Widget declarativo que renderiza [child] solo si el usuario actual cumple
/// con los permisos, roles y políticas de solo lectura requeridos.
class PermissionGuard extends StatelessWidget {
  /// Permiso singular obligatorio (ej. [AppPermissions.managePosts]).
  final String? requiredPermission;

  /// Lista de permisos donde al menos uno debe cumplirse.
  final Iterable<String>? anyPermissions;

  /// Lista de permisos donde todos deben cumplirse simultáneamente.
  final Iterable<String>? allPermissions;

  /// Lista blanca de roles permitidos para visualizar el widget.
  final List<UserRole>? allowedRoles;

  /// Si es true, requiere obligatoriamente que el usuario sea administrador de iglesia.
  final bool requireChurchAdmin;

  /// Si es true, requiere obligatoriamente que el usuario sea administrador global de plataforma.
  final bool requirePlatformAdmin;

  /// Si es true, requiere que el usuario sea miembro verificado o superior.
  final bool requireMember;

  /// Si es true, oculta el widget si el backend marcó la sesión como `read_only: true`.
  final bool disallowReadOnly;

  /// Widget a renderizar si se aprueban todas las reglas.
  final Widget child;

  /// Widget alternativo a renderizar si no se cumplen los permisos (por defecto vacío).
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    this.requiredPermission,
    this.anyPermissions,
    this.allPermissions,
    this.allowedRoles,
    this.requireChurchAdmin = false,
    this.requirePlatformAdmin = false,
    this.requireMember = false,
    this.disallowReadOnly = false,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    final isAuthorized = _evaluarPermisos(user);

    if (isAuthorized) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }

  bool _evaluarPermisos(UserModel? user) {
    if (user == null) {
      return false;
    }

    if (disallowReadOnly && user.isReadOnly) {
      return false;
    }

    if (requireChurchAdmin && !user.isChurchAdmin) {
      return false;
    }

    if (requirePlatformAdmin && !user.isPlatformAdmin) {
      return false;
    }

    if (requireMember && !user.isMember) {
      return false;
    }

    if (allowedRoles != null && allowedRoles!.isNotEmpty) {
      if (!allowedRoles!.contains(user.role)) {
        return false;
      }
    }

    if (requiredPermission != null &&
        !user.hasPermission(requiredPermission!)) {
      return false;
    }

    if (anyPermissions != null && anyPermissions!.isNotEmpty) {
      if (!anyPermissions!.any((p) => user.hasPermission(p))) {
        return false;
      }
    }

    if (allPermissions != null && allPermissions!.isNotEmpty) {
      if (!allPermissions!.every((p) => user.hasPermission(p))) {
        return false;
      }
    }

    return true;
  }
}

/// Constructor de interfaz que pasa el estado de autorización a una función builder,
/// ideal para botones que no deben desaparecer sino mostrarse deshabilitados o con candado.
class PermissionBuilder extends StatelessWidget {
  final String? requiredPermission;
  final Iterable<String>? anyPermissions;
  final Iterable<String>? allPermissions;
  final List<UserRole>? allowedRoles;
  final bool requireChurchAdmin;
  final bool requirePlatformAdmin;
  final bool requireMember;
  final bool disallowReadOnly;

  final Widget Function(
    BuildContext context,
    bool isAuthorized,
    UserModel? user,
  ) builder;

  const PermissionBuilder({
    super.key,
    this.requiredPermission,
    this.anyPermissions,
    this.allPermissions,
    this.allowedRoles,
    this.requireChurchAdmin = false,
    this.requirePlatformAdmin = false,
    this.requireMember = false,
    this.disallowReadOnly = false,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    bool isAuthorized = true;

    if (user == null) {
      isAuthorized = false;
    } else {
      if (disallowReadOnly && user.isReadOnly) isAuthorized = false;
      if (requireChurchAdmin && !user.isChurchAdmin) isAuthorized = false;
      if (requirePlatformAdmin && !user.isPlatformAdmin) isAuthorized = false;
      if (requireMember && !user.isMember) isAuthorized = false;

      if (allowedRoles != null &&
          allowedRoles!.isNotEmpty &&
          !allowedRoles!.contains(user.role)) {
        isAuthorized = false;
      }

      if (requiredPermission != null &&
          !user.hasPermission(requiredPermission!)) {
        isAuthorized = false;
      }

      if (anyPermissions != null &&
          anyPermissions!.isNotEmpty &&
          !anyPermissions!.any((p) => user.hasPermission(p))) {
        isAuthorized = false;
      }

      if (allPermissions != null &&
          allPermissions!.isNotEmpty &&
          !allPermissions!.every((p) => user.hasPermission(p))) {
        isAuthorized = false;
      }
    }

    return builder(context, isAuthorized, user);
  }
}
