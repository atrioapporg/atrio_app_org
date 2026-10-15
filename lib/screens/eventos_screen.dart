import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../atrio_api.dart';
import '../providers/user_provider.dart';
import '../l10n/app_localizations.dart';

import '../modelos/evento_model.dart';

class EventosScreen extends StatefulWidget {
  static const routeName = 'eventos_screen';

  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'Todos',
    'Liderazgo',
    'Adoración',
    'Jóvenes',
    'Familias',
    'Comunidad',
  ];

  String _getCategoryName(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context);
    switch (category.toLowerCase()) {
      case 'todos':
        return l10n?.categoriaTodos ?? 'Todos';
      case 'liderazgo':
        return l10n?.categoriaLiderazgo ?? 'Liderazgo';
      case 'adoración':
      case 'adoracion':
        return l10n?.categoriaAdoracion ?? 'Adoración';
      case 'jóvenes':
      case 'jovenes':
        return l10n?.categoriaJovenes ?? 'Jóvenes';
      case 'familias':
        return l10n?.categoriaFamilias ?? 'Familias';
      case 'comunidad':
        return l10n?.categoriaComunidad ?? 'Comunidad';
      default:
        return category;
    }
  }

  bool _isLoadingEvents = false;

  // Evento destacado (con fallback inicial local)
  EventoModel _featuredEvent = EventoModel(
    id: '1',
    titulo: 'Conferencia de Liderazgo y Fe 2026',
    organizador: 'Pastor Carlos Gómez & Invitados',
    imagenUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865?q=80&w=800&auto=format&fit=crop',
    categoria: 'Liderazgo',
    fecha: 'Viernes 24 y Sábado 25 de Octubre, 2026',
    hora: '6:30 p. m. - 9:30 p. m.',
    lugar: 'Auditorio Central ATRIO',
    dia: '24',
    mes: 'OCT',
    descripcion: 'Un encuentro transformador diseñado para capacitar a líderes, servidores y familias en principios bíblicos prácticos para el crecimiento integral y el impacto en la comunidad.',
    cupoMaximo: 350,
    cupoReservado: 245,
    esDestacado: true,
    estaInscrito: true,
    fallbackBgColor: '0xFF072B4F',
    fallbackTextColor: '0xFFE5A023',
  );

  // Catálogo inicial de 4 eventos (total 5 eventos con el destacado)
  List<EventoModel> _eventsList = [
    EventoModel(
      id: '2',
      titulo: 'Noche de Adoración Íntima',
      organizador: 'Ministerio de Alabanza ATRIO',
      imagenUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=800&auto=format&fit=crop',
      categoria: 'Adoración',
      fecha: 'Viernes 31 de Octubre, 2026',
      hora: '7:30 p. m.',
      lugar: 'Santuario Principal',
      dia: '31',
      mes: 'OCT',
      descripcion: 'Una noche especial dedicada a la búsqueda espiritual profunda a través de la alabanza acústica, oración compartida e intercesión por la ciudad.',
      cupoMaximo: 200,
      cupoReservado: 180,
      estaInscrito: false,
      fallbackBgColor: '0xFF1B3B5A',
      fallbackTextColor: '0xFFFAF7F0',
    ),
    EventoModel(
      id: '3',
      titulo: 'Encuentro Juvenil "Fuego & Gracia"',
      organizador: 'Comunidad Jóvenes ATRIO',
      imagenUrl: 'https://images.unsplash.com/photo-1523580494863-6f3031224c94?q=80&w=800&auto=format&fit=crop',
      categoria: 'Jóvenes',
      fecha: 'Sábado 07 de Noviembre, 2026',
      hora: '5:00 p. m.',
      lugar: 'Salón Multiusos & Cancha',
      dia: '07',
      mes: 'NOV',
      descripcion: 'Música en vivo, dinámicas de integración, panel de testimonios y un mensaje relevante para jóvenes y universitarios sobre propósito y valentía cristiana.',
      cupoMaximo: 150,
      cupoReservado: 95,
      estaInscrito: false,
      fallbackBgColor: '0xFF2E4057',
      fallbackTextColor: '0xFFE5A023',
    ),
    EventoModel(
      id: '4',
      titulo: 'Seminario Matrimonial "Pacto Firme"',
      organizador: 'Ministerio de Familias',
      imagenUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?q=80&w=800&auto=format&fit=crop',
      categoria: 'Familias',
      fecha: 'Sábado 14 de Noviembre, 2026',
      hora: '9:00 a. m. - 1:00 p. m.',
      lugar: 'Salón de Eventos Las Terrazas',
      dia: '14',
      mes: 'NOV',
      descripcion: 'Taller práctico enfocado en fortalecer los pilares del matrimonio cristiano: comunicación efectiva, perdón sincero, intimidad saludable y finanzas en armonía.',
      cupoMaximo: 80,
      cupoReservado: 64,
      estaInscrito: false,
      fallbackBgColor: '0xFF3D5A80',
      fallbackTextColor: '0xFFFFFFFF',
    ),
    EventoModel(
      id: '5',
      titulo: 'Jornada Solidaria "Manos que Bendicen"',
      organizador: 'Voluntariado Social ATRIO',
      imagenUrl: 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?q=80&w=800&auto=format&fit=crop',
      categoria: 'Comunidad',
      fecha: 'Sábado 21 de Noviembre, 2026',
      hora: '8:00 a. m. - 2:00 p. m.',
      lugar: 'Comedor Solidario Barrio Esperanza',
      dia: '21',
      mes: 'NOV',
      descripcion: 'Jornada de servicio comunitario con entrega de canastas de alimentos, asistencia médica básica, peluquería y actividades recreativas para niños y adultos mayores.',
      cupoMaximo: 60,
      cupoReservado: 42,
      estaInscrito: false,
      fallbackBgColor: '0xFF293241',
      fallbackTextColor: '0xFFE5A023',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEventosOdoo();
    });
  }

  /// Consulta los eventos de la iglesia del usuario en Odoo (GET /events)
  Future<void> _cargarEventosOdoo() async {
    if (!mounted) return;
    setState(() => _isLoadingEvents = true);

    try {
      final userProvider = context.read<UserProvider>();
      final data = await userProvider.api.events(limit: 50);

      final dynamic raw = data['events'] ?? data['items'] ?? data['data'];
      if (raw is List && raw.isNotEmpty) {
        final List<EventoModel> loaded = raw
            .map((e) => EventoModel.fromJson(e as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _eventsList = loaded;
            _featuredEvent = _eventsList.firstWhere(
              (e) => e.esDestacado,
              orElse: () => _eventsList.first,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('[EVENTOS] Odoo fallback activo: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
    }
  }

  /// Inscribe o cancela asistencia a un evento en Odoo (POST/DELETE /events/{id}/register)
  Future<void> _cambiarInscripcion(EventoModel evento) async {
    final userProvider = context.read<UserProvider>();
    final eventId = int.tryParse(evento.id);

    if (eventId == null) {
      // Manejo local para eventos demo/fallback
      setState(() {
        final idx = _eventsList.indexWhere((e) => e.id == evento.id);
        if (idx != -1) {
          final act = _eventsList[idx];
          _eventsList[idx] = EventoModel(
            id: act.id,
            titulo: act.titulo,
            organizador: act.organizador,
            imagenUrl: act.imagenUrl,
            categoria: act.categoria,
            fecha: act.fecha,
            hora: act.hora,
            lugar: act.lugar,
            dia: act.dia,
            mes: act.mes,
            descripcion: act.descripcion,
            cupoMaximo: act.cupoMaximo,
            cupoReservado: act.estaInscrito ? act.cupoReservado - 1 : act.cupoReservado + 1,
            estaInscrito: !act.estaInscrito,
            esDestacado: act.esDestacado,
          );
        }
      });
      return;
    }

    try {
      if (evento.estaInscrito) {
        await userProvider.api.unregisterFromEvent(eventId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inscripción cancelada para "${evento.titulo}".'),
            backgroundColor: const Color(0xFF072B4F),
          ),
        );
      } else {
        await userProvider.api.registerToEvent(eventId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Inscripción confirmada para "${evento.titulo}"!'),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
      }
      await _cargarEventosOdoo();
    } on AtrioApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar inscripción: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtrado reactivo por categoría y texto de búsqueda
  List<EventoModel> get _filteredEvents {
    final query = _searchController.text.trim().toLowerCase();
    final selectedCategory = _categories[_selectedCategoryIndex];

    return _eventsList.where((evento) {
      final matchesCategory =
          selectedCategory == 'Todos' ||
          evento.categoria.toLowerCase() == selectedCategory.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          evento.titulo.toLowerCase().contains(query) ||
          evento.organizador.toLowerCase().contains(query) ||
          evento.lugar.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 1. Métricas relativas dinámicas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    // Paleta de diseño Atrio
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
              // 2. Encabezado Superior (Botón Volver + Título + Buscador reactivo)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de la pantalla con botón de retroceso (Back <-)
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
                        Text(
                          l10n?.eventos ?? 'Eventos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.068,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.015),

                    // Buscador reactivo de eventos
                    Container(
                      height: usableHeight * 0.052,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n?.buscarEventosPlaceholder ??
                              'Buscar eventos, expositores o lugares...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: screenWidth * 0.035,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade600,
                            size: screenWidth * 0.05,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    size: screenWidth * 0.045,
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

              // 3. Contenedor Blanco Inferior Scrollable
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
                      onRefresh: _cargarEventosOdoo,
                      color: azulFondo,
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
                            if (_isLoadingEvents)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: LinearProgressIndicator(
                                  color: azulFondo,
                                  minHeight: 2,
                                ),
                              ),
                            // Banner Hero: Evento Destacado
                            _buildFeaturedEventHero(
                              evento: _featuredEvent,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            amarilloOro: amarilloOro,
                            grisBorde: grisBorde,
                            onTap: () =>
                                _showEventDetailsModal(context, _featuredEvent),
                          ),
                          SizedBox(height: usableHeight * 0.011),

                          // Tarjeta "Mi próximo evento agendado" con miniatura y cupo
                          _buildMyEventScheduleCard(
                            evento: _featuredEvent,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            amarilloOro: amarilloOro,
                            grisBorde: grisBorde,
                            onTap: () =>
                                _showEventDetailsModal(context, _featuredEvent),
                          ),
                          SizedBox(height: usableHeight * 0.020),

                          // Sección Categorías
                          Text(
                            l10n?.categorias ?? 'Categorías',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // Pastillas de Categorías interactivas
                          SizedBox(
                            height: usableHeight * 0.045,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _categories.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(width: screenWidth * 0.025),
                              itemBuilder: (context, index) {
                                final isSelected =
                                    _selectedCategoryIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryIndex = index;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.04,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? azulFondo
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        screenWidth * 0.025,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? azulFondo
                                            : grisBorde,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getCategoryName(
                                          context,
                                          _categories[index],
                                        ),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : azulFondo,
                                          fontSize: screenWidth * 0.032,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.031),

                          // Encabezado "Explorar eventos"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n?.explorarEventos ?? 'Explorar eventos',
                                style: TextStyle(
                                  color: azulFondo,
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedCategoryIndex != 0)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryIndex = 0;
                                    });
                                  },
                                  child: Text(
                                    l10n?.verTodos ?? 'Ver todos',
                                    style: TextStyle(
                                      color: amarilloOro,
                                      fontSize: screenWidth * 0.034,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // Carrusel Horizontal de Eventos filtrado reactivamente
                          SizedBox(
                            height: usableHeight * 0.24,
                            child: _filteredEvents.isEmpty
                                ? Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.event_busy_rounded,
                                          color: Colors.grey.shade500,
                                          size: screenWidth * 0.05,
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        Text(
                                          l10n?.noEventosEnCategoria ??
                                              'No se encontraron eventos en esta categoría',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _filteredEvents.length,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(width: screenWidth * 0.03),
                                    itemBuilder: (context, index) {
                                      final evento = _filteredEvents[index];
                                      return _buildEventCarouselItem(
                                        evento: evento,
                                        screenWidth: screenWidth,
                                        usableHeight: usableHeight,
                                        azulFondo: azulFondo,
                                        amarilloOro: amarilloOro,
                                        onTap: () => _showEventDetailsModal(
                                          context,
                                          evento,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // Sección: Próximos en agenda (Lista vertical)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n?.proximosEnAgenda ?? 'Próximos en agenda',
                                style: TextStyle(
                                  color: azulFondo,
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n?.mostrandoCalendarioCompleto ??
                                            'Mostrando calendario completo de actividades...',
                                      ),
                                      backgroundColor: azulFondo,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Text(
                                  l10n?.verCalendario ?? 'Ver calendario',
                                  style: TextStyle(
                                    color: amarilloOro,
                                    fontSize: screenWidth * 0.034,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // Lista vertical de eventos
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _eventsList.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: usableHeight * 0.014),
                            itemBuilder: (context, index) {
                              final event = _eventsList[index];
                              return _buildEventTile(
                                evento: event,
                                screenWidth: screenWidth,
                                usableHeight: usableHeight,
                                azulFondo: azulFondo,
                                amarilloOro: amarilloOro,
                                grisBorde: grisBorde,
                                onTap: () =>
                                    _showEventDetailsModal(context, event),
                              );
                            },
                          ),
                          SizedBox(height: usableHeight * 0.025),
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

  // Componente: Hero del evento destacado con imagen real y shimmer
  Widget _buildFeaturedEventHero({
    required EventoModel evento,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
    required VoidCallback onTap,
  }) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth,
        padding: EdgeInsets.all(screenWidth * 0.035),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.045),
          border: Border.all(color: grisBorde),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portada / Afiche del evento con shimmer
            Container(
              width: screenWidth * 0.32,
              height: usableHeight * 0.22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                child: Image.network(
                  evento.imagenUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _ShimmerPlaceholder(
                      width: screenWidth * 0.32,
                      height: usableHeight * 0.22,
                      borderRadius: screenWidth * 0.025,
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Color(int.parse(evento.fallbackBgColor)),
                    padding: EdgeInsets.all(screenWidth * 0.025),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          evento.titulo.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(int.parse(evento.fallbackTextColor)),
                            fontSize: screenWidth * 0.032,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(
                          Icons.celebration_rounded,
                          color: Color(int.parse(evento.fallbackTextColor))
                              .withValues(alpha: 0.8),
                          size: screenWidth * 0.08,
                        ),
                        Text(
                          '${evento.dia} ${evento.mes}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.025,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.04),

            // Información y acciones
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etiqueta destacada
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.025,
                      vertical: usableHeight * 0.003,
                    ),
                    decoration: BoxDecoration(
                      color: amarilloOro.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(screenWidth * 0.015),
                    ),
                    child: Text(
                      l10n?.destacadoMayus ?? 'DESTACADO',
                      style: TextStyle(
                        color: const Color(0xFF9E6500),
                        fontSize: screenWidth * 0.024,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.006),
                  Text(
                    evento.titulo,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.046,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: usableHeight * 0.004),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: screenWidth * 0.032,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: screenWidth * 0.012),
                      Expanded(
                        child: Text(
                          '${evento.dia} ${evento.mes} · ${evento.hora}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.028,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.003),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: screenWidth * 0.034,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: screenWidth * 0.012),
                      Expanded(
                        child: Text(
                          evento.lugar,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.028,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.012),

                  // Botón Inscribirme ahora
                  SizedBox(
                    width: double.infinity,
                    height: usableHeight * 0.042,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: amarilloOro,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.025,
                          ),
                        ),
                      ),
                      onPressed: onTap,
                      child: Text(
                        l10n?.inscribirmeAhora ?? 'Inscribirme ahora',
                        style: TextStyle(
                          fontSize: screenWidth * 0.034,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.008),

                  // Botón Añadir a mi calendario
                  SizedBox(
                    width: double.infinity,
                    height: usableHeight * 0.042,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: azulFondo,
                        side: BorderSide(color: azulFondo),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.025,
                          ),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n?.eventoAnadidoACalendario(evento.titulo) ??
                                  'Evento "${evento.titulo}" añadido a tu calendario.',
                            ),
                            backgroundColor: azulFondo,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.event_available_rounded,
                        size: screenWidth * 0.04,
                        color: azulFondo,
                      ),
                      label: Text(
                        l10n?.anadirACalendario ?? 'Añadir a calendario',
                        style: TextStyle(
                          fontSize: screenWidth * 0.030,
                          fontWeight: FontWeight.bold,
                        ),
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

  // Componente: Tarjeta "Mi próximo evento agendado" con indicador de cupo y miniatura
  Widget _buildMyEventScheduleCard({
    required EventoModel evento,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
    required VoidCallback onTap,
  }) {
    final progressPercent = (evento.porcentajeOcupacion * 100).toInt();
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.035),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Miniatura de imagen
                Container(
                  width: screenWidth * 0.11,
                  height: usableHeight * 0.065,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.015),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.015),
                    child: Image.network(
                      evento.imagenUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _ShimmerPlaceholder(
                          width: screenWidth * 0.11,
                          height: usableHeight * 0.065,
                          borderRadius: screenWidth * 0.015,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: azulFondo,
                        child: Icon(
                          Icons.event_note_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.05,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bookmark_added_rounded,
                            size: screenWidth * 0.036,
                            color: amarilloOro,
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          Text(
                            l10n?.miActividadAgendada ?? 'Mi actividad agendada',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: usableHeight * 0.002),
                      Text(
                        evento.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: screenWidth * 0.034,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${evento.dia} ${evento.mes} · ${evento.lugar}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: screenWidth * 0.026,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: azulFondo,
                  size: screenWidth * 0.06,
                ),
              ],
            ),
            SizedBox(height: usableHeight * 0.012),

            // Barra de ocupación / cupo disponible
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    child: LinearProgressIndicator(
                      value: evento.porcentajeOcupacion,
                      minHeight: usableHeight * 0.006,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(amarilloOro),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Text(
                  l10n?.porcentajeOcupacion(progressPercent) ??
                      '$progressPercent% ocupación',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: screenWidth * 0.030,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Componente: Ítem del carrusel horizontal de eventos con Shimmer y fallback
  Widget _buildEventCarouselItem({
    required EventoModel evento,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required VoidCallback onTap,
  }) {
    final coverBg = Color(int.parse(evento.fallbackBgColor));
    final textColor = Color(int.parse(evento.fallbackTextColor));

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: screenWidth * 0.32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del evento con insignia de fecha en esquina
            Container(
              width: screenWidth * 0.32,
              height: usableHeight * 0.14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 5,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                      child: evento.imagenUrl.isNotEmpty
                          ? Image.network(
                              evento.imagenUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return _ShimmerPlaceholder(
                                      width: screenWidth * 0.32,
                                      height: usableHeight * 0.14,
                                      borderRadius: screenWidth * 0.025,
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackCover(
                                    title: evento.titulo,
                                    dia: evento.dia,
                                    mes: evento.mes,
                                    textColor: textColor,
                                    coverBg: coverBg,
                                    screenWidth: screenWidth,
                                  ),
                            )
                          : _buildFallbackCover(
                              title: evento.titulo,
                              dia: evento.dia,
                              mes: evento.mes,
                              textColor: textColor,
                              coverBg: coverBg,
                              screenWidth: screenWidth,
                            ),
                    ),
                  ),
                  // Insignia flotante con el día y mes
                  Positioned(
                    top: usableHeight * 0.008,
                    right: screenWidth * 0.015,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.018,
                        vertical: usableHeight * 0.003,
                      ),
                      decoration: BoxDecoration(
                        color: azulFondo.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.015,
                        ),
                      ),
                      child: Text(
                        '${evento.dia} ${evento.mes}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.022,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: usableHeight * 0.008),

            // Título
            Text(
              evento.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: azulFondo,
                fontSize: screenWidth * 0.030,
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
            ),
            SizedBox(height: usableHeight * 0.002),

            // Lugar / Expositor
            Text(
              evento.organizador,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: screenWidth * 0.024,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Componente: Fila vertical de próximo evento con bloque de calendario
  Widget _buildEventTile({
    required EventoModel evento,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.035),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        child: Row(
          children: [
            // Tarjeta de fecha estilo calendario
            Container(
              width: screenWidth * 0.13,
              height: screenWidth * 0.13,
              decoration: BoxDecoration(
                color: azulFondo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                border: Border.all(color: azulFondo.withValues(alpha: 0.12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    evento.dia,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.046,
                      fontWeight: FontWeight.bold,
                      height: 1.05,
                    ),
                  ),
                  Text(
                    evento.mes,
                    style: TextStyle(
                      color: amarilloOro,
                      fontSize: screenWidth * 0.026,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.035),

            // Detalles del evento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    evento.titulo,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.036,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: usableHeight * 0.004),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: screenWidth * 0.032,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Expanded(
                        child: Text(
                          evento.hora,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.028,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.002),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: screenWidth * 0.032,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Expanded(
                        child: Text(
                          evento.lugar,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.028,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: azulFondo,
              size: screenWidth * 0.055,
            ),
          ],
        ),
      ),
    );
  }

  // Fallback visual si falla la carga de red de imagen
  Widget _buildFallbackCover({
    required String title,
    required String dia,
    required String mes,
    required Color textColor,
    required Color coverBg,
    required double screenWidth,
  }) {
    return Container(
      color: coverBg,
      padding: EdgeInsets.all(screenWidth * 0.02),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dia $mes',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: screenWidth * 0.024,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: screenWidth * 0.022,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Modal Inferior de Detalle Rápido del Evento (Bottom Sheet moderno)
  void _showEventDetailsModal(BuildContext context, EventoModel evento) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final usableHeight = screenHeight - MediaQuery.of(context).padding.top;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final l10n = AppLocalizations.of(modalContext);

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
              // Indicador superior de arrastre
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

              // Cabecera: Imagen + Datos principales
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen amplia con sombra
                  Container(
                    width: screenWidth * 0.28,
                    height: usableHeight * 0.18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(2, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                      child: Image.network(
                        evento.imagenUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return _ShimmerPlaceholder(
                            width: screenWidth * 0.28,
                            height: usableHeight * 0.18,
                            borderRadius: screenWidth * 0.025,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Color(int.parse(evento.fallbackBgColor)),
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Text(
                              evento.titulo,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(
                                  int.parse(evento.fallbackTextColor),
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.045),

                  // Título, Organizador, Categoría, Fecha y Lugar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.025,
                            vertical: usableHeight * 0.004,
                          ),
                          decoration: BoxDecoration(
                            color: azulFondo.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.015,
                            ),
                          ),
                          child: Text(
                            _getCategoryName(modalContext, evento.categoria),
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.028,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.008),
                        Text(
                          evento.titulo,
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.046,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: usableHeight * 0.004),
                        Text(
                          evento.organizador,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.032,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.008),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: screenWidth * 0.034,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: screenWidth * 0.012),
                            Expanded(
                              child: Text(
                                '${evento.dia} ${evento.mes} · ${evento.hora}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: screenWidth * 0.028,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: usableHeight * 0.004),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: screenWidth * 0.034,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: screenWidth * 0.012),
                            Expanded(
                              child: Text(
                                evento.lugar,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: screenWidth * 0.028,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: usableHeight * 0.018),

              // Cupo y capacidad
              if (evento.cupoMaximo > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.disponibilidadCupos ?? 'Disponibilidad de cupos',
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.034,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${evento.cupoReservado} / ${evento.cupoMaximo}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.030,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: usableHeight * 0.006),
                ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  child: LinearProgressIndicator(
                    value: evento.porcentajeOcupacion,
                    minHeight: usableHeight * 0.008,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(amarilloOro),
                  ),
                ),
                SizedBox(height: usableHeight * 0.016),
              ],

              // Descripción
              if (evento.descripcion.isNotEmpty) ...[
                Text(
                  l10n?.detallesDelEvento ?? 'Detalles del evento',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: usableHeight * 0.006),
                Text(
                  evento.descripcion,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: screenWidth * 0.032,
                    height: 1.35,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: usableHeight * 0.02),
              ],

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: amarilloOro,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: usableHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.025,
                          ),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(modalContext);
                        await _cambiarInscripcion(evento);
                      },
                      icon: Icon(
                        Icons.check_circle_outline_rounded,
                        size: screenWidth * 0.045,
                      ),
                      label: Text(
                        evento.estaInscrito
                            ? (l10n?.yaEstasInscrito ?? 'Ya estás inscrito')
                            : (l10n?.inscribirmeAhora ?? 'Inscribirme ahora'),
                        style: TextStyle(
                          fontSize: screenWidth * 0.034,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: azulFondo,
                      side: BorderSide(color: azulFondo, width: 1.2),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: usableHeight * 0.015,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.025,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n?.eventoAgregadoAgendaLocal(evento.titulo) ??
                                'Evento "${evento.titulo}" agregado a tu agenda local.',
                          ),
                          backgroundColor: azulFondo,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: screenWidth * 0.05,
                      color: azulFondo,
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

// Widget Shimmer animado para efecto de carga elegante sin dependencias externas
class _ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerPlaceholder({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-2.0 + (_controller.value * 4), -0.5),
              end: Alignment(-0.5 + (_controller.value * 4), 0.5),
              colors: const [
                Color(0xFFE2E6EC),
                Color(0xFFF2F4F8),
                Color(0xFFE2E6EC),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.event_seat_rounded,
              color: Color(0xFFC4CBD4),
              size: 24,
            ),
          ),
        );
      },
    );
  }
}
