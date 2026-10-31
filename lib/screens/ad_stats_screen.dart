import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../modelos/ad_models.dart';
import '../providers/ads_provider.dart';

/// Pantalla / Vista modal para consultar el rendimiento estadístico de una campaña.
/// Muestra métricas de impresiones, clics, CTR y gráfico de barras de evolución diaria.
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
    final locale = Localizations.localeOf(context).toString();
    final adsProvider = context.watch<AdsProvider>();
    final stats = adsProvider.currentStats;
    final isLoading = adsProvider.isStatsLoading;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
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
            onPressed: () => context.read<AdsProvider>().loadStats(widget.ad.id),
          ),
        ],
      ),
      body: isLoading
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
                  // 1. Resumen de Campaña
                  Container(
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
                        Text(
                          widget.ad.name,
                          style: const TextStyle(
                            color: azulFondo,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.ad.startDate != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${DateFormat.yMMMMd(locale).format(widget.ad.startDate!)} ${widget.ad.endDate != null ? '· ${DateFormat.yMMMMd(locale).format(widget.ad.endDate!)}' : ''}',
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
                  ),

                  const SizedBox(height: 16),

                  // 2. Tarjetas de Métricas Clave (Impresiones, Clics, CTR)
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: l10n?.impresiones ?? 'Impresiones',
                          value: NumberFormat.decimalPattern(locale).format(
                            stats?.impressions ?? widget.ad.totalImpressions,
                          ),
                          icon: Icons.visibility_rounded,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          title: l10n?.clics ?? 'Clics',
                          value: NumberFormat.decimalPattern(locale).format(
                            stats?.clicks ?? widget.ad.totalClicks,
                          ),
                          icon: Icons.touch_app_rounded,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          title: 'CTR',
                          value: NumberFormat.percentPattern(locale).format(
                            ((stats?.ctr ?? widget.ad.ctrPercentage) / 100.0)
                                .clamp(0.0, 1.0),
                          ),
                          icon: Icons.pie_chart_rounded,
                          color: amarilloOro,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. Gráfico de Evolución Diaria
                  Container(
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
                                fontSize: 16,
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

                        // Renderizado de Barras Diarias o Estado Vacío
                        if (stats != null && stats.timeSeries.isNotEmpty)
                          _AdTimeSeriesChart(points: stats.timeSeries)
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.bar_chart_rounded,
                                    size: 48,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Las estadísticas detalladas por día se actualizarán conforme la campaña registre actividad en vivo.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF072B4F),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _AdTimeSeriesChart extends StatelessWidget {
  final List<AdStatsPointModel> points;

  const _AdTimeSeriesChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final maxImpressions = points.fold<int>(
      1,
      (prev, curr) => curr.impressions > prev ? curr.impressions : prev,
    );

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: points.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final pt = points[index];
          final heightFactor = (pt.impressions / maxImpressions).clamp(0.05, 1.0);
          final clicksHeightFactor = maxImpressions > 0
              ? (pt.clicks / maxImpressions).clamp(0.02, 1.0)
              : 0.02;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${pt.impressions}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 14,
                    height: 120 * heightFactor,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 14,
                    height: 120 * clicksHeightFactor,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat.Md(locale).format(pt.date),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
