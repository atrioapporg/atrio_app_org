import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../modelos/ad_models.dart';
import '../providers/ads_provider.dart';

/// Pantalla para consultar el rendimiento estadístico de una campaña publicitaria en Odoo 19 ERP.
/// Endpoint: GET /admin/ads/{id}/stats
/// Muestra métricas de impresiones, clics, clics únicos, CTR y gráfico de evolución temporal.
class AdStatsScreen extends StatefulWidget {
  static const routeName = 'ad_stats_screen';
  final AdModel ad;

  const AdStatsScreen({super.key, required this.ad});

  @override
  State<AdStatsScreen> createState() => _AdStatsScreenState();
}

class _AdStatsScreenState extends State<AdStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdsProvider>().loadStats(widget.ad.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final adsProvider = context.watch<AdsProvider>();
    final stats = adsProvider.currentStats;
    final isLoading = adsProvider.isStatsLoading;

    const Color azulFondo = Color(0xFF072B4F);
    const Color blancoFondo = Color(0xFFFAF7F0);

    return Scaffold(
      backgroundColor: blancoFondo,
      appBar: AppBar(
        title: Text(
          l10n?.rendimientoCampana ?? 'Rendimiento de la Campaña',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: azulFondo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<AdsProvider>().loadStats(widget.ad.id),
          ),
        ],
      ),
      body: isLoading && stats == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(azulFondo),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Resumen y Estado de la Campaña
                  _CampaignSummaryHeader(ad: widget.ad),
                  const SizedBox(height: 16),

                  // 2. Tarjetas de Métricas Clave (Odoo 19: impresiones, clics, clics únicos, CTR)
                  _MetricsGrid(
                    ad: widget.ad,
                    stats: stats,
                  ),
                  const SizedBox(height: 18),

                  // 3. Gráfico de Evolución Temporal (series)
                  _TimeSeriesChartCard(
                    stats: stats,
                  ),
                  const SizedBox(height: 18),

                  // 4. Desglose adicional si Odoo 19 envía canales o iglesias
                  if (stats != null && stats.byChannel.isNotEmpty)
                    _BreakdownCard(
                      title: 'Desglose por Canal',
                      items: stats.byChannel,
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// =============================================================================
// SUB-WIDGETS DESACOPLADOS (CONSTRUCTORES CONST)
// =============================================================================

class _CampaignSummaryHeader extends StatelessWidget {
  final AdModel ad;

  const _CampaignSummaryHeader({required this.ad});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    const Color azulFondo = Color(0xFF072B4F);

    return Container(
      padding: const EdgeInsetsDirectional.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ad.name,
                  style: const TextStyle(
                    color: azulFondo,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _StatusBadge(status: ad.status, label: ad.statusLabel),
            ],
          ),
          if (ad.startDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat.yMMMMd(locale).format(ad.startDate!)} ${ad.endDate != null ? '· ${DateFormat.yMMMMd(locale).format(ad.endDate!)}' : ''}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AdStatus status;
  final String? label;

  const _StatusBadge({required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text = label ?? status.value;

    switch (status) {
      case AdStatus.active:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        text = label ?? 'Activa';
        break;
      case AdStatus.toPay:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        text = label ?? 'Por Pagar';
        break;
      case AdStatus.paymentReview:
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF4338CA);
        text = label ?? 'En Revisión de Pago';
        break;
      case AdStatus.ready:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        text = label ?? 'Lista';
        break;
      case AdStatus.finished:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        text = label ?? 'Finalizada';
        break;
      case AdStatus.rejected:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        text = label ?? 'Rechazada';
        break;
      case AdStatus.requested:
      default:
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF6B21A8);
        text = label ?? 'En Revisión';
        break;
    }

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final AdModel ad;
  final AdStatsModel? stats;

  const _MetricsGrid({required this.ad, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    const Color amarilloOro = Color(0xFFE5A023);

    final imp = stats?.impressions ?? ad.totalImpressions;
    final clk = stats?.clicks ?? ad.totalClicks;
    final uniqClk = stats?.uniqueClicks ?? 0;
    final ctrValue = stats?.ctr ?? ad.ctrPercentage;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: l10n?.impresiones ?? 'Impresiones',
                value: NumberFormat.decimalPattern(locale).format(imp),
                icon: Icons.visibility_rounded,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: l10n?.clics ?? 'Clics',
                value: NumberFormat.decimalPattern(locale).format(clk),
                icon: Icons.touch_app_rounded,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: l10n?.clicsUnicos ?? 'Clics Únicos',
                value: NumberFormat.decimalPattern(locale).format(uniqClk),
                icon: Icons.person_pin_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'CTR (Tasa)',
                value: '${ctrValue.toStringAsFixed(1)}%',
                icon: Icons.pie_chart_rounded,
                color: amarilloOro,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF072B4F),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSeriesChartCard extends StatelessWidget {
  final AdStatsModel? stats;

  const _TimeSeriesChartCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);

    return Container(
      padding: const EdgeInsetsDirectional.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.evolucionDiaria ?? 'Evolución Diaria',
                style: const TextStyle(
                  color: azulFondo,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _LegendDot(
                    color: const Color(0xFF2563EB),
                    label: l10n?.impresiones ?? 'Impresiones',
                  ),
                  const SizedBox(width: 12),
                  _LegendDot(
                    color: const Color(0xFF16A34A),
                    label: l10n?.clics ?? 'Clics',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (stats != null && stats!.timeSeries.isNotEmpty)
            _BarChartVisualizer(points: stats!.timeSeries)
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 44,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.sinEstadisticasDetalladas ??
                          'Las estadísticas detalladas se actualizarán conforme la campaña registre actividad en vivo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BarChartVisualizer extends StatelessWidget {
  final List<AdStatsPointModel> points;

  const _BarChartVisualizer({required this.points});

  @override
  Widget build(BuildContext context) {
    int maxImp = 1;
    for (final p in points) {
      if (p.impressions > maxImp) maxImp = p.impressions;
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: points.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final p = points[index];
          final impHeight = (p.impressions / maxImp) * 110.0;
          final clkHeight = (p.clicks / maxImp) * 110.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 14,
                    height: impHeight.clamp(4.0, 110.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 14,
                    height: clkHeight.clamp(2.0, 110.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p.dateLabel.length > 5
                    ? p.dateLabel.substring(p.dateLabel.length - 5)
                    : p.dateLabel,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final List<dynamic> items;

  const _BreakdownCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);

    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: azulFondo,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  it.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              )),
        ],
      ),
    );
  }
}
