import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../modelos/ad_models.dart';
import '../modelos/auth_permissions.dart';
import '../providers/ads_provider.dart';
import '../providers/user_provider.dart';
import 'ad_payment_screen.dart';
import 'ad_stats_screen.dart';
import 'create_ad_campaign_screen.dart';

/// Pantalla principal de administración de campañas publicitarias para administradores de iglesia.
/// Requiere estrictamente el permiso `manage_ads` (RBAC Odoo 19).
class AdminAdsScreen extends StatefulWidget {
  static const routeName = 'admin_ads_screen';

  const AdminAdsScreen({super.key});

  @override
  State<AdminAdsScreen> createState() => _AdminAdsScreenState();
}

class _AdminAdsScreenState extends State<AdminAdsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().currentUser;
      if (user != null && user.hasPermission(AppPermissions.manageAds)) {
        context.read<AdsProvider>().loadChurchAds(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userProvider = context.watch<UserProvider>();
    final hasManageAds = userProvider.hasPermission(AppPermissions.manageAds);

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    // 1. Blindaje estricto de seguridad: control de permiso `manage_ads`
    if (!hasManageAds) {
      return Scaffold(
        backgroundColor: blancoFondo,
        appBar: AppBar(
          title: Text(
            l10n?.anunciosYPublicidad ?? 'Publicidad y Anuncios',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: azulFondo,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.red.shade700,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.permisoRequeridoManageAds ??
                      'Se requiere el permiso de Administrador de Anuncios (manage_ads) para acceder a este módulo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final adsProvider = context.watch<AdsProvider>();
    final ads = adsProvider.churchAds;
    final isLoading = adsProvider.isAdminLoading;

    return Scaffold(
      backgroundColor: blancoFondo,
      appBar: AppBar(
        title: Text(
          l10n?.gestionCampanasPublicitarias ?? 'Gestión de Campañas',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: azulFondo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AdsProvider>().loadChurchAds(force: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: amarilloOro,
        foregroundColor: azulFondo,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          l10n?.nuevaCampana ?? 'Nueva Campaña',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final res = await Navigator.pushNamed(
            context,
            CreateAdCampaignScreen.routeName,
          );
          if (res == true && context.mounted) {
            context.read<AdsProvider>().loadChurchAds(force: true);
          }
        },
      ),
      body: Column(
        children: [
          // 2. Barra de Filtros por Estado
          _FilterChipsBar(
            selectedFilter: adsProvider.statusFilter,
            onFilterSelected: (status) {
              context.read<AdsProvider>().setStatusFilter(status);
            },
          ),

          // 3. Listado de Campañas o Estado Vacío
          Expanded(
            child: RefreshIndicator(
              color: azulFondo,
              onRefresh: () =>
                  context.read<AdsProvider>().loadChurchAds(force: true),
              child: isLoading && ads.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(azulFondo),
                      ),
                    )
                  : ads.isEmpty
                      ? _EmptyAdsView()
                      : ListView.separated(
                          padding: const EdgeInsetsDirectional.only(
                            start: 16,
                            end: 16,
                            top: 12,
                            bottom: 80,
                          ),
                          itemCount: ads.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final ad = ads[index];
                            return _AdminAdCard(ad: ad);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipsBar extends StatelessWidget {
  final AdStatus? selectedFilter;
  final ValueChanged<AdStatus?> onFilterSelected;

  const _FilterChipsBar({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);

    final filters = [
      (label: l10n?.filtroTodas ?? 'Todas', status: null),
      (label: l10n?.filtroActivas ?? 'Activas', status: AdStatus.active),
      (label: l10n?.filtroPorPagar ?? 'Por Pagar', status: AdStatus.toPay),
      (label: l10n?.filtroEnRevision ?? 'En Revisión', status: AdStatus.requested),
      (label: l10n?.filtroFinalizadas ?? 'Finalizadas', status: AdStatus.finished),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((f) {
            final isSelected = selectedFilter == f.status;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FilterChip(
                label: Text(f.label),
                selected: isSelected,
                selectedColor: azulFondo,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                backgroundColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? azulFondo : const Color(0xFFCBD5E1),
                  ),
                ),
                onSelected: (_) => onFilterSelected(f.status),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AdminAdCard extends StatelessWidget {
  final AdModel ad;

  const _AdminAdCard({required this.ad});

  void _showCancelDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.cancelarCampana ?? 'Cancelar Campaña'),
        content: Text(
          l10n?.confirmarCancelarCampana ??
              '¿Estás seguro de que deseas retirar esta solicitud de anuncio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancelar ?? 'Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AdsProvider>().cancelCampaign(ad.id);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Fila de Encabezado: Título + Badge de Estado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miniatura si existe
              if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ad.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 56,
                      height: 56,
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.image_not_supported_rounded, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.name,
                      style: const TextStyle(
                        color: azulFondo,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (ad.createdAt != null)
                      Text(
                        DateFormat.yMMMMd(locale).format(ad.createdAt!),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: ad.status),
            ],
          ),

          // 2. Banner de Motivo de Rechazo (si aplica)
          if (ad.isRejected && ad.rejectionReason != null && ad.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsetsDirectional.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n?.motivoRechazo ?? 'Motivo'}: ${ad.rejectionReason!}',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 3. Fila de Estadísticas Resumidas
          Row(
            children: [
              _MiniStat(
                icon: Icons.visibility_outlined,
                label: '${ad.totalImpressions} ${l10n?.impresiones ?? 'impr.'}',
              ),
              const SizedBox(width: 14),
              _MiniStat(
                icon: Icons.touch_app_outlined,
                label: '${ad.totalClicks} ${l10n?.clics ?? 'clics'}',
              ),
              const SizedBox(width: 14),
              _MiniStat(
                icon: Icons.pie_chart_outline_rounded,
                label: 'CTR: ${ad.ctrPercentage.toStringAsFixed(1)}%',
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // 4. Botones de Acción Contextuales
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Si está solicitada: opción de cancelar
              if (ad.isRequested)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                  onPressed: () => _showCancelDialog(context),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(l10n?.cancelarCampana ?? 'Cancelar'),
                ),

              // Si está lista para pagar: Botón destacado de Pago
              if (ad.canBePaid) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amarilloOro,
                    foregroundColor: azulFondo,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdPaymentScreen(ad: ad),
                      ),
                    );
                    if (context.mounted) {
                      context.read<AdsProvider>().loadChurchAds(force: true);
                    }
                  },
                  icon: const Icon(Icons.payment_rounded, size: 16),
                  label: Text(
                    l10n?.pagarCampana ?? 'Pagar Campaña',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              // Si está activa o finalizada: Botón de Estadísticas
              if (ad.isActive || ad.isFinished || ad.totalImpressions > 0) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: azulFondo,
                    side: const BorderSide(color: azulFondo),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdStatsScreen(ad: ad),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics_outlined, size: 16),
                  label: Text(
                    l10n?.verEstadisticas ?? 'Estadísticas',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AdStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case AdStatus.requested:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        label = l10n?.estadoSolicitada ?? 'En Revisión';
        break;
      case AdStatus.toPay:
        bgColor = const Color(0xFFFFFBEB);
        textColor = const Color(0xFFD97706);
        label = l10n?.estadoPorPagar ?? 'Por Pagar';
        break;
      case AdStatus.paymentReview:
        bgColor = const Color(0xFFE0E7FF);
        textColor = const Color(0xFF3730A3);
        label = l10n?.estadoComprobanteRevision ?? 'Comprobante en Revisión';
        break;
      case AdStatus.ready:
        bgColor = const Color(0xFFCCFBF1);
        textColor = const Color(0xFF0F766E);
        label = l10n?.estadoLista ?? 'Lista para Salir';
        break;
      case AdStatus.active:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        label = l10n?.estadoActiva ?? 'Activa';
        break;
      case AdStatus.paused:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        label = l10n?.estadoPausada ?? 'Pausada';
        break;
      case AdStatus.finished:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        label = l10n?.estadoFinalizada ?? 'Finalizada';
        break;
      case AdStatus.rejected:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFB91C1C);
        label = l10n?.estadoRechazada ?? 'Rechazada';
        break;
      case AdStatus.unknown:
        bgColor = const Color(0xFFF1F5F9);
        textColor = Colors.grey.shade600;
        label = 'Desconocido';
        break;
    }

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EmptyAdsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);

    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_outlined,
                color: azulFondo,
                size: 54,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n?.sinCampanas ?? 'No hay campañas registradas',
              style: const TextStyle(
                color: azulFondo,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.sinCampanasSubtitulo ??
                  'Crea tu primera campaña para llegar a más iglesias y miembros de la comunidad.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
