import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../modelos/auth_permissions.dart';
import '../modelos/iglesia_model.dart';
import '../providers/admin_provider.dart';
import '../providers/iglesia_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/atrio_connectivity_alert.dart';
import '../widgets/permission_guard.dart';
import 'admin_ads_screen.dart';
import 'admin_requests_screen.dart';
import 'church_admin_dashboard_screen.dart';
import 'church_poster_preview_screen.dart';
import 'crear_evento_screen.dart';
import 'crear_predica_screen.dart';
import 'perfil_screen.dart';

/// Centro de Mando Pastoral independiente para usuarios con rol `church_admin`.
/// Desacoplado de [PerfilScreen] para ofrecer una jerarquía clara entre
/// pantalla Padre (triage operativo y directorio de gestión) y pantallas Hijas
/// (Panel Pastoral, Bandeja de Solicitudes, Avisos, Audiencias y Publicidad).
class AdministradorIglesiaScreen extends StatefulWidget {
  static const routeName = 'AdministradorIglesiaScreen';

  const AdministradorIglesiaScreen({super.key});

  @override
  State<AdministradorIglesiaScreen> createState() =>
      _AdministradorIglesiaScreenState();
}

class _AdministradorIglesiaScreenState
    extends State<AdministradorIglesiaScreen> {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final adminProv = context.read<AdminProvider>();
    adminProv.loadChurchStats();
    adminProv.loadChurchRequests(limit: 10);
    adminProv.loadAdminNotifications();
    adminProv.loadAnnouncements();
    adminProv.loadGroups();
  }

  Future<void> _handleRefresh() async {
    final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: _handleRefresh,
    );
    if (!hasInternet || !mounted) return;
    _loadInitialData();
  }

  Future<void> _navigateWithConnectivity(String routeName) async {
    final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: () => _navigateWithConnectivity(routeName),
    );
    if (!hasInternet || !mounted) return;
    Navigator.pushNamed(context, routeName);
  }

  void _openAnnouncementsSheet(BuildContext context) {
    final adminProv = context.read<AdminProvider>();
    adminProv.loadAnnouncements();
    adminProv.loadGroups();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AdminAnnouncementsSheet(),
    );
  }

  void _openGroupsSheet(BuildContext context) {
    context.read<AdminProvider>().loadGroups();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AdminGroupsSheet(),
    );
  }

  Future<void> _openInboxNotifications(BuildContext context) async {
    final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: () => _openInboxNotifications(context),
    );
    if (!hasInternet || !context.mounted) return;
    context.read<AdminProvider>().loadAdminNotifications();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AdminInboxNotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final padding = MediaQuery.paddingOf(context);
    final usableHeight = size.height - padding.top - padding.bottom;

    final userProv = context.watch<UserProvider>();
    final iglesiaProv = context.watch<IglesiaProvider>();
    final adminProv = context.watch<AdminProvider>();

    final String currentChurch = iglesiaProv.iglesiaActual?.nombre.trim() ?? '';
    final String userChurch = userProv.currentUser?.iglesiaActual.trim() ?? '';
    final String churchName = currentChurch.isNotEmpty
        ? currentChurch
        : (userChurch.isNotEmpty ? userChurch : l10n.comunidadAtrio);

    final String userName = userProv.currentUser?.nombre.trim() ?? '';
    final String initials = _computeInitials(userName);

    final int pendingRequestsCount = adminProv.churchRequests
        .where((r) => r.isNew)
        .length;
    final int activeAnnouncementsCount = adminProv.announcements.length;
    final int activeGroupsCount = adminProv.groups.length;

    return ColoredBox(
      color: blancoFondo,
      child: RefreshIndicator(
        color: amarilloOro,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _PastoralHeader(
                churchName: churchName,
                userInitials: initials,
                unreadNotifications: adminProv.unreadNotificationsCount,
                kycStatus: iglesiaProv.iglesiaActual?.kycStatus ??
                    userProv.churchKycStatus,
                onOpenProfile: () {
                  Navigator.pushNamed(context, PerfilScreen.routeName);
                },
                onOpenInbox: () => _openInboxNotifications(context),
              ),
            ),
            SliverPadding(
              padding: EdgeInsetsDirectional.fromSTEB(
                screenWidth * 0.05,
                usableHeight * 0.022,
                screenWidth * 0.05,
                usableHeight * 0.04,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Cinta de Triage Operativo ("Pulso de Atención Hoy")
                  _SectionTitle(title: l10n.pulsoDeAtencion),
                  SizedBox(height: usableHeight * 0.012),
                  _AttentionPulseStrip(
                    pendingRequestsCount: pendingRequestsCount,
                    announcementsCount: activeAnnouncementsCount,
                    groupsCount: activeGroupsCount,
                    onTapRequests: () => _navigateWithConnectivity(
                      AdminRequestsScreen.routeName,
                    ),
                    onTapAnnouncements: () => _openAnnouncementsSheet(context),
                    onTapGroups: () => _openGroupsSheet(context),
                  ),
                  SizedBox(height: usableHeight * 0.028),

                  // 2. Bloque A: Cuidado Pastoral y Analítica
                  _SectionTitle(title: l10n.cuidadoPastoral),
                  SizedBox(height: usableHeight * 0.012),
                  _ModuleCardGroup(
                    items: [
                      _ModuleItemData(
                        icon: Icons.dashboard_customize_rounded,
                        accentColor: azulFondo,
                        title: l10n.panelPastoral,
                        subtitle: l10n.subtituloPanelPastoral,
                        onTap: () => _navigateWithConnectivity(
                          ChurchAdminDashboardScreen.routeName,
                        ),
                      ),
                      _ModuleItemData(
                        icon: Icons.inbox_rounded,
                        accentColor: amarilloOro,
                        title: l10n.bandejaSolicitudes,
                        subtitle: l10n.perfilSubtituloBandejaSolicitudes,
                        badgeCount: pendingRequestsCount,
                        onTap: () => _navigateWithConnectivity(
                          AdminRequestsScreen.routeName,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.026),

                  // 3. Bloque B: Comunicación y Membresía
                  _SectionTitle(title: l10n.comunicacionMembresia),
                  SizedBox(height: usableHeight * 0.012),
                  _ModuleCardGroup(
                    items: [
                      _ModuleItemData(
                        icon: Icons.campaign_rounded,
                        accentColor: const Color(0xFF0284C7),
                        title: l10n.gestionAvisos,
                        subtitle: l10n.perfilSubtituloAvisos,
                        onTap: () => _openAnnouncementsSheet(context),
                      ),
                      _ModuleItemData(
                        icon: Icons.groups_rounded,
                        accentColor: const Color(0xFF0D9488),
                        title: l10n.gestionGrupos,
                        subtitle: l10n.perfilSubtituloGrupos,
                        onTap: () => _openGroupsSheet(context),
                      ),
                    ],
                  ),

                  // 4. Bloque C: Difusión y Campañas (RBAC manageAds)
                  PermissionGuard(
                    requiredPermission: AppPermissions.manageAds,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: usableHeight * 0.026),
                        _SectionTitle(title: l10n.difusionCampanas),
                        SizedBox(height: usableHeight * 0.012),
                        _ModuleCardGroup(
                          items: [
                            _ModuleItemData(
                              icon: Icons.ad_units_rounded,
                              accentColor: const Color(0xFF9333EA),
                              title: l10n.anunciosYPublicidad,
                              subtitle: l10n.subtituloGestionCampanas,
                              onTap: () => _navigateWithConnectivity(
                                AdminAdsScreen.routeName,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: usableHeight * 0.026),

                  // 5. Herramientas Operativas Rápidas
                  _SectionTitle(title: l10n.herramientasRapidas),
                  SizedBox(height: usableHeight * 0.012),
                  _QuickToolsRow(
                    onTapNewEvent: () =>
                        _navigateWithConnectivity(CrearEventoScreen.routeName),
                    onTapNewSermon: () =>
                        _navigateWithConnectivity(CrearPredicaScreen.routeName),
                    onTapPosterQr: () {
                      Navigator.pushNamed(
                        context,
                        ChurchPosterPreviewScreen.routeName,
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _computeInitials(String name) {
    if (name.isEmpty) return 'P';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

// =============================================================================
// HEADER PASTORAL CON ACCESO DUAL A PERFIL PERSONAL
// =============================================================================

class _PastoralHeader extends StatelessWidget {
  final String churchName;
  final String userInitials;
  final int unreadNotifications;
  final ChurchKycStatus kycStatus;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenInbox;

  const _PastoralHeader({
    required this.churchName,
    required this.userInitials,
    required this.unreadNotifications,
    required this.kycStatus,
    required this.onOpenProfile,
    required this.onOpenInbox,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final usableHeight = size.height - MediaQuery.paddingOf(context).top;
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.fromSTEB(
        screenWidth * 0.05,
        usableHeight * 0.018,
        screenWidth * 0.05,
        usableHeight * 0.024,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [azulFondo, Color(0xFF0F3E6C)],
        ),
        borderRadius: BorderRadiusDirectional.only(
          bottomStart: Radius.circular(screenWidth * 0.06),
          bottomEnd: Radius.circular(screenWidth * 0.06),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            top: -10,
            end: -10,
            child: Icon(
              Icons.church_rounded,
              size: screenWidth * 0.34,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Badge LÍDER + Campana + Chip "Mi perfil"
              Row(
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: amarilloOro,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.perfilBadgeLider,
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: (screenWidth * 0.028).clamp(10.0, 12.0),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _InboxBellButton(
                    unreadCount: unreadNotifications,
                    onTap: onOpenInbox,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  _ProfileAccessChip(
                    initials: userInitials,
                    label: l10n.miPerfil,
                    onTap: onOpenProfile,
                  ),
                ],
              ),
              SizedBox(height: usableHeight * 0.016),
              Text(
                l10n.administracionPastoral,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: (screenWidth * 0.032).clamp(12.0, 14.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                churchName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (screenWidth * 0.052).clamp(18.0, 24.0),
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: usableHeight * 0.012),
              _CompactStatusPill(kycStatus: kycStatus),
            ],
          ),
        ],
      ),
    );
  }
}

class _InboxBellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _InboxBellButton({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Tooltip(
          message: l10n.buzonAlertas,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                if (unreadCount > 0)
                  PositionedDirectional(
                    top: -4,
                    end: -4,
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: amarilloOro,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        NumberFormat.compact(
                          locale: Localizations.localeOf(context).toString(),
                        ).format(unreadCount),
                        style: const TextStyle(
                          color: azulFondo,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAccessChip extends StatelessWidget {
  final String initials;
  final String label;
  final VoidCallback onTap;

  const _ProfileAccessChip({
    required this.initials,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(5, 4, 12, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: amarilloOro,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: azulFondo,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactStatusPill extends StatelessWidget {
  final ChurchKycStatus kycStatus;

  const _CompactStatusPill({required this.kycStatus});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (Color dotColor, String label) = switch (kycStatus) {
      ChurchKycStatus.approved => (
        const Color(0xFF4ADE80),
        l10n.perfilIglesiaAprobada,
      ),
      ChurchKycStatus.pendingKyc => (
        const Color(0xFF60A5FA),
        l10n.perfilBadgeEnRevision,
      ),
      ChurchKycStatus.suspended => (
        const Color(0xFFF87171),
        l10n.kycStatusSuspendedTitle,
      ),
      ChurchKycStatus.draft => (
        const Color(0xFFFBBF24),
        l10n.perfilPendienteAprobacion,
      ),
    };

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CINTA DE TRIAGE OPERATIVO ("PULSO DE ATENCIÓN HOY")
// =============================================================================

class _AttentionPulseStrip extends StatelessWidget {
  final int pendingRequestsCount;
  final int announcementsCount;
  final int groupsCount;
  final VoidCallback onTapRequests;
  final VoidCallback onTapAnnouncements;
  final VoidCallback onTapGroups;

  const _AttentionPulseStrip({
    required this.pendingRequestsCount,
    required this.announcementsCount,
    required this.groupsCount,
    required this.onTapRequests,
    required this.onTapAnnouncements,
    required this.onTapGroups,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.decimalPattern(locale);

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth * 0.025;
        return Row(
          children: [
            Expanded(
              child: _PulseCounterTile(
                value: formatter.format(pendingRequestsCount),
                label: l10n.porAtender,
                icon: Icons.mark_email_unread_rounded,
                accentColor: pendingRequestsCount > 0
                    ? const Color(0xFFE5A023)
                    : const Color(0xFF072B4F),
                highlight: pendingRequestsCount > 0,
                onTap: onTapRequests,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PulseCounterTile(
                value: formatter.format(announcementsCount),
                label: l10n.avisosActivos,
                icon: Icons.campaign_rounded,
                accentColor: const Color(0xFF0284C7),
                onTap: onTapAnnouncements,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PulseCounterTile(
                value: formatter.format(groupsCount),
                label: l10n.gruposActivos,
                icon: Icons.groups_rounded,
                accentColor: const Color(0xFF0D9488),
                onTap: onTapGroups,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PulseCounterTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool highlight;
  final VoidCallback onTap;

  const _PulseCounterTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight
                  ? accentColor.withValues(alpha: 0.6)
                  : const Color(0xFFE2E8F0),
              width: highlight ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06072B4F),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: 17),
                  ),
                  if (highlight)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: azulFondo,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DIRECTORIO DE MÓDULOS Y TARJETAS
// =============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF072B4F),
          fontSize: (screenWidth * 0.042).clamp(15.0, 18.0),
          fontWeight: FontWeight.bold,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class _ModuleItemData {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final int badgeCount;
  final VoidCallback onTap;

  const _ModuleItemData({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });
}

class _ModuleCardGroup extends StatelessWidget {
  final List<_ModuleItemData> items;

  const _ModuleCardGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06072B4F),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isFirst = index == 0;
          final isLast = index == items.length - 1;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.vertical(
                    top: isFirst ? const Radius.circular(18) : Radius.zero,
                    bottom: isLast ? const Radius.circular(18) : Radius.zero,
                  ),
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsetsDirectional.all(10),
                          decoration: BoxDecoration(
                            color: item.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Color(0xFF072B4F),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.badgeCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5A023),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              NumberFormat.decimalPattern(
                                Localizations.localeOf(context).toString(),
                              ).format(item.badgeCount),
                              style: const TextStyle(
                                color: Color(0xFF072B4F),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 62,
                  endIndent: 16,
                  color: Color(0xFFF1F5F9),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// =============================================================================
// BARRA DE HERRAMIENTAS RÁPIDAS
// =============================================================================

class _QuickToolsRow extends StatelessWidget {
  final VoidCallback onTapNewEvent;
  final VoidCallback onTapNewSermon;
  final VoidCallback onTapPosterQr;

  const _QuickToolsRow({
    required this.onTapNewEvent,
    required this.onTapNewSermon,
    required this.onTapPosterQr,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth * 0.025;
        return Row(
          children: [
            Expanded(
              child: _QuickToolTile(
                icon: Icons.event_available_rounded,
                label: l10n.nuevoEvento,
                color: const Color(0xFF9333EA),
                onTap: onTapNewEvent,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _QuickToolTile(
                icon: Icons.record_voice_over_rounded,
                label: l10n.nuevaPredica,
                color: const Color(0xFF0284C7),
                onTap: onTapNewSermon,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _QuickToolTile(
                icon: Icons.qr_code_2_rounded,
                label: l10n.aficheQrOficial,
                color: const Color(0xFF0D9488),
                onTap: onTapPosterQr,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickToolTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 10,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF072B4F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MODALES DESACOPLADOS: AVISOS, GRUPOS Y BUZÓN INSTITUCIONAL
// =============================================================================

class _AdminAnnouncementsSheet extends StatelessWidget {
  const _AdminAnnouncementsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final usableHeight = size.height - MediaQuery.paddingOf(context).top;
    final userProvider = context.watch<UserProvider>();

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    return Container(
      constraints: BoxConstraints(maxHeight: usableHeight * 0.85),
      decoration: BoxDecoration(
        color: blancoFondo,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: usableHeight * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: screenWidth * 0.12,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: usableHeight * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.gestionAvisos,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: (screenWidth * 0.046).clamp(16.0, 20.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (userProvider.canWrite)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amarilloOro,
                    foregroundColor: azulFondo,
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: usableHeight * 0.008,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const _AdminCreateAnnouncementSheet(),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    l10n.publicarAviso,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          SizedBox(height: usableHeight * 0.015),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, prov, _) {
                if (prov.isLoading && prov.announcements.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: amarilloOro),
                  );
                }
                if (prov.announcements.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.sinAvisosActivos,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: (screenWidth * 0.036).clamp(13.0, 15.0),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: prov.announcements.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: usableHeight * 0.012),
                  itemBuilder: (context, index) {
                    final a = prov.announcements[index];
                    return Container(
                      padding: EdgeInsetsDirectional.all(screenWidth * 0.035),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEFEFEF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (a.isPinned)
                                const Padding(
                                  padding: EdgeInsetsDirectional.only(end: 6),
                                  child: Icon(
                                    Icons.push_pin_rounded,
                                    size: 16,
                                    color: amarilloOro,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  a.title,
                                  style: const TextStyle(
                                    color: azulFondo,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (userProvider.canWrite)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => prov.deleteAnnouncement(a.id),
                                ),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.006),
                          Text(
                            a.plainContent,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCreateAnnouncementSheet extends StatefulWidget {
  const _AdminCreateAnnouncementSheet();

  @override
  State<_AdminCreateAnnouncementSheet> createState() =>
      _AdminCreateAnnouncementSheetState();
}

class _AdminCreateAnnouncementSheetState
    extends State<_AdminCreateAnnouncementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _pinned = false;
  int? _selectedGroupId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context)!;
    final adminProv = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final ok = await adminProv.createAnnouncement(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        targetGroupIds: _selectedGroupId != null ? [_selectedGroupId!] : null,
        pinned: _pinned,
      );
      if (!mounted) return;
      if (ok) {
        nav.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.avisoPublicadoExito),
            backgroundColor: const Color(0xFF072B4F),
          ),
        );
      } else {
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(adminProv.errorMessage ?? l10n.errorPublicarAviso),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.errorPublicarAviso),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final usableHeight = size.height - MediaQuery.paddingOf(context).top;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final adminProv = context.watch<AdminProvider>();

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    return PopScope(
      canPop: !_isSubmitting,
      child: Container(
        constraints: BoxConstraints(maxHeight: usableHeight * 0.92),
        decoration: BoxDecoration(
          color: blancoFondo,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(screenWidth * 0.06),
          ),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.only(bottom: keyboardHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 12, bottom: 6),
                child: Center(
                  child: Container(
                    width: screenWidth * 0.12,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.all(10),
                      decoration: BoxDecoration(
                        color: amarilloOro.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: azulFondo,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.publicarAviso,
                            style: const TextStyle(
                              color: azulFondo,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.perfilSubtituloAvisos,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: l10n.cancelar,
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    screenWidth * 0.05,
                    usableHeight * 0.02,
                    screenWidth * 0.05,
                    usableHeight * 0.025,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tituloAviso,
                          style: const TextStyle(
                            color: azulFondo,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleCtrl,
                          enabled: !_isSubmitting,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(
                              Icons.title_rounded,
                              color: azulFondo,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.campoRequerido
                              : null,
                        ),
                        SizedBox(height: usableHeight * 0.018),
                        Text(
                          l10n.contenidoAviso,
                          style: const TextStyle(
                            color: azulFondo,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _contentCtrl,
                          enabled: !_isSubmitting,
                          maxLines: 4,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.campoRequerido
                              : null,
                        ),
                        SizedBox(height: usableHeight * 0.018),
                        Text(
                          l10n.seleccionarAudiencia,
                          style: const TextStyle(
                            color: azulFondo,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int?>(
                          initialValue: _selectedGroupId,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(
                              Icons.groups_rounded,
                              color: azulFondo,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(l10n.todasLasAudiencias),
                            ),
                            ...adminProv.groups.map(
                              (g) => DropdownMenuItem<int?>(
                                value: g.id,
                                child: Text('${g.name} (${g.memberCount})'),
                              ),
                            ),
                          ],
                          onChanged: _isSubmitting
                              ? null
                              : (val) => setState(() => _selectedGroupId = val),
                        ),
                        SizedBox(height: usableHeight * 0.016),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _pinned
                                  ? amarilloOro.withValues(alpha: 0.6)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              l10n.fijarAviso,
                              style: const TextStyle(
                                color: azulFondo,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                            value: _pinned,
                            activeThumbColor: amarilloOro,
                            onChanged: _isSubmitting
                                ? null
                                : (val) => setState(() => _pinned = val),
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.024),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: amarilloOro,
                              foregroundColor: azulFondo,
                              padding: const EdgeInsetsDirectional.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: azulFondo,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            label: Text(
                              l10n.publicar,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminGroupsSheet extends StatelessWidget {
  const _AdminGroupsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final usableHeight = size.height - MediaQuery.paddingOf(context).top;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    return Container(
      constraints: BoxConstraints(maxHeight: usableHeight * 0.65),
      decoration: BoxDecoration(
        color: blancoFondo,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: usableHeight * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: screenWidth * 0.12,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: usableHeight * 0.02),
          Text(
            l10n.gestionGrupos,
            style: TextStyle(
              color: azulFondo,
              fontSize: (screenWidth * 0.046).clamp(16.0, 20.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: usableHeight * 0.015),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, prov, _) {
                if (prov.isLoading && prov.groups.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: amarilloOro),
                  );
                }
                if (prov.groups.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.sinGruposConfigurados,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: prov.groups.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final g = prov.groups[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: azulFondo.withValues(alpha: 0.1),
                        child: const Icon(Icons.group, color: azulFondo),
                      ),
                      title: Text(
                        g.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        g.description.isNotEmpty
                            ? g.description
                            : l10n.miembrosCount(g.memberCount),
                      ),
                      trailing: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: amarilloOro.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          NumberFormat.decimalPattern(
                            Localizations.localeOf(context).toString(),
                          ).format(g.memberCount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9E6500),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminInboxNotificationsSheet extends StatelessWidget {
  const _AdminInboxNotificationsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final usableHeight = size.height - MediaQuery.paddingOf(context).top;
    final adminProv = context.watch<AdminProvider>();
    final items = adminProv.adminNotificationsList;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    return Container(
      constraints: BoxConstraints(maxHeight: usableHeight * 0.72),
      decoration: const BoxDecoration(
        color: blancoFondo,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: size.width * 0.12,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.buzonAlertas,
                  style: const TextStyle(
                    color: azulFondo,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      l10n.sinNotificacionesAdmin,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsetsDirectional.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final n = items[index];
                      return Container(
                        padding: const EdgeInsetsDirectional.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: n.isRead
                                ? const Color(0xFFE2E8F0)
                                : amarilloOro.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: const TextStyle(
                                color: azulFondo,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (n.message.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                n.message,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

