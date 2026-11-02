import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/admin_models.dart';
import 'package:atrio/providers/admin_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/screens/admin_requests_screen.dart';
import 'package:atrio/screens/admin_ads_screen.dart';
import 'package:atrio/screens/crear_evento_screen.dart';
import 'package:atrio/screens/crear_predica_screen.dart';
import 'package:atrio/screens/church_poster_preview_screen.dart';
import 'package:atrio/widgets/atrio_connectivity_alert.dart';

/// Pantalla Principal del Dashboard Pastoral Móvil para el Admin de Iglesia (Odoo 19).
/// Proporciona métricas consolidadas en tiempo real, accesos rápidos a gestión pastoral,
/// solicitudes pendientes por atender y notificaciones del buzón institucional.
class ChurchAdminDashboardScreen extends StatefulWidget {
  static const String routeName = '/church-admin-dashboard';

  const ChurchAdminDashboardScreen({super.key});

  @override
  State<ChurchAdminDashboardScreen> createState() =>
      _ChurchAdminDashboardScreenState();
}

class _ChurchAdminDashboardScreenState
    extends State<ChurchAdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() {
    final adminProv = context.read<AdminProvider>();
    adminProv.loadChurchStats();
    adminProv.loadChurchRequests(limit: 10);
    adminProv.loadAdminNotifications();
  }

  Future<void> _handleRefresh() async {
    final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: () => _handleRefresh(),
    );
    if (!hasInternet || !mounted) return;
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final iglesiaProv = context.watch<IglesiaProvider>();
    final iglesia = iglesiaProv.iglesiaActual;

    const Color azulFondo = Color(0xFF072B4F);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color amarilloOro = Color(0xFFE5A023);

    return Scaffold(
      backgroundColor: blancoFondo,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.panelPastoral ?? 'Panel Pastoral',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (iglesia?.nombre != null && iglesia!.nombre.isNotEmpty)
              Text(
                iglesia.nombre,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: azulFondo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<AdminProvider>(
            builder: (context, prov, _) {
              final unread = prov.unreadNotificationsCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded),
                    tooltip: l10n?.buzonAlertas ?? 'Buzón de Alertas',
                    onPressed: _mostrarBuzonNotificaciones,
                  ),
                  if (unread > 0)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        padding: const EdgeInsetsDirectional.all(4),
                        decoration: const BoxDecoration(
                          color: amarilloOro,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: azulFondo,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n?.refrescar ?? 'Refrescar',
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: amarilloOro,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Tarjeta de Bienvenida y Datos de la Iglesia
              _AdminHeaderCard(
                iglesiaNombre: iglesia?.nombre ?? 'Comunidad Atrio',
              ),
              const SizedBox(height: 16),

              // 2. Grilla de Indicadores Clave (KPIs)
              const _AdminKpiGrid(),
              const SizedBox(height: 24),

              // 3. Barra de Acciones Rápidas
              const _QuickActionsSection(),
              const SizedBox(height: 24),

              // 4. Sección de Solicitudes Pastorales Pendientes
              const _RecentRequestsSection(),
              const SizedBox(height: 24),

              // 5. Últimas Notificaciones del Buzón Institucional
              const _AdminNotificationsFeedSection(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarBuzonNotificaciones() async {
    final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: () => _mostrarBuzonNotificaciones(),
    );
    if (!hasInternet || !mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AdminNotificationsModal(),
    );
  }
}

/// Encabezado con bienvenida y estatus pastoral
class _AdminHeaderCard extends StatelessWidget {
  final String iglesiaNombre;

  const _AdminHeaderCard({required this.iglesiaNombre});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [azulFondo, Color(0xFF0F3E6C)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F072B4F),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge de Rol
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
                  l10n?.administradorPastoral ?? 'ADMINISTRADOR PASTORAL',
                  style: const TextStyle(
                    color: azulFondo,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Conexión activa Odoo 19
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Odoo 19 Live',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            iglesiaNombre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.bienvenidoAdmin ?? 'Gestión, cuidado pastoral y métricas en vivo de tu congregación',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Grilla de Indicadores Clave (KPIs en tiempo real)
class _AdminKpiGrid extends StatelessWidget {
  const _AdminKpiGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final adminProv = context.watch<AdminProvider>();
    final stats = adminProv.churchStats;
    final requests = adminProv.churchRequests;

    // Conteo de solicitudes nuevas
    final newRequestsCount = requests.where((r) => r.isNew).length;

    // Formateador de moneda
    final currencySymbol = stats?.currencySymbol ?? 'RD\$';
    final offeringsFormatted =
        '$currencySymbol ${NumberFormat('#,##0.00').format(stats?.offeringsTotal ?? 0.0)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n?.resumenMensual ?? 'Resumen del Mes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF072B4F),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.enTiempoReal ?? 'En tiempo real',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: l10n?.solicitudesNuevas ?? 'Nuevas Solicitudes',
                value: '$newRequestsCount',
                icon: Icons.mark_email_unread_rounded,
                accentColor: const Color(0xFFE5A023),
                onTap: () async {
                  final hasInternet =
                      await AtrioConnectivityAlert.checkAndNotify(
                        context,
                        onRetry: () => Navigator.pushNamed(
                          context,
                          AdminRequestsScreen.routeName,
                        ),
                      );
                  if (hasInternet && context.mounted) {
                    Navigator.pushNamed(context, AdminRequestsScreen.routeName);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: l10n?.feligresesActivos ?? 'Feligreses Activos',
                value: '${stats?.activeMembers ?? 0}',
                icon: Icons.people_alt_rounded,
                accentColor: const Color(0xFF0284C7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: l10n?.ofrendasRecaudadas ?? 'Ofrendas Recaudadas',
                value: offeringsFormatted,
                icon: Icons.volunteer_activism_rounded,
                accentColor: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: l10n?.eventosCelebrados ?? 'Eventos del Mes',
                value: '${stats?.heldEvents ?? 0}',
                icon: Icons.event_available_rounded,
                accentColor: const Color(0xFF9333EA),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsetsDirectional.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06072B4F),
              blurRadius: 10,
              offset: Offset(0, 4),
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
                  padding: const EdgeInsetsDirectional.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xFF94A3B8),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF072B4F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección de Acciones Rápidas Pastorales
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.accionesRapidas ?? 'Acciones Rápidas',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF072B4F),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _QuickActionCard(
                icon: Icons.inbox_rounded,
                label: l10n?.bandejaSolicitudes ?? 'Bandeja de Solicitudes',
                color: const Color(0xFF072B4F),
                onTap: () async {
                  final hasInternet =
                      await AtrioConnectivityAlert.checkAndNotify(
                        context,
                        onRetry: () => Navigator.pushNamed(
                          context,
                          AdminRequestsScreen.routeName,
                        ),
                      );
                  if (hasInternet && context.mounted) {
                    Navigator.pushNamed(context, AdminRequestsScreen.routeName);
                  }
                },
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.campaign_rounded,
                label: l10n?.crearAviso ?? 'Nuevo Aviso',
                color: const Color(0xFF0284C7),
                onTap: () async {
                  final hasInternet =
                      await AtrioConnectivityAlert.checkAndNotify(
                        context,
                        onRetry: () => Navigator.pushNamed(
                          context,
                          CrearPredicaScreen.routeName,
                        ),
                      );
                  if (hasInternet && context.mounted) {
                    Navigator.pushNamed(context, CrearPredicaScreen.routeName);
                  }
                },
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.event_available_rounded,
                label: l10n?.nuevoEvento ?? 'Nuevo Evento',
                color: const Color(0xFF9333EA),
                onTap: () async {
                  final hasInternet =
                      await AtrioConnectivityAlert.checkAndNotify(
                        context,
                        onRetry: () => Navigator.pushNamed(
                          context,
                          CrearEventoScreen.routeName,
                        ),
                      );
                  if (hasInternet && context.mounted) {
                    Navigator.pushNamed(context, CrearEventoScreen.routeName);
                  }
                },
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.ad_units_rounded,
                label: l10n?.anunciosCampanas ?? 'Publicidad y Anuncios',
                color: const Color(0xFFE5A023),
                onTap: () async {
                  final hasInternet =
                      await AtrioConnectivityAlert.checkAndNotify(
                        context,
                        onRetry: () => Navigator.pushNamed(
                          context,
                          AdminAdsScreen.routeName,
                        ),
                      );
                  if (hasInternet && context.mounted) {
                    Navigator.pushNamed(context, AdminAdsScreen.routeName);
                  }
                },
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.qr_code_2_rounded,
                label: l10n?.aficheQrOficial ?? 'Afiche y QR Oficial',
                color: const Color(0xFF0D9488),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    ChurchPosterPreviewScreen.routeName,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 130,
        padding: const EdgeInsetsDirectional.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsetsDirectional.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección de Solicitudes Recientes
class _RecentRequestsSection extends StatelessWidget {
  const _RecentRequestsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final adminProv = context.watch<AdminProvider>();
    final requests = adminProv.churchRequests;
    final recent = requests.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n?.solicitudesRecientes ??
                    'Solicitudes Pastorales Recientes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF072B4F),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                final hasInternet = await AtrioConnectivityAlert.checkAndNotify(
                  context,
                  onRetry: () => Navigator.pushNamed(
                    context,
                    AdminRequestsScreen.routeName,
                  ),
                );
                if (hasInternet && context.mounted) {
                  Navigator.pushNamed(context, AdminRequestsScreen.routeName);
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n?.verTodasSolicitudes ?? 'Ver todas',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF072B4F),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.inbox_rounded,
                  size: 40,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.sinSolicitudesRecientes ??
                      'No hay solicitudes pendientes en este momento',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: recent.map((item) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 10),
                child: _RecentRequestCard(request: item),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _RecentRequestCard extends StatelessWidget {
  final AdminChurchRequestModel request;

  const _RecentRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);

    return Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(8),
            decoration: BoxDecoration(
              color: request.isAnswered
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              request.isAnswered
                  ? Icons.check_circle_rounded
                  : Icons.favorite_rounded,
              size: 16,
              color: request.isAnswered
                  ? const Color(0xFF15803D)
                  : const Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        request.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: azulFondo,
                        ),
                      ),
                    ),
                    Text(
                      request.state.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: request.isAnswered
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${request.requesterName}: "${request.message}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: azulFondo,
            ),
            onPressed: () async {
              final hasInternet = await AtrioConnectivityAlert.checkAndNotify(
                context,
                onRetry: () =>
                    Navigator.pushNamed(context, AdminRequestsScreen.routeName),
              );
              if (hasInternet && context.mounted) {
                Navigator.pushNamed(context, AdminRequestsScreen.routeName);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Sección de Notificaciones Institucionales
class _AdminNotificationsFeedSection extends StatelessWidget {
  const _AdminNotificationsFeedSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final adminProv = context.watch<AdminProvider>();
    final notifs = adminProv.adminNotificationsList.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.notificacionesInstitucionales ??
              'Notificaciones Institucionales',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF072B4F),
          ),
        ),
        const SizedBox(height: 10),
        if (notifs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              l10n?.sinNotificacionesAdmin ??
                  'No tienes notificaciones en tu buzón',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          )
        else
          Column(
            children: notifs.map((n) {
              return Container(
                margin: const EdgeInsetsDirectional.only(bottom: 8),
                padding: const EdgeInsetsDirectional.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      size: 18,
                      color: Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n.message,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

/// Modal inferior para ver todo el buzón de notificaciones institucionales
class _AdminNotificationsModal extends StatelessWidget {
  const _AdminNotificationsModal();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final adminProv = context.watch<AdminProvider>();
    final notifs = adminProv.adminNotificationsList;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsetsDirectional.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.buzonAlertas ?? 'Buzón de Notificaciones',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF072B4F),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: notifs.isEmpty
                ? Center(
                    child: Text(
                      l10n?.sinNotificacionesAdmin ??
                          'No tienes notificaciones en tu buzón',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    itemCount: notifs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = notifs[index];
                      return Container(
                        padding: const EdgeInsetsDirectional.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF072B4F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                              ),
                            ),
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
