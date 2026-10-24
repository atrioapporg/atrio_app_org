/// Define los estados de navegación principales de la aplicación ATRIO
/// basados en la respuesta del endpoint GET /me o el login en Odoo 19.
enum AppStage {
  /// Sin sesión / Invitado: puede explorar iglesias, tienda y donar sin cuenta.
  welcome,

  /// Usuario autenticado (role == 'user') que no pertenece a ninguna congregación ni tiene solicitud pendiente.
  /// Muestra la pantalla "Elegir": "Unirme a una iglesia" o "Registrar mi iglesia".
  chooseChurch,

  /// Usuario que envió una solicitud para unirse a una iglesia (membership_status == 'membership_pending').
  /// Pantalla de espera hasta que el administrador de la iglesia la apruebe.
  waitingApproval,

  /// Administrador cuya iglesia recién creada aún no ha sido activada por el equipo de ATRIO
  /// (role == 'church_admin' y church.has_active_subscription == false).
  churchPendingActivation,

  /// Miembro regular de una iglesia activa (role == 'member' y church.has_active_subscription == true).
  /// Si membership_status == 'change_pending', muestra el inicio normal con aviso de cambio pendiente.
  memberHome,

  /// Administrador de una iglesia activa (role == 'church_admin' y church.has_active_subscription == true).
  adminHome,

  /// Superadministrador global de la plataforma (role == 'platform_admin') en modo solo lectura.
  platformAdmin,
}

/// Resuelve de forma pura e inmutable la pantalla / estado que corresponde mostrar
/// a partir del payload devuelto por el servidor Odoo 19 (GET /me, login, etc.).
AppStage resolveStage(Map<String, dynamic>? me) {
  if (me == null || me.isEmpty) return AppStage.welcome;

  final role = me['role'] as String?;
  final status = (me['membership_status'] ?? me['member']?['status']) as String?;
  final church = me['church'] as Map<String, dynamic>?;
  final bool activeSubscription = church?['has_active_subscription'] == true;

  if (role == 'platform_admin') return AppStage.platformAdmin;
  if (status == 'membership_pending') return AppStage.waitingApproval;
  if (role == 'church_admin') {
    return activeSubscription ? AppStage.adminHome : AppStage.churchPendingActivation;
  }
  if ((role == 'member' || status == 'approved') && activeSubscription) {
    return AppStage.memberHome;
  }
  if (status == 'change_pending') {
    return AppStage.memberHome;
  }

  // role == 'user', o iglesia sin suscripción activa para un miembro regular
  return AppStage.chooseChurch;
}
