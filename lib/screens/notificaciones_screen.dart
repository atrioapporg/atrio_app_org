import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/providers/user_provider.dart';
import '../modelos/notificacion_model.dart';

class NotificacionesScreen extends StatefulWidget {
  static const routeName = 'notificaciones_screen';

  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0;
  bool _isInit = true;
  bool _isLoading = false;
  List<Map<String, dynamic>> _sponsored = [];

  late List<NotificacionModel> _notificaciones;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      final l10n = AppLocalizations.of(context)!;
      _notificaciones = _crearAvisosIniciales(l10n);
      _cargarNotificaciones();
    }
  }

  Future<void> _cargarNotificaciones({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final res = await userProvider.api.notifications();
      final notisRaw = res['notifications'] as List? ?? [];
      final sponsoredRaw = res['sponsored'] as List? ?? [];

      final List<NotificacionModel> parsed = notisRaw
          .map((e) => NotificacionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (mounted) {
        setState(() {
          if (parsed.isNotEmpty) {
            _notificaciones = parsed;
          }
          _sponsored = sponsoredRaw
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> _obtenerFiltros(AppLocalizations l10n) => [
    l10n.filtroTodas,
    l10n.filtroNoLeidas,
    l10n.categoriaServicios,
    l10n.categoriaEventos,
    l10n.categoriaComunidad,
  ];

  // 3 avisos/notificaciones iniciales (preparados para Odoo 19)
  List<NotificacionModel> _crearAvisosIniciales(AppLocalizations l10n) => [
    NotificacionModel(
      id: '1',
      titulo: l10n.notiHorarioServicioTitulo,
      resumen: l10n.notiHorarioServicioResumen,
      cuerpo: l10n.notiHorarioServicioCuerpo,
      fecha: l10n.fechaHoy,
      hora: l10n.hora1030am,
      categoria: l10n.categoriaServicios,
      remitente: l10n.remitenteAdmin,
      leida: false,
      esUrgente: true,
      iconCode: 'schedule',
    ),
    NotificacionModel(
      id: '2',
      titulo: l10n.notiRetiroTitulo,
      resumen: l10n.notiRetiroResumen,
      cuerpo: l10n.notiRetiroCuerpo,
      fecha: l10n.fechaAyer,
      hora: l10n.hora415pm,
      categoria: l10n.categoriaEventos,
      remitente: l10n.remitenteEventos,
      leida: false,
      esUrgente: false,
      iconCode: 'event',
    ),
    NotificacionModel(
      id: '3',
      titulo: l10n.notiCampanaTitulo,
      resumen: l10n.notiCampanaResumen,
      cuerpo: l10n.notiCampanaCuerpo,
      fecha: l10n.fechaHace2Dias,
      hora: l10n.hora900am,
      categoria: l10n.categoriaComunidad,
      remitente: l10n.remitentePastoralSocial,
      leida: false,
      esUrgente: false,
      iconCode: 'volunteer',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    super.deactivate();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  int get _conteoNoLeidas => _notificaciones.where((n) => !n.leida).length;

  List<NotificacionModel> _filtrarNotificaciones(AppLocalizations l10n) {
    final query = _searchController.text.trim().toLowerCase();

    return _notificaciones.where((noti) {
      bool coincideFiltro = true;
      if (_selectedFilterIndex == 1) {
        coincideFiltro = !noti.leida;
      } else if (_selectedFilterIndex == 2) {
        coincideFiltro =
            noti.categoria.toLowerCase() == l10n.categoriaServicios.toLowerCase() ||
            noti.categoria.toLowerCase() == 'servicios' ||
            noti.categoria.toLowerCase() == 'services';
      } else if (_selectedFilterIndex == 3) {
        coincideFiltro =
            noti.categoria.toLowerCase() == l10n.categoriaEventos.toLowerCase() ||
            noti.categoria.toLowerCase() == 'eventos' ||
            noti.categoria.toLowerCase() == 'events';
      } else if (_selectedFilterIndex == 4) {
        coincideFiltro =
            noti.categoria.toLowerCase() == l10n.categoriaComunidad.toLowerCase() ||
            noti.categoria.toLowerCase() == 'comunidad' ||
            noti.categoria.toLowerCase() == 'community';
      }

      final coincideQuery =
          query.isEmpty ||
          noti.titulo.toLowerCase().contains(query) ||
          noti.resumen.toLowerCase().contains(query) ||
          noti.cuerpo.toLowerCase().contains(query) ||
          noti.remitente.toLowerCase().contains(query);

      return coincideFiltro && coincideQuery;
    }).toList();
  }

  void _marcarTodasComoLeidas() {
    if (!mounted) return;
    setState(() {
      _notificaciones = _notificaciones
          .map((n) => n.copyWith(leida: true))
          .toList();
    });
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.todasNotificacionesLeidas,
          style: const TextStyle(fontSize: 15),
        ),
        backgroundColor: const Color(0xFF072B4F),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _marcarComoLeida(String id) {
    if (!mounted) return;
    setState(() {
      _notificaciones = _notificaciones.map((n) {
        if (n.id == id) {
          return n.copyWith(leida: true);
        }
        return n;
      }).toList();
    });
  }

  /// Borra una sola notificación con soporte para Deshacer
  void _eliminarNotificacion(NotificacionModel noti) {
    if (!mounted) return;
    final int index = _notificaciones.indexWhere((n) => n.id == noti.id);
    setState(() {
      _notificaciones.removeWhere((n) => n.id == noti.id);
    });

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.notificacionEliminada(noti.titulo),
          style: const TextStyle(fontSize: 15),
        ),
        backgroundColor: const Color(0xFF072B4F),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.deshacer,
          textColor: const Color(0xFFE5A023),
          onPressed: () {
            if (!mounted) return;
            setState(() {
              if (index >= 0 && index <= _notificaciones.length) {
                _notificaciones.insert(index, noti);
              } else {
                _notificaciones.add(noti);
              }
            });
          },
        ),
      ),
    );
  }

  /// Muestra diálogo de confirmación antes de borrar todas las notificaciones
  void _confirmarBorrarTodas() {
    if (_notificaciones.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.borrarAvisos,
                style: const TextStyle(
                  color: Color(0xFF072B4F),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            l10n.confirmarBorrarTodasMensaje,
            style: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                l10n.cancelar,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _borrarTodas();
              },
              child: Text(
                l10n.borrarTodas,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Borra todas las notificaciones con respaldo para Deshacer
  void _borrarTodas() {
    if (!mounted) return;
    final List<NotificacionModel> respaldo = List<NotificacionModel>.from(
      _notificaciones,
    );
    setState(() {
      _notificaciones.clear();
    });

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.todasNotificacionesEliminadas,
          style: const TextStyle(fontSize: 15),
        ),
        backgroundColor: const Color(0xFF072B4F),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.deshacer,
          textColor: const Color(0xFFE5A023),
          onPressed: () {
            if (!mounted) return;
            setState(() {
              _notificaciones = respaldo;
            });
          },
        ),
      ),
    );
  }

  /// Restaura los avisos ficticios temporales para pruebas
  void _restaurarAvisosEjemplo() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _notificaciones = _crearAvisosIniciales(l10n);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.avisosEjemploRestaurados,
          style: const TextStyle(fontSize: 15),
        ),
        backgroundColor: const Color(0xFF072B4F),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _obtenerIcono(String iconCode) {
    switch (iconCode) {
      case 'schedule':
        return Icons.access_time_rounded;
      case 'event':
        return Icons.calendar_month_rounded;
      case 'volunteer':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    final l10n = AppLocalizations.of(context)!;
    final filters = _obtenerFiltros(l10n);
    final notificacionesFiltradas = _filtrarNotificaciones(l10n);

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE5E5E5);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // Encabezado Superior con tipografía amplia y clara
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.02),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white,
                              size: screenWidth * 0.07,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            l10n.notificaciones,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.052,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_notificaciones.isNotEmpty) ...[
                          if (_conteoNoLeidas > 0)
                            IconButton(
                              tooltip: l10n.marcarTodasComoLeidas,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.01,
                              ),
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.done_all_rounded,
                                color: amarilloOro,
                                size: screenWidth * 0.065,
                              ),
                              onPressed: _marcarTodasComoLeidas,
                            ),
                          SizedBox(width: screenWidth * 0.015),
                          IconButton(
                            tooltip: l10n.borrarTodas,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.01,
                            ),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.delete_sweep_outlined,
                              color: Colors.white,
                              size: screenWidth * 0.065,
                            ),
                            onPressed: _confirmarBorrarTodas,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.015),

                    // Buscador reactivo adaptado con letra legible
                    Container(
                      height: usableHeight * 0.056,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.040,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.buscarEnAvisosPlaceholder,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: screenWidth * 0.038,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade600,
                            size: screenWidth * 0.055,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    size: screenWidth * 0.050,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                padding: EdgeInsets.zero,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: usableHeight * 0.013,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.015),
                    if (_isLoading) ...[
                      LinearProgressIndicator(
                        color: amarilloOro,
                        backgroundColor: azulFondo.withValues(alpha: 0.2),
                        minHeight: 3,
                      ),
                      SizedBox(height: usableHeight * 0.010),
                    ],
                  ],
                ),
              ),

              // Contenedor Blanco Inferior Scrollable
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: blancoFondo,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.08),
                      topRight: Radius.circular(screenWidth * 0.08),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.08),
                      topRight: Radius.circular(screenWidth * 0.08),
                    ),
                    child: RefreshIndicator(
                      color: amarilloOro,
                      backgroundColor: Colors.white,
                      onRefresh: () => _cargarNotificaciones(silent: true),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: usableHeight * 0.02,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // Pastillas de Filtro con mayor tamaño táctil y tipográfico
                          SizedBox(
                            height: usableHeight * 0.052,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: filters.length,
                              separatorBuilder: (context, index) =>
                                   SizedBox(width: screenWidth * 0.025),
                              itemBuilder: (context, index) {
                                final isSelected =
                                    _selectedFilterIndex == index;
                                final label = filters[index];
                                final bool esNoLeidas = index == 1;

                                return GestureDetector(
                                  onTap: () {
                                    if (mounted) {
                                      setState(() {
                                        _selectedFilterIndex = index;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.042,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? azulFondo
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        screenWidth * 0.028,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? azulFondo
                                            : grisBorde,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          label,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : azulFondo,
                                            fontSize: screenWidth * 0.038,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (esNoLeidas &&
                                            _conteoNoLeidas > 0) ...[
                                          SizedBox(width: screenWidth * 0.018),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? amarilloOro
                                                  : azulFondo,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '$_conteoNoLeidas',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? azulFondo
                                                    : Colors.white,
                                                fontSize: screenWidth * 0.028,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // Indicador de estado y ayuda visual
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.avisosDeLaComunidad,
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.048,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                l10n.conteoNoLeidas(_conteoNoLeidas),
                                style: TextStyle(
                                  color: _conteoNoLeidas > 0
                                      ? const Color(0xFF9E6500)
                                      : Colors.grey.shade600,
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.006),

                          if (_notificaciones.isNotEmpty)
                            Text(
                              l10n.deslizaAvisoParaEliminar,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: screenWidth * 0.032,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          SizedBox(height: usableHeight * 0.014),

                          // Lista de Notificaciones
                          if (notificacionesFiltradas.isEmpty)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: usableHeight * 0.06,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.notifications_off_outlined,
                                      color: Colors.grey.shade400,
                                      size: screenWidth * 0.16,
                                    ),
                                    SizedBox(height: usableHeight * 0.015),
                                    Text(
                                      l10n.noHayAvisosMomento,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: screenWidth * 0.044,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: usableHeight * 0.006),
                                    Text(
                                      l10n.avisosOdooApareceranAqui,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: screenWidth * 0.034,
                                      ),
                                    ),
                                    if (_notificaciones.isEmpty) ...[
                                      SizedBox(height: usableHeight * 0.025),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: azulFondo,
                                          side: BorderSide(
                                            color: azulFondo,
                                            width: 1.5,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.04,
                                            vertical: usableHeight * 0.014,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              screenWidth * 0.025,
                                            ),
                                          ),
                                        ),
                                        onPressed: _restaurarAvisosEjemplo,
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          size: 22,
                                        ),
                                        label: Text(
                                          l10n.restaurarAvisosEjemplo,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.036,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: notificacionesFiltradas.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: usableHeight * 0.016),
                              itemBuilder: (context, index) {
                                final noti = notificacionesFiltradas[index];
                                return Dismissible(
                                  key: Key('noti_${noti.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.only(
                                      right: screenWidth * 0.05,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius: BorderRadius.circular(
                                        screenWidth * 0.035,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          l10n.eliminar,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.036,
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.015),
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.white,
                                          size: screenWidth * 0.065,
                                        ),
                                      ],
                                    ),
                                  ),
                                  onDismissed: (_) {
                                    _eliminarNotificacion(noti);
                                  },
                                  child: _buildNotificationTile(
                                    noti: noti,
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                    azulFondo: azulFondo,
                                    amarilloOro: amarilloOro,
                                    grisBorde: grisBorde,
                                    onTap: () {
                                      _marcarComoLeida(noti.id);
                                      _showNotificationDetailModal(
                                        context,
                                        noti,
                                        screenWidth,
                                        usableHeight,
                                        azulFondo,
                                        amarilloOro,
                                        blancoFondo,
                                      );
                                    },
                                    onDelete: () => _eliminarNotificacion(noti),
                                  ),
                                );
                              },
                            ),
                          if (_sponsored.isNotEmpty) ...[
                            SizedBox(height: usableHeight * 0.02),
                            ..._sponsored.map((ad) {
                              final title = ad['title'] as String? ?? '';
                              final msg = ad['message'] as String? ?? '';
                              final advertiser = ad['advertiser'] as String? ?? '';

                              return Container(
                                margin: EdgeInsets.only(bottom: usableHeight * 0.015),
                                padding: EdgeInsets.all(screenWidth * 0.035),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF9E6),
                                  borderRadius: BorderRadius.circular(screenWidth * 0.035),
                                  border: Border.all(
                                    color: amarilloOro.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(screenWidth * 0.02),
                                      decoration: BoxDecoration(
                                        color: amarilloOro.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.campaign_rounded,
                                        color: const Color(0xFF9E6500),
                                        size: screenWidth * 0.055,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: amarilloOro.withValues(alpha: 0.3),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  l10n.publicidad,
                                                  style: TextStyle(
                                                    color: const Color(0xFF9E6500),
                                                    fontSize: screenWidth * 0.026,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (advertiser.isNotEmpty)
                                                Text(
                                                  advertiser,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: screenWidth * 0.028,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: usableHeight * 0.005),
                                          Text(
                                            title,
                                            style: TextStyle(
                                              color: azulFondo,
                                              fontSize: screenWidth * 0.040,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (msg.isNotEmpty) ...[
                                            SizedBox(height: usableHeight * 0.003),
                                            Text(
                                              msg,
                                              style: TextStyle(
                                                color: Colors.grey.shade800,
                                                fontSize: screenWidth * 0.034,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          SizedBox(height: usableHeight * 0.03),
                        ],
                      ),
                    ),
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

  // Componente: Tarjeta de Notificación con tipografía de alto contraste y tamaño cómodo
  Widget _buildNotificationTile({
    required NotificacionModel noti,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool tieneImagen = noti.imageUrl != null && noti.imageUrl!.isNotEmpty;
    final String? fullImageUrl = tieneImagen
        ? userProvider.api.imageUrl(noti.imageUrl!)
        : null;

    if (tieneImagen && fullImageUrl != null) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: noti.leida ? Colors.white : const Color(0xFFF0F5FA),
            borderRadius: BorderRadius.circular(screenWidth * 0.035),
            border: Border.all(
              color: noti.leida ? grisBorde : azulFondo.withValues(alpha: 0.25),
              width: noti.leida ? 1.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(screenWidth * 0.035),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen superior destacada
                Image.network(
                  fullImageUrl,
                  width: double.infinity,
                  height: usableHeight * 0.17,
                  fit: BoxFit.cover,
                  headers: userProvider.api.imageHeaders,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: usableHeight * 0.17,
                      color: azulFondo.withValues(alpha: 0.05),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: amarilloOro,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.038),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera: Categoría, Estado Urgente, Punto no leída y Eliminar
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.024,
                              vertical: usableHeight * 0.003,
                            ),
                            decoration: BoxDecoration(
                              color: noti.esUrgente
                                  ? amarilloOro.withValues(alpha: 0.20)
                                  : azulFondo.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.015,
                              ),
                            ),
                            child: Text(
                              noti.categoria.toUpperCase(),
                              style: TextStyle(
                                color: noti.esUrgente
                                    ? const Color(0xFF9E6500)
                                    : azulFondo,
                                fontSize: screenWidth * 0.028,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          if (!noti.leida) ...[
                            SizedBox(width: screenWidth * 0.02),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: amarilloOro,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            '${noti.fecha} · ${noti.hora}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: screenWidth * 0.029,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.grey.shade500,
                              size: screenWidth * 0.054,
                            ),
                            tooltip: l10n.eliminarAviso,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onDelete,
                          ),
                        ],
                      ),
                      SizedBox(height: usableHeight * 0.008),

                      // Título
                      Text(
                        noti.titulo,
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.044,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: usableHeight * 0.006),

                      // Resumen
                      Text(
                        noti.resumen,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: screenWidth * 0.035,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: usableHeight * 0.012),

                      // Emisor y enlace "Ver detalle"
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_rounded,
                            size: screenWidth * 0.036,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          Expanded(
                            child: Text(
                              noti.remitente,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: screenWidth * 0.030,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Ver detalle',
                                style: TextStyle(
                                  color: const Color(0xFF9E6500),
                                  fontSize: screenWidth * 0.030,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: const Color(0xFF9E6500),
                                size: screenWidth * 0.040,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(screenWidth * 0.040),
        decoration: BoxDecoration(
          color: noti.leida ? Colors.white : const Color(0xFFF0F5FA),
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(
            color: noti.leida ? grisBorde : azulFondo.withValues(alpha: 0.25),
            width: noti.leida ? 1.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono representativo amplio
            Container(
              width: screenWidth * 0.125,
              height: screenWidth * 0.125,
              decoration: BoxDecoration(
                color: noti.esUrgente
                    ? amarilloOro.withValues(alpha: 0.20)
                    : azulFondo.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _obtenerIcono(noti.iconCode),
                color: noti.esUrgente ? const Color(0xFF9E6500) : azulFondo,
                size: screenWidth * 0.065,
              ),
            ),
            SizedBox(width: screenWidth * 0.032),

            // Contenido con tipografía ampliada para lectura sin esfuerzo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          noti.titulo,
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.044,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!noti.leida) ...[
                        SizedBox(width: screenWidth * 0.015),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: amarilloOro,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.005),
                  Text(
                    noti.resumen,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: screenWidth * 0.036,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: usableHeight * 0.010),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.024,
                          vertical: usableHeight * 0.003,
                        ),
                        decoration: BoxDecoration(
                          color: azulFondo.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.015,
                          ),
                        ),
                        child: Text(
                          noti.categoria,
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.030,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: Text(
                          '${noti.remitente} · ${noti.fecha}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: screenWidth * 0.031,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.01),

            // Botón de eliminar individual en la tarjeta con toque cómodo
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.grey.shade500,
                size: screenWidth * 0.058,
              ),
              tooltip: l10n.eliminarAviso,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  // Modal Inferior de Detalle Completo de Notificación optimizado para personas mayores
  void _showNotificationDetailModal(
    BuildContext context,
    NotificacionModel noti,
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
    Color blancoFondo,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: BoxDecoration(
            color: blancoFondo,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(screenWidth * 0.06),
              topRight: Radius.circular(screenWidth * 0.06),
            ),
          ),
          padding: EdgeInsets.only(
            left: screenWidth * 0.06,
            right: screenWidth * 0.06,
            top: usableHeight * 0.018,
            bottom:
                MediaQuery.of(modalContext).padding.bottom +
                usableHeight * 0.02,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de arrastre
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

              // Cabecera del aviso
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.032,
                      vertical: usableHeight * 0.006,
                    ),
                    decoration: BoxDecoration(
                      color: noti.esUrgente
                          ? amarilloOro.withValues(alpha: 0.20)
                          : azulFondo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(screenWidth * 0.020),
                    ),
                    child: Text(
                      noti.categoria.toUpperCase(),
                      style: TextStyle(
                        color: noti.esUrgente
                            ? const Color(0xFF9E6500)
                            : azulFondo,
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      '${noti.fecha} · ${noti.hora}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: screenWidth * 0.034,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade400,
                      size: screenWidth * 0.065,
                    ),
                    tooltip: l10n.eliminarEsteAviso,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.pop(modalContext);
                      _eliminarNotificacion(noti);
                    },
                  ),
                ],
              ),
              SizedBox(height: usableHeight * 0.014),

              // Imagen destacada si existe (estilo modal Odoo / comunicado)
              if (noti.imageUrl != null && noti.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.035),
                  child: Image.network(
                    Provider.of<UserProvider>(context, listen: false)
                        .api
                        .imageUrl(noti.imageUrl!),
                    width: double.infinity,
                    height: usableHeight * 0.22,
                    fit: BoxFit.cover,
                    headers: Provider.of<UserProvider>(context, listen: false)
                        .api
                        .imageHeaders,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: usableHeight * 0.22,
                        decoration: BoxDecoration(
                          color: azulFondo.withValues(alpha: 0.06),
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.035),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: amarilloOro,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: usableHeight * 0.016),
              ],

              // Título ampliado
              Text(
                noti.titulo,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.056,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              SizedBox(height: usableHeight * 0.008),

              // Emisor
              Row(
                children: [
                  Icon(
                    Icons.account_balance_rounded,
                    size: screenWidth * 0.045,
                    color: Colors.grey.shade700,
                  ),
                  SizedBox(width: screenWidth * 0.018),
                  Expanded(
                    child: Text(
                      noti.remitente,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: screenWidth * 0.038,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: usableHeight * 0.02),

              // Cuerpo completo con tipografía generosa y alto contraste
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.045),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Text(
                  noti.cuerpo,
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontSize: screenWidth * 0.042,
                    height: 1.55,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.025),

              // Botones de acción accesibles
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300, width: 1.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.045,
                        vertical: usableHeight * 0.016,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.025,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(modalContext);
                      _eliminarNotificacion(noti);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    label: Text(
                      l10n.eliminar,
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulFondo,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: usableHeight * 0.016,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.025,
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.pop(modalContext),
                      child: Text(
                        l10n.entendido,
                        style: TextStyle(
                          fontSize: screenWidth * 0.042,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
