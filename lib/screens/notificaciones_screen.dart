import 'package:flutter/material.dart';

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

  final List<String> _filters = [
    'Todas',
    'No leídas',
    'Servicios',
    'Eventos',
    'Comunidad',
  ];

  // 3 avisos/notificaciones iniciales (preparados para Odoo 19)
  late List<NotificacionModel> _notificaciones = _crearAvisosIniciales();

  List<NotificacionModel> _crearAvisosIniciales() => [
    NotificacionModel(
      id: '1',
      titulo: 'Cambio de horario de servicio',
      resumen: 'Miércoles de Oración · 7:00 p. m. en el Templo Principal.',
      cuerpo: 'Estimada congregación: Por motivos de la jornada pastoral y preparación para las actividades del mes, nuestro servicio de intercesión y estudio bíblico de este miércoles se adelantará 30 minutos, iniciando a las 7:00 p. m. Te invitamos a llegar temprano con tu familia.',
      fecha: 'Hoy',
      hora: '10:30 a. m.',
      categoria: 'Servicios',
      remitente: 'Administración ATRIO',
      leida: false,
      esUrgente: true,
      iconCode: 'schedule',
    ),
    NotificacionModel(
      id: '2',
      titulo: 'Inscripciones abiertas: Retiro 2026',
      resumen: 'Cupos limitados disponibles para jóvenes y familias.',
      cuerpo: '¡Ya puedes apartar tu lugar! Se han abierto formalmente los registros para el Retiro Anual "Vida & Fe 2026" en el Campamento Los Pinos. Puedes realizar tu inscripción directamente desde la sección de Eventos en la app.',
      fecha: 'Ayer',
      hora: '4:15 p. m.',
      categoria: 'Eventos',
      remitente: 'Comité de Eventos',
      leida: false,
      esUrgente: false,
      iconCode: 'event',
    ),
    NotificacionModel(
      id: '3',
      titulo: 'Campaña solidaria "Manos que Bendicen"',
      resumen: 'Recepción de víveres y donaciones este fin de semana.',
      cuerpo: 'Estaremos recolectando alimentos no perecibles, abrigos y kits de aseo en el vestíbulo principal antes de cada reunión dominical. Tu generosa colaboración bendecirá a más de 50 familias vulnerables en nuestra comunidad.',
      fecha: 'Hace 2 días',
      hora: '9:00 a. m.',
      categoria: 'Comunidad',
      remitente: 'Pastoral Social',
      leida: false,
      esUrgente: false,
      iconCode: 'volunteer',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _conteoNoLeidas => _notificaciones.where((n) => !n.leida).length;

  List<NotificacionModel> get _notificacionesFiltradas {
    final query = _searchController.text.trim().toLowerCase();
    final filtroSeleccionado = _filters[_selectedFilterIndex];

    return _notificaciones.where((noti) {
      bool coincideFiltro = true;
      if (filtroSeleccionado == 'No leídas') {
        coincideFiltro = !noti.leida;
      } else if (filtroSeleccionado != 'Todas') {
        coincideFiltro =
            noti.categoria.toLowerCase() == filtroSeleccionado.toLowerCase();
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
    setState(() {
      _notificaciones = _notificaciones
          .map((n) => n.copyWith(leida: true))
          .toList();
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Todas las notificaciones han sido marcadas como leídas',
          style: TextStyle(fontSize: 15),
        ),
        backgroundColor: Color(0xFF072B4F),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _marcarComoLeida(String id) {
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
    final int index = _notificaciones.indexWhere((n) => n.id == noti.id);
    setState(() {
      _notificaciones.removeWhere((n) => n.id == noti.id);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notificación "${noti.titulo}" eliminada',
          style: const TextStyle(fontSize: 15),
        ),
        backgroundColor: const Color(0xFF072B4F),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: const Color(0xFFE5A023),
          onPressed: () {
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

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                'Borrar avisos',
                style: TextStyle(
                  color: Color(0xFF072B4F),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Deseas eliminar todas las notificaciones recibidas? Podrás deshacer la acción inmediatamente si lo deseas.',
            style: TextStyle(color: Colors.black87, fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey, fontSize: 16),
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
              child: const Text(
                'Borrar todas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Borra todas las notificaciones con respaldo para Deshacer
  void _borrarTodas() {
    final List<NotificacionModel> respaldo = List<NotificacionModel>.from(
      _notificaciones,
    );
    setState(() {
      _notificaciones.clear();
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Todas las notificaciones han sido eliminadas',
          style: TextStyle(fontSize: 15),
        ),
        backgroundColor: const Color(0xFF072B4F),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: const Color(0xFFE5A023),
          onPressed: () {
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
    setState(() {
      _notificaciones = _crearAvisosIniciales();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Avisos de ejemplo restaurados',
          style: TextStyle(fontSize: 15),
        ),
        backgroundColor: Color(0xFF072B4F),
        duration: Duration(seconds: 2),
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
                            'Notificaciones',
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
                              tooltip: 'Marcar todas como leídas',
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
                            tooltip: 'Borrar todas',
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
                          hintText: 'Buscar en avisos...',
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
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
                              itemCount: _filters.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(width: screenWidth * 0.025),
                              itemBuilder: (context, index) {
                                final isSelected =
                                    _selectedFilterIndex == index;
                                final label = _filters[index];
                                final bool esNoLeidas = label == 'No leídas';

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFilterIndex = index;
                                    });
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
                                  'Avisos de la comunidad',
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
                                '$_conteoNoLeidas no leídas',
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
                              'Desliza un aviso hacia la izquierda para eliminarlo',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: screenWidth * 0.032,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          SizedBox(height: usableHeight * 0.014),

                          // Lista de Notificaciones
                          if (_notificacionesFiltradas.isEmpty)
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
                                      'No hay avisos en este momento',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: screenWidth * 0.044,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: usableHeight * 0.006),
                                    Text(
                                      'Los avisos publicados en Odoo aparecerán aquí.',
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
                                          'Restaurar avisos de ejemplo',
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
                              itemCount: _notificacionesFiltradas.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: usableHeight * 0.016),
                              itemBuilder: (context, index) {
                                final noti = _notificacionesFiltradas[index];
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
                                          'Eliminar',
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
                          SizedBox(height: usableHeight * 0.03),
                        ],
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
              tooltip: 'Eliminar aviso',
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
                    tooltip: 'Eliminar este aviso',
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
                      'Eliminar',
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
                        'Entendido',
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
