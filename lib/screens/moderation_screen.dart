import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../modelos/moderation_models.dart';
import '../providers/moderation_provider.dart';
import '../widgets/permission_guard.dart';
import 'moderation_words_screen.dart';

/// Centro de Moderación de Plataforma para el Super Admin (`role: platform_admin`).
/// Audita publicaciones, eventos y notificaciones marcadas o bloqueadas, gestiona
/// motivos de censura y ejecuta reescaneos léxicos globales en Odoo 19.
class ModerationScreen extends StatefulWidget {
  static const routeName = 'moderation_screen';

  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final status = _tabController.index == 0 ? 'flagged' : 'banned';
        context.read<ModerationProvider>().setStatusFilter(status);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.isPlatformAdmin) {
        context.read<ModerationProvider>().loadSummary();
        context.read<ModerationProvider>().loadContent(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showBanDialog(ModeratedItemModel item) {
    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n?.bloquearContenido ?? 'Bloquear Contenido',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elemento: ${item.title}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Iglesia: ${item.church.name}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n?.motivoBloqueo ?? 'Motivo del Bloqueo',
                  hintText: l10n?.motivoBloqueoHint ??
                      'Explica por qué este contenido es inapropiado (la iglesia lo verá)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n?.motivoBloqueoObligatorio ??
                        'El motivo del bloqueo es obligatorio';
                  }
                  return null;
                },
              ),
            ],
          ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);

              final ok = await context.read<ModerationProvider>().banContent(
                    type: item.type,
                    id: item.id,
                    reason: reason,
                  );

              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.contenidoBloqueadoExito ?? 'Contenido bloqueado',
                    ),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            child: Text(l10n?.confirmarBloqueo ?? 'Bloquear'),
          ),
        ],
      ),
    );
  }

  void _showUnbanDialog(ModeratedItemModel item) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.desbloquearContenido ?? 'Desbloquear Contenido'),
        content: Text(
          l10n?.confirmarDesbloqueo ??
              '¿Deseas desbloquear este contenido para que vuelva a estar visible en la comunidad?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancelar ?? 'Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context
                  .read<ModerationProvider>()
                  .unbanContent(type: item.type, id: item.id);
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.contenidoDesbloqueadoExito ??
                          'Contenido desbloqueado con éxito',
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
              }
            },
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
  }

  void _showRescanDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.revisarTodoElContenido ?? 'Revisar Todo el Contenido'),
        content: Text(
          l10n?.confirmarRescan ??
              'Se auditarán todas las publicaciones, eventos y notificaciones existentes en busca de palabras restringidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancelar ?? 'Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF072B4F),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final flaggedCount =
                  await context.read<ModerationProvider>().rescanAllContent();
              if (mounted && flaggedCount != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.elementosMarcadosRescan(flaggedCount) ??
                          'Se marcaron $flaggedCount elementos.',
                    ),
                    backgroundColor: const Color(0xFF072B4F),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            child: Text(l10n?.iniciarRevision ?? 'Iniciar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSuperAdmin = context.isPlatformAdmin;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    if (!isSuperAdmin) {
      return Scaffold(
        backgroundColor: blancoFondo,
        appBar: AppBar(
          title: Text(l10n?.moderacionPlataforma ?? 'Moderación de Plataforma'),
          backgroundColor: azulFondo,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n?.permisoRequeridoSuperAdmin ??
                  'Acceso exclusivo para Super Administradores de Plataforma',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    final provider = context.watch<ModerationProvider>();
    final summary = provider.summary;
    final items = provider.items;
    final isLoading = provider.isLoading;
    final isRescanning = provider.isRescanning;

    return Scaffold(
      backgroundColor: blancoFondo,
      appBar: AppBar(
        title: Text(
          l10n?.centroModeracion ?? 'Centro de Moderación',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: azulFondo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: l10n?.revisarTodoElContenido ?? 'Revisar Todo',
            icon: isRescanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(amarilloOro),
                    ),
                  )
                : const Icon(Icons.radar_rounded),
            onPressed: isRescanning ? null : _showRescanDialog,
          ),
          IconButton(
            tooltip: l10n?.palabrasRestringidas ?? 'Palabras Restringidas',
            icon: const Icon(Icons.rule_rounded),
            onPressed: () {
              Navigator.pushNamed(context, ModerationWordsScreen.routeName);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Tarjetas de Resumen Global (/summary)
          _ModerationSummaryHeader(summary: summary),

          // 2. Pestañas de Estado (Marcados vs Bloqueados)
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: azulFondo,
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: amarilloOro,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(
                  icon: const Icon(Icons.flag_rounded, size: 18),
                  text: '${l10n?.marcados ?? 'Marcados'} (${summary?.totalFlagged ?? 0})',
                ),
                Tab(
                  icon: const Icon(Icons.block_rounded, size: 18),
                  text: '${l10n?.bloqueados ?? 'Bloqueados'} (${summary?.totalBanned ?? 0})',
                ),
              ],
            ),
          ),

          // 3. Filtros por Tipo y Barra de Búsqueda
          _TypeFilterChips(
            selectedType: provider.selectedType,
            onTypeSelected: (type) => provider.setTypeFilter(type),
          ),

          // 4. Listado de Contenido Auditado
          Expanded(
            child: RefreshIndicator(
              color: azulFondo,
              onRefresh: () async {
                await Future.wait([
                  provider.loadSummary(),
                  provider.loadContent(refresh: true),
                ]);
              },
              child: isLoading && items.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(azulFondo),
                      ),
                    )
                  : items.isEmpty
                      ? Center(
                          child: Text(
                            l10n?.sinContenidoModerado ??
                                'No hay contenido en esta sección',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsetsDirectional.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final it = items[index];
                            return _ModeratedItemCard(
                              item: it,
                              onBan: () => _showBanDialog(it),
                              onUnban: () => _showUnbanDialog(it),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModerationSummaryHeader extends StatelessWidget {
  final ModerationSummaryModel? summary;

  const _ModerationSummaryHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Container(
      color: azulFondo,
      padding: const EdgeInsetsDirectional.only(
        start: 16,
        end: 16,
        bottom: 16,
        top: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryBox(
              title: l10n?.publicaciones ?? 'Posts',
              flagged: summary?.post.flagged ?? 0,
              banned: summary?.post.banned ?? 0,
              icon: Icons.article_rounded,
              color: amarilloOro,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryBox(
              title: l10n?.eventos ?? 'Eventos',
              flagged: summary?.event.flagged ?? 0,
              banned: summary?.event.banned ?? 0,
              icon: Icons.event_rounded,
              color: const Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryBox(
              title: l10n?.notificaciones ?? 'Avisos',
              flagged: summary?.notification.flagged ?? 0,
              banned: summary?.notification.banned ?? 0,
              icon: Icons.campaign_rounded,
              color: const Color(0xFF4ADE80),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final int flagged;
  final int banned;
  final IconData icon;
  final Color color;

  const _SummaryBox({
    required this.title,
    required this.flagged,
    required this.banned,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🚩 $flagged',
                style: const TextStyle(
                  color: Color(0xFFFDE047),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '🚫 $banned',
                style: const TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeFilterChips extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeSelected;

  const _TypeFilterChips({
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);

    final types = [
      (label: l10n?.publicaciones ?? 'Publicaciones', value: 'post'),
      (label: l10n?.eventos ?? 'Eventos', value: 'event'),
      (label: l10n?.notificaciones ?? 'Notificaciones', value: 'notification'),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: types.map((t) {
          final isSelected = selectedType == t.value;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(t.label),
              selected: isSelected,
              selectedColor: azulFondo,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              backgroundColor: const Color(0xFFF1F5F9),
              onSelected: (_) => onTypeSelected(t.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ModeratedItemCard extends StatelessWidget {
  final ModeratedItemModel item;
  final VoidCallback onBan;
  final VoidCallback onUnban;

  const _ModeratedItemCard({
    required this.item,
    required this.onBan,
    required this.onUnban,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    const Color azulFondo = Color(0xFF072B4F);

    IconData typeIcon = Icons.article_rounded;
    if (item.type == 'event') typeIcon = Icons.event_rounded;
    if (item.type == 'notification') typeIcon = Icons.campaign_rounded;

    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.banned ? Colors.red.shade200 : const Color(0xFFE2E8F0),
        ),
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
          // Encabezado: Tipo + Fecha local
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(typeIcon, color: azulFondo, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    item.type.toUpperCase(),
                    style: const TextStyle(
                      color: azulFondo,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (item.createdAt != null)
                Text(
                  DateFormat.yMMMd(locale).add_jm().format(item.createdAt!),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Título
          Text(
            item.title,
            style: const TextStyle(
              color: azulFondo,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Iglesia
          Row(
            children: [
              Icon(Icons.church_rounded, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.church.name,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // Detalle de Marcas Léxicas (flagged_words)
          if (item.flagged && item.flaggedWords != null && item.flaggedWords!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n?.palabrasDetectadas(item.flaggedWords!) ??
                          'Palabras detectadas: ${item.flaggedWords}',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Detalle de Bloqueo (ban_reason)
          if (item.banned) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.block_rounded, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${l10n?.motivoBloqueo ?? 'Bloqueado'}: ${item.banReason ?? 'Inapropiado'}',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!item.banned)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onBan,
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: Text(l10n?.bloquearContenido ?? 'Bloquear'),
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    side: const BorderSide(color: Color(0xFF16A34A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onUnban,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: Text(l10n?.desbloquearContenido ?? 'Desbloquear'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
