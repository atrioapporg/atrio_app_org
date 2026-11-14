import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/admin_models.dart';
import 'package:atrio/providers/admin_provider.dart';
import 'package:atrio/modelos/iglesia_model.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/user_provider.dart';
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
  static const String _fontSizePrefsKey = 'admin_iglesia_base_font_size';
  static const double _defaultBaseFontSize = 14.0;
  static const double _minBaseFontSize = 14.0;
  static const double _maxBaseFontSize = 22.0;
  static const double _fontSizeStep = 1.0;

  double _baseFontSize = _defaultBaseFontSize;

  double get _fontDelta => _baseFontSize - _defaultBaseFontSize;

  @override
  void initState() {
    super.initState();
    _cargarAjustesVisuales();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _cargarAjustesVisuales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSize = prefs.getDouble(_fontSizePrefsKey);
      if (savedSize != null && mounted) {
        setState(() {
          _baseFontSize = savedSize.clamp(_minBaseFontSize, _maxBaseFontSize);
        });
      }
    } catch (_) {}
  }

  Future<void> _guardarAjustesVisuales(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizePrefsKey, size);
    } catch (_) {}
  }

  void _actualizarTamanoLetra(double newSize) {
    final double clamped = newSize.clamp(_minBaseFontSize, _maxBaseFontSize);
    if (clamped == _baseFontSize) return;
    setState(() => _baseFontSize = clamped);
    _guardarAjustesVisuales(clamped);
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
        toolbarHeight: kToolbarHeight + (_fontDelta * 2.5),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.panelPastoral ?? 'Panel Pastoral',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18 + _fontDelta,
              ),
            ),
            if (iglesia?.nombre != null && iglesia!.nombre.isNotEmpty)
              Text(
                iglesia.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12 + _fontDelta,
                  color: Colors.white70,
                ),
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
              return IconButton(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: l10n?.buzonAlertas ?? 'Buzón de Alertas',
                onPressed: _mostrarBuzonNotificaciones,
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      size: 22 + (_fontDelta * 0.5),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: amarilloOro,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          NumberFormat.compact(
                            locale: Localizations.localeOf(context).toString(),
                          ).format(unread),
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: 10 + _fontDelta,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
                iglesiaNombre:
                    iglesia?.nombre ?? l10n?.comunidadAtrio ?? 'Comunidad Atrio',
                baseFontSize: _baseFontSize,
                minBaseFontSize: _minBaseFontSize,
                maxBaseFontSize: _maxBaseFontSize,
                fontDelta: _fontDelta,
                onDecreaseFont: () =>
                    _actualizarTamanoLetra(_baseFontSize - _fontSizeStep),
                onIncreaseFont: () =>
                    _actualizarTamanoLetra(_baseFontSize + _fontSizeStep),
              ),
              const SizedBox(height: 16),

              // 1.5 Banner de Ciclo de Vida y Verificación Institucional (KYC)
              _ChurchKycStatusBanner(fontDelta: _fontDelta),
              const SizedBox(height: 16),

              // 2. Grilla de Indicadores Clave (KPIs)
              _AdminKpiGrid(fontDelta: _fontDelta),
              const SizedBox(height: 24),

              // 3. Barra de Acciones Rápidas
              _QuickActionsSection(fontDelta: _fontDelta),
              const SizedBox(height: 24),

              // 4. Sección de Solicitudes Pastorales Pendientes
              _RecentRequestsSection(fontDelta: _fontDelta),
              const SizedBox(height: 24),

              // 5. Últimas Notificaciones del Buzón Institucional
              _AdminNotificationsFeedSection(fontDelta: _fontDelta),
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
      builder: (ctx) => _AdminNotificationsModal(fontDelta: _fontDelta),
    );
  }
}

/// Encabezado con bienvenida y estatus pastoral
class _AdminHeaderCard extends StatelessWidget {
  final String iglesiaNombre;
  final double baseFontSize;
  final double minBaseFontSize;
  final double maxBaseFontSize;
  final double fontDelta;
  final VoidCallback onDecreaseFont;
  final VoidCallback onIncreaseFont;

