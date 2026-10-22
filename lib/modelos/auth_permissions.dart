import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Enumeración de roles del sistema ATRIO integrados con Odoo 19.
enum UserRole {
  user,
  member,
  churchAdmin,
  platformAdmin;

  /// Parsea la cadena retornada por el backend Odoo a [UserRole].
  static UserRole fromString(String? role) {
    switch (role?.toLowerCase().trim()) {
      case 'platform_admin':
        return UserRole.platformAdmin;
      case 'church_admin':
      case 'admin':
        return UserRole.churchAdmin;
      case 'member':
        return UserRole.member;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  /// Retorna la representación esperada por la API de Odoo.
  String toOdooString() {
    switch (this) {
      case UserRole.platformAdmin:
        return 'platform_admin';
      case UserRole.churchAdmin:
        return 'church_admin';
      case UserRole.member:
        return 'member';
      case UserRole.user:
        return 'user';
    }
  }

  /// Retorna el nombre traducido del rol mediante AppLocalizations.
  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case UserRole.platformAdmin:
        return l10n?.rolSuperAdmin ?? 'Super Administrador';
      case UserRole.churchAdmin:
        return l10n?.rolAdministradorIglesia ?? 'Administrador de Iglesia';
      case UserRole.member:
        return l10n?.rolMiembro ?? 'Miembro Activo';
      case UserRole.user:
        return l10n?.rolUsuario ?? 'Usuario';
    }
  }
}

/// Catálogo de permisos granulares provistos por Odoo 19 (/me y /auth/login)
/// según el documento oficial de especificación "Permisos por perfil en Atrio" (Pablo Oliveros).
class AppPermissions {
  // 1. Feligrés / Miembro (role: member)
  static const String viewContent = 'view_content';
  static const String registerEvents = 'register_events';
  static const String createOfferings = 'create_offerings';
  static const String createRequests = 'create_requests';
  static const String manageProfile = 'manage_profile';
  static const String shop = 'shop';
  static const String donate = 'donate';

  // 2. Administrador de Iglesia (role: church_admin - además de todos los del miembro)
  static const String managePosts = 'manage_posts';
  static const String manageEvents = 'manage_events';
  static const String manageAnnouncements = 'manage_announcements';
  static const String manageRequests = 'manage_requests';
  static const String viewStats = 'view_stats';
  static const String manageAds = 'manage_ads';
  static const String viewAdminNotifications = 'view_admin_notifications';
  // Retrocompatibilidad con audiencias
  static const String manageGroups = 'manage_groups';

  // 3. Super Admin de Plataforma (role: platform_admin, read_only: true)
  static const String viewAllChurches = 'view_all_churches';
  static const String viewAdminContent = 'view_admin_content';
  static const String readOnly = 'read_only';

  /// Conjunto canónico oficial de permisos API para rol Miembro
  static const Set<String> memberOfficialPermissions = {
    viewContent,
    registerEvents,
    createOfferings,
    createRequests,
    manageProfile,
    shop,
    donate,
  };

  /// Conjunto canónico de permisos API adicionales para el Administrador de Iglesia
  static const Set<String> churchAdminAdditionalPermissions = {
    managePosts,
    manageEvents,
    manageAnnouncements,
    manageRequests,
    viewStats,
    manageAds,
    viewAdminNotifications,
  };

  /// Conjunto canónico oficial de permisos API para el Super Admin
  static const Set<String> platformAdminOfficialPermissions = {
    viewAllChurches,
    viewContent,
    viewAdminContent,
    readOnly,
  };
}
