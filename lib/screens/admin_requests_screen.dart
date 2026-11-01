import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/admin_models.dart';
import 'package:atrio/providers/admin_provider.dart';
import 'package:atrio/widgets/atrio_connectivity_alert.dart';

/// Pantalla completa de gestión y atención pastoral de solicitudes (Odoo 19 /admin/requests).
/// Permite filtrar por estado (nueva, en_progreso, respondida, rechazada), por tipo y responder en tiempo real.
class AdminRequestsScreen extends StatefulWidget {
  static const String routeName = '/admin-requests';

  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  String _selectedStatus = 'all'; // 'all', 'nueva', 'en_progreso', 'respondida', 'rechazada'
  String _selectedType = 'all'; // 'all', 'oracion', 'ayuda', 'consejeria'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadChurchRequests();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color blancoFondo = Color(0xFFFAF7F0);

    return Scaffold(
      backgroundColor: blancoFondo,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          l10n?.bandejaSolicitudes ?? 'Bandeja de Solicitudes',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulFondo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n?.refrescar ?? 'Refrescar',
            onPressed: () async {
              final bool hasInternet =
                  await AtrioConnectivityAlert.checkAndNotify(
                context,
                onRetry: () =>
                    context.read<AdminProvider>().loadChurchRequests(),
              );
              if (hasInternet && context.mounted) {
                context.read<AdminProvider>().loadChurchRequests();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Barra de búsqueda y filtros
          _FilterSection(
            searchController: _searchController,
            searchQuery: _searchQuery,
            selectedStatus: _selectedStatus,
            selectedType: _selectedType,
            onSearchChanged: (val) {
              setState(() => _searchQuery = val.trim().toLowerCase());
            },
            onStatusChanged: (status) {
              setState(() => _selectedStatus = status);
            },
            onTypeChanged: (type) {
              setState(() => _selectedType = type);
            },
          ),

          // 2. Lista de solicitudes
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.churchRequests.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE5A023)),
                  );
                }

                if (provider.errorMessage != null && provider.churchRequests.isEmpty) {
                  return _ErrorNotice(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadChurchRequests(),
                  );
                }

                final filtered = provider.churchRequests.where((req) {
                  // Filtro por estado
                  if (_selectedStatus != 'all' && req.state != _selectedStatus) {
                    return false;
                  }
                  // Filtro por tipo
                  if (_selectedType != 'all' && req.type != _selectedType) {
                    return false;
                  }
                  // Filtro por texto de búsqueda
                  if (_searchQuery.isNotEmpty) {
                    final matchTitle = req.title.toLowerCase().contains(_searchQuery);
                    final matchReq = req.requesterName.toLowerCase().contains(_searchQuery);
                    final matchMsg = req.message.toLowerCase().contains(_searchQuery);
                    if (!matchTitle && !matchReq && !matchMsg) return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _EmptyRequestsNotice(
                    selectedStatus: _selectedStatus,
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFFE5A023),
                  onRefresh: () => provider.loadChurchRequests(),
                  child: ListView.separated(
                    padding: const EdgeInsetsDirectional.all(16),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _AdminRequestCard(
                        request: item,
                        onAnswer: () => _openAnswerDialog(context, item),
                        onApprove: () => _handleApprove(item.id),
                        onReject: () => _openRejectDialog(context, item.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openAnswerDialog(BuildContext context, AdminChurchRequestModel request) {
    showDialog(
      context: context,
      builder: (ctx) => _PastoralAnswerModal(request: request),
    );
  }

  void _openRejectDialog(BuildContext context, int requestId) {
    showDialog(
      context: context,
      builder: (ctx) => _PastoralRejectModal(requestId: requestId),
    );
  }

  Future<void> _handleApprove(int requestId) async {
    final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: () => _handleApprove(requestId),
    );
    if (!hasInternet || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final ok = await context
        .read<AdminProvider>()
        .approveChurchRequest(requestId: requestId);
    if (ok && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.solicitudAprobadaExito ?? 'Solicitud aprobada con éxito.',
          ),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    }
  }
}

/// Sección superior de filtrado y búsqueda
class _FilterSection extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedStatus;
  final String selectedType;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onTypeChanged;

  const _FilterSection({
    required this.searchController,
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedType,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      color: Colors.white,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de búsqueda
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n?.buscarPorNombreOTitulo ?? 'Buscar por solicitante o título...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF072B4F)),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Chips de estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _StatusFilterChip(
                  label: l10n?.todasLasCategorias ?? 'Todas',
                  isSelected: selectedStatus == 'all',
                  onSelected: () => onStatusChanged('all'),
                ),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  label: l10n?.estadoNueva ?? 'Nueva',
                  isSelected: selectedStatus == 'nueva',
                  badgeColor: const Color(0xFF0369A1),
                  onSelected: () => onStatusChanged('nueva'),
                ),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  label: l10n?.estadoEnProgreso ?? 'En Progreso',
                  isSelected: selectedStatus == 'en_progreso',
                  badgeColor: const Color(0xFFB45309),
                  onSelected: () => onStatusChanged('en_progreso'),
                ),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  label: l10n?.estadoRespondida ?? 'Respondida',
                  isSelected: selectedStatus == 'respondida',
                  badgeColor: const Color(0xFF15803D),
                  onSelected: () => onStatusChanged('respondida'),
                ),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  label: l10n?.estadoRechazada ?? 'Rechazada',
                  isSelected: selectedStatus == 'rechazada',
                  badgeColor: const Color(0xFFB91C1C),
                  onSelected: () => onStatusChanged('rechazada'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? badgeColor;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    this.badgeColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? azulFondo : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? azulFondo : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta individual de solicitud pastoral
class _AdminRequestCard extends StatelessWidget {
  final AdminChurchRequestModel request;
  final VoidCallback onAnswer;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AdminRequestCard({
    required this.request,
    required this.onAnswer,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    final statusStyle = _resolveStatusStyle(request.state);
    final typeLabel = _resolveTypeLabel(request.type, l10n);
    final formattedDate = _formatDate(context, request.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08072B4F),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera de la tarjeta: Tipo y Estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge de Tipo
              Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: azulFondo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_resolveTypeIcon(request.type), size: 14, color: azulFondo),
                    const SizedBox(width: 4),
                    Text(
                      typeLabel,
                      style: const TextStyle(
                        color: azulFondo,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Badge de Estado
              Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusStyle.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusStyle.label(l10n),
                  style: TextStyle(
                    color: statusStyle.textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Título de la Solicitud
          Text(
            request.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: azulFondo,
            ),
          ),
          const SizedBox(height: 6),

          // 3. Feligrés solicitante y fecha
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.requesterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  formattedDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Mensaje del solicitante
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: Text(
              request.message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),

          // 5. Respuesta Pastoral previa (si existe)
          if (request.response != null && request.response!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF15803D)),
                      const SizedBox(width: 4),
                      Text(
                        l10n?.respuestaPastoralEmitida ?? 'Respuesta Pastoral Emitida',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.response!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF166534),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 6. Motivo de rechazo (si aplica)
          if (request.rejectionReason != null && request.rejectionReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFEE2E2)),
              ),
              child: Text(
                l10n?.solicitudRechazadaMotivo(request.rejectionReason!) ??
                    'Rechazada: ${request.rejectionReason}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF991B1B),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 7. Barra de acciones rápidas pastorales (Wrap para evitar desbordamiento en pantallas angostas)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Botón de Rechazar (solo si no está resuelta)
                if (!request.isAnswered && !request.isRejected)
                  TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                    ),
                    child: Text(l10n?.rechazarSolicitud ?? 'Rechazar'),
                  ),

                // Botón de Responder / Atender
                ElevatedButton.icon(
                  onPressed: onAnswer,
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: Text(
                    request.isAnswered
                        ? (l10n?.actualizarRespuesta ?? 'Actualizar Respuesta')
                        : (l10n?.responderAhora ?? 'Responder Ahora'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: request.isAnswered ? azulFondo : amarilloOro,
                    foregroundColor: request.isAnswered ? Colors.white : azulFondo,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final locale = Localizations.localeOf(context).toString();
      return DateFormat('d MMM yyyy, h:mm a', locale).format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  IconData _resolveTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'oracion':
        return Icons.favorite_rounded;
      case 'ayuda':
        return Icons.handshake_rounded;
      case 'consejeria':
        return Icons.record_voice_over_rounded;
      default:
        return Icons.mark_email_unread_rounded;
    }
  }

  String _resolveTypeLabel(String type, AppLocalizations? l10n) {
    switch (type.toLowerCase()) {
      case 'oracion':
        return l10n?.tipoOracion ?? 'Oración';
      case 'ayuda':
        return l10n?.tipoAyuda ?? 'Ayuda';
      case 'consejeria':
        return l10n?.tipoConsejeria ?? 'Consejería';
      default:
        return type.toUpperCase();
    }
  }

  _StatusStyle _resolveStatusStyle(String state) {
    switch (state.toLowerCase()) {
      case 'nueva':
      case 'draft':
      case 'pending':
        return _StatusStyle(
          label: (l) => l?.estadoNueva ?? 'Nueva',
          backgroundColor: const Color(0xFFE0F2FE),
          textColor: const Color(0xFF0369A1),
        );
      case 'en_progreso':
        return _StatusStyle(
          label: (l) => l?.estadoEnProgreso ?? 'En Progreso',
          backgroundColor: const Color(0xFFFEF3C7),
          textColor: const Color(0xFFB45309),
        );
      case 'respondida':
      case 'approved':
      case 'done':
        return _StatusStyle(
          label: (l) => l?.estadoRespondida ?? 'Respondida',
          backgroundColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF15803D),
        );
      case 'rechazada':
        return _StatusStyle(
          label: (l) => l?.estadoRechazada ?? 'Rechazada',
          backgroundColor: const Color(0xFFFEE2E2),
          textColor: const Color(0xFFB91C1C),
        );
      default:
        return _StatusStyle(
          label: (_) => state,
          backgroundColor: const Color(0xFFF1F5F9),
          textColor: const Color(0xFF475569),
        );
    }
  }
}

class _StatusStyle {
  final String Function(AppLocalizations?) label;
  final Color backgroundColor;
  final Color textColor;

  const _StatusStyle({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

/// Diálogo Material 3 para responder con mensaje pastoral
class _PastoralAnswerModal extends StatefulWidget {
  final AdminChurchRequestModel request;

  const _PastoralAnswerModal({required this.request});

  @override
  State<_PastoralAnswerModal> createState() => _PastoralAnswerModalState();
}

class _PastoralAnswerModalState extends State<_PastoralAnswerModal> {
  late final TextEditingController _responseController;
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    final initialText = widget.request.response ?? '';
    _responseController = TextEditingController(text: initialText);
    if (initialText.isNotEmpty) {
      _responseController.selection = TextSelection.fromPosition(
        TextPosition(offset: initialText.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      titlePadding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 12),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
      actionsPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
      title: Row(
        children: [
          const Icon(Icons.volunteer_activism_rounded, color: azulFondo, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n?.responderSolicitud ?? 'Responder Petición',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: azulFondo),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen compacto de la petición
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_pin_rounded, size: 14, color: azulFondo),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.request.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: azulFondo,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.request.requesterName}: "${widget.request.message}"',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  if (widget.request.message.length > 70) ...[
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(top: 4),
                        child: Text(
                          _isExpanded ? (l10n?.verMenos ?? 'Ver menos') : (l10n?.verMas ?? 'Ver más'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: azulFondo,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Campo de respuesta pastoral
            Text(
              l10n?.escribirRespuestaPastoral ?? 'Escribe tu mensaje pastoral para el feligrés...',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _responseController,
              focusNode: _focusNode,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: azulFondo,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: l10n?.placeholderRespuestaPastoral ?? 'Escribe tu respuesta aquí...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.normal,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsetsDirectional.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: azulFondo, width: 1.8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          child: Text(
            MaterialLocalizations.of(context).cancelButtonLabel,
            style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _submitAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: amarilloOro,
            foregroundColor: azulFondo,
            elevation: 0,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: azulFondo),
                )
              : Text(l10n?.enviarRespuesta ?? 'Enviar Respuesta', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Future<void> _submitAnswer() async {
    final text = _responseController.text.trim();
    if (text.isEmpty) return;

    final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: () => _submitAnswer(),
    );
    if (!hasInternet || !mounted) return;

    setState(() => _isSending = true);
    final provider = context.read<AdminProvider>();
    final ok = await provider.answerChurchRequest(
      requestId: widget.request.id,
      response: text,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (ok) {
        Navigator.pop(context);
        final messenger = ScaffoldMessenger.of(context);
        final l10n = AppLocalizations.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n?.respuestaEnviadaExito ??
                  '¡Respuesta pastoral enviada con éxito!',
            ),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
      }
    }
  }
}

/// Diálogo para rechazar solicitud con justificación opcional
class _PastoralRejectModal extends StatefulWidget {
  final int requestId;

  const _PastoralRejectModal({required this.requestId});

  @override
  State<_PastoralRejectModal> createState() => _PastoralRejectModalState();
}

class _PastoralRejectModalState extends State<_PastoralRejectModal> {
  final TextEditingController _reasonController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _focusNode.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      titlePadding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 12),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
      actionsPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
      title: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n?.rechazarSolicitud ?? 'Rechazar Solicitud',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: TextField(
          controller: _reasonController,
          focusNode: _focusNode,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          cursorColor: const Color(0xFFDC2626),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: l10n?.motivoRechazo ?? 'Motivo del rechazo (opcional)...',
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsetsDirectional.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.8),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          child: Text(
            MaterialLocalizations.of(context).cancelButtonLabel,
            style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isSending ? null : _submitReject,
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n?.rechazarSolicitud ?? 'Rechazar', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Future<void> _submitReject() async {
    final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: () => _submitReject(),
    );
    if (!hasInternet || !mounted) return;

    setState(() => _isSending = true);
    final ok = await context.read<AdminProvider>().rejectChurchRequest(
          requestId: widget.requestId,
          reason: _reasonController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSending = false);
      if (ok) {
        Navigator.pop(context);
        final messenger = ScaffoldMessenger.of(context);
        final l10n = AppLocalizations.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n?.solicitudRechazadaExito ?? 'Solicitud rechazada.',
            ),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    }
  }
}

/// Estado vacío cuando no hay solicitudes para el filtro
class _EmptyRequestsNotice extends StatelessWidget {
  final String selectedStatus;

  const _EmptyRequestsNotice({required this.selectedStatus});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_rounded, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              l10n?.sinSolicitudesRecientes ?? 'No hay solicitudes en esta sección',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado de error con reintento
class _ErrorNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final bool hasInternet =
                    await AtrioConnectivityAlert.checkAndNotify(
                  context,
                  onRetry: onRetry,
                );
                if (hasInternet) {
                  onRetry();
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n?.reintentar ?? 'Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