  const _AdminHeaderCard({
    required this.iglesiaNombre,
    required this.baseFontSize,
    required this.minBaseFontSize,
    required this.maxBaseFontSize,
    required this.fontDelta,
    required this.onDecreaseFont,
    required this.onIncreaseFont,
  });

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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
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
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: 11 + fontDelta,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _DashboardFontSizeControlBar(
                baseFontSize: baseFontSize,
                minBaseFontSize: minBaseFontSize,
                maxBaseFontSize: maxBaseFontSize,
                onDecrease: onDecreaseFont,
                onIncrease: onIncreaseFont,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            iglesiaNombre,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20 + fontDelta,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.bienvenidoAdmin ??
                'Gestión, cuidado pastoral y métricas en vivo de tu congregación',
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: 13 + fontDelta,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardFontSizeControlBar extends StatelessWidget {
  final double baseFontSize;
  final double minBaseFontSize;
  final double maxBaseFontSize;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _DashboardFontSizeControlBar({
    required this.baseFontSize,
    required this.minBaseFontSize,
    required this.maxBaseFontSize,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool canDecrease = baseFontSize > minBaseFontSize;
    final bool canIncrease = baseFontSize < maxBaseFontSize;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            enabled: canDecrease,
            label: l10n.reducirTamanoLetra,
            child: Tooltip(
              message: l10n.reducirTamanoLetra,
              child: InkWell(
                borderRadius: const BorderRadiusDirectional.horizontal(
                  start: Radius.circular(14),
                ).resolve(Directionality.of(context)),
                onTap: canDecrease ? onDecrease : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: Center(
                    child: Text(
                      'A-',
                      style: TextStyle(
                        color: canDecrease
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.38),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.22),
          ),
          Semantics(
            button: true,
            enabled: canIncrease,
            label: l10n.aumentarTamanoLetra,
            child: Tooltip(
              message: l10n.aumentarTamanoLetra,
              child: InkWell(
                borderRadius: const BorderRadiusDirectional.horizontal(
                  end: Radius.circular(14),
                ).resolve(Directionality.of(context)),
                onTap: canIncrease ? onIncrease : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: Center(
                    child: Text(
                      'A+',
                      style: TextStyle(
                        color: canIncrease
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.38),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grilla de Indicadores Clave (KPIs en tiempo real)
class _AdminKpiGrid extends StatelessWidget {
  final double fontDelta;

  const _AdminKpiGrid({this.fontDelta = 0.0});

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
                style: TextStyle(
                  fontSize: 16 + fontDelta,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF072B4F),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.enTiempoReal ?? 'En tiempo real',
              style: TextStyle(
                fontSize: 12 + fontDelta,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KpiCard(
                  title: l10n?.solicitudesNuevas ?? 'Nuevas Solicitudes',
                  value: '$newRequestsCount',
                  icon: Icons.mark_email_unread_rounded,
                  accentColor: const Color(0xFFE5A023),
                  fontDelta: fontDelta,
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
                      Navigator.pushNamed(
                        context,
                        AdminRequestsScreen.routeName,
                      );
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
                  fontDelta: fontDelta,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KpiCard(
                  title: l10n?.ofrendasRecaudadas ?? 'Ofrendas Recaudadas',
                  value: offeringsFormatted,
                  icon: Icons.volunteer_activism_rounded,
                  accentColor: const Color(0xFF16A34A),
                  fontDelta: fontDelta,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  title: l10n?.eventosCelebrados ?? 'Eventos del Mes',
                  value: '${stats?.heldEvents ?? 0}',
                  icon: Icons.event_available_rounded,
                  accentColor: const Color(0xFF9333EA),
                  fontDelta: fontDelta,
                ),
              ),
            ],
          ),
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
  final double fontDelta;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.fontDelta = 0.0,
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 18 + fontDelta,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF072B4F),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11 + fontDelta,
                color: const Color(0xFF64748B),
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
  final double fontDelta;

  const _QuickActionsSection({this.fontDelta = 0.0});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.accionesRapidas ?? 'Acciones Rápidas',
          style: TextStyle(
            fontSize: 16 + fontDelta,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF072B4F),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuickActionCard(
                  icon: Icons.inbox_rounded,
                  label: l10n?.bandejaSolicitudes ?? 'Bandeja de Solicitudes',
                  color: const Color(0xFF072B4F),
                  fontDelta: fontDelta,
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
                      Navigator.pushNamed(
                        context,
                        AdminRequestsScreen.routeName,
                      );
                    }
                  },
                ),
                const SizedBox(width: 12),
                _QuickActionCard(
                  icon: Icons.campaign_rounded,
                  label: l10n?.crearAviso ?? 'Nuevo Aviso',
                  color: const Color(0xFF0284C7),
                  fontDelta: fontDelta,
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
                      Navigator.pushNamed(
                        context,
                        CrearPredicaScreen.routeName,
                      );
                    }
                  },
                ),
                const SizedBox(width: 12),
                _QuickActionCard(
                  icon: Icons.event_available_rounded,
                  label: l10n?.nuevoEvento ?? 'Nuevo Evento',
                  color: const Color(0xFF9333EA),
                  fontDelta: fontDelta,
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
                  fontDelta: fontDelta,
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
                  fontDelta: fontDelta,
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
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double fontDelta;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.fontDelta = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 130 + (fontDelta * 8),
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12 + fontDelta,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
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
  final double fontDelta;

  const _RecentRequestsSection({this.fontDelta = 0.0});

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
                style: TextStyle(
                  fontSize: 16 + fontDelta,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF072B4F),
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
                minimumSize: const Size(48, 48),
              ),
              child: Text(
                l10n?.verTodasSolicitudes ?? 'Ver todas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12 + fontDelta,
                  color: const Color(0xFF072B4F),
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
                  style: TextStyle(
                    fontSize: 13 + fontDelta,
                    color: const Color(0xFF64748B),
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
                child: _RecentRequestCard(
                  request: item,
                  fontDelta: fontDelta,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _RecentRequestCard extends StatelessWidget {
  final AdminChurchRequestModel request;
  final double fontDelta;

  const _RecentRequestCard({required this.request, this.fontDelta = 0.0});

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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14 + fontDelta,
                          fontWeight: FontWeight.bold,
                          color: azulFondo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      request.state.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10 + fontDelta,
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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12 + fontDelta,
                    color: const Color(0xFF475569),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
  final double fontDelta;

  const _AdminNotificationsFeedSection({this.fontDelta = 0.0});

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
          style: TextStyle(
            fontSize: 16 + fontDelta,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF072B4F),
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
              style: TextStyle(
                fontSize: 12 + fontDelta,
                color: const Color(0xFF64748B),
              ),
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
                            style: TextStyle(
                              fontSize: 13 + fontDelta,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n.message,
                            style: TextStyle(
                              fontSize: 11 + fontDelta,
                              color: const Color(0xFF475569),
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
  final double fontDelta;

  const _AdminNotificationsModal({this.fontDelta = 0.0});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final adminProv = context.watch<AdminProvider>();
    final notifs = adminProv.adminNotificationsList;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
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
            style: TextStyle(
              fontSize: 18 + fontDelta,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF072B4F),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: notifs.isEmpty
                ? Center(
                    child: Text(
                      l10n?.sinNotificacionesAdmin ??
                          'No tienes notificaciones en tu buzón',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14 + fontDelta,
                        color: const Color(0xFF64748B),
                      ),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13 + fontDelta,
                                color: const Color(0xFF072B4F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              style: TextStyle(
                                fontSize: 12 + fontDelta,
                                color: const Color(0xFF334155),
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


/// Banner institucional de estado KYC en el Dashboard Pastoral Móvil.
/// Muestra en tiempo real el ciclo de vida legal de la congregación (`draft`, `pending_kyc`, `approved`, `suspended`)
/// conforme a los requisitos de organizaciones sin fines de lucro (RD Ley 122-05 / HN Personería Jurídica y RTN).
class _ChurchKycStatusBanner extends StatelessWidget {
  final double fontDelta;

  const _ChurchKycStatusBanner({this.fontDelta = 0.0});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final adminStats = context.watch<AdminProvider>().churchStats;
    final userProv = context.watch<UserProvider>();
    final iglesia = context.watch<IglesiaProvider>().iglesiaActual;

    final ChurchKycStatus status = adminStats != null
        ? ChurchKycStatus.fromString(
            adminStats.kycStatus,
            fallbackVerified: userProv.isChurchKycApproved,
          )
        : (iglesia?.kycStatus ?? userProv.churchKycStatus);

    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final IconData icon;
    final String title;
    final String description;

    switch (status) {
      case ChurchKycStatus.draft:
        bgColor = const Color(0xFFFFF8E1);
        borderColor = const Color(0xFFE5A023);
        iconColor = const Color(0xFFB45309);
        icon = Icons.pending_actions_rounded;
        title = l10n?.kycStatusDraftTitle ??
            'Verificación Institucional Pendiente de Inicio (Borrador)';
        description = l10n?.kycStatusDraftDesc ??
            'La recaudación de ofrendas se encuentra oculta en la aplicación.';
        break;
      case ChurchKycStatus.pendingKyc:
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF3B82F6);
        iconColor = const Color(0xFF1D4ED8);
        icon = Icons.fact_check_outlined;
        title = l10n?.kycStatusPendingTitle ??
            'Validación en curso (KYC Institucional)';
        description = l10n?.kycStatusPendingDesc ??
            'El equipo legal de ATRIO está verificando la documentación legal.';
        break;
      case ChurchKycStatus.approved:
        bgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF10B981);
        iconColor = const Color(0xFF047857);
        icon = Icons.verified_user_rounded;
        title = l10n?.kycStatusApprovedTitle ??
            'Congregación Verificada (KYC Aprobado)';
        description = l10n?.kycStatusApprovedDesc ??
            'Documentación legal e institucional validada. Recepción de ofrendas activa.';
        break;
      case ChurchKycStatus.suspended:
        bgColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFEF4444);
        iconColor = const Color(0xFFB91C1C);
        icon = Icons.gpp_bad_rounded;
        title = l10n?.kycStatusSuspendedTitle ??
            'Recaudación Suspendida por Auditoría Legal';
        description = l10n?.kycStatusSuspendedDesc ??
            'La recepción de ofrendas ha sido desactivada temporalmente.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(8),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5 + fontDelta,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: const Color(0xFF334155),
                    fontSize: 12 + fontDelta,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
