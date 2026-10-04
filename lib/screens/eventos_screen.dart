import 'package:flutter/material.dart';

class EventosScreen extends StatefulWidget {
  static const routeName = 'eventos_screen';
  const EventosScreen({super.key});

  @override
  State createState() => _EventosScreenState();
}

class _EventosScreenState extends State {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  final List _categories = [
    'Todos',
    'Jóvenes',
    'Familias',
    'Estudios',
    'Retiros',
  ];
  final List<Map<String, dynamic>> _upcomingEvents = [
    {
      'day': '15',
      'month': 'OCT',
      'title': 'Noche de Adoración y Alabanza',
      'time': 'Viernes · 7:30 p. m.',
      'location': 'Templo Principal',
      'iconColor': const Color(0xFF0055A5),
    },
    {
      'day': '22',
      'month': 'OCT',
      'title': 'Reunión de Jóvenes: "Con Propósito"',
      'time': 'Sábado · 6:00 p. m.',
      'location': 'Salón Anexo',
      'iconColor': const Color(0xFFE5A023),
    },
    {
      'day': '05',
      'month': 'NOV',
      'title': 'Bautismos en Agua',
      'time': 'Domingo · 10:00 a. m.',
      'location': 'Iglesia Comunidad de Esperanza',
      'iconColor': const Color(0xFF4A7C59),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              // Encabezado Superior Optimizado
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.012,
                ),
                child: Column(
                  children: [
                    // Fila 1: Back + Título + Logo + Notificaciones
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.018),
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
                        SizedBox(width: screenWidth * 0.025),
                        Text(
                          'Eventos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.058,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),

                        SizedBox(width: screenWidth * 0.03),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.018),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: screenWidth * 0.058,
                              ),
                            ),
                            Positioned(
                              top: screenWidth * 0.015,
                              right: screenWidth * 0.015,
                              child: Container(
                                width: screenWidth * 0.022,
                                height: screenWidth * 0.022,
                                decoration: const BoxDecoration(
                                  color: amarilloOro,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.014),
                    // Fila 2: Buscador moderno con sombra y acción de borrado
                    Container(
                      height: usableHeight * 0.052,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.035,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.037,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar actividades y eventos...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: screenWidth * 0.035,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: azulFondo,
                            size: screenWidth * 0.052,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.cancel_rounded,
                                    color: Colors.grey.shade400,
                                    size: screenWidth * 0.048,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
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
                    SizedBox(height: usableHeight * 0.006),
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
                        vertical: usableHeight * 0.022,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filtros de categoría en pastillas (Pills)
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
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.048,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? azulFondo
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        screenWidth * 0.05,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? azulFondo
                                            : grisBorde,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: azulFondo.withValues(
                                                  alpha: 0.18,
                                                ),
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        _categories[index],
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          fontSize: screenWidth * 0.033,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // Título "Evento Destacado"
                          Text(
                            'Evento destacado',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.048,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // Tarjeta de Evento Destacado
                          _buildFeaturedEventCard(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            amarilloOro: amarilloOro,
                            grisBorde: grisBorde,
                            onTap: () {},
                          ),
                          SizedBox(height: usableHeight * 0.03),

                          // Título "Próximos eventos"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Próximos eventos',
                                style: TextStyle(
                                  color: azulFondo,
                                  fontSize: screenWidth * 0.055,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Ver calendario',
                                  style: TextStyle(
                                    color: const Color(0xFF0055A5),
                                    fontSize: screenWidth * 0.034,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // Lista de Próximos Eventos
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _upcomingEvents.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: usableHeight * 0.015),
                            itemBuilder: (context, index) {
                              final event = _upcomingEvents[index];
                              return _buildEventTile(
                                day: event['day']!,
                                month: event['month']!,
                                title: event['title']!,
                                time: event['time']!,
                                location: event['location']!,
                                iconColor: event['iconColor'] as Color,
                                screenWidth: screenWidth,
                                usableHeight: usableHeight,
                                azulFondo: azulFondo,
                                grisBorde: grisBorde,
                                onTap: () {},
                              );
                            },
                          ),
                          SizedBox(height: usableHeight * 0.02),
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

  // Componente: Tarjeta de Evento Destacado
  Widget _buildFeaturedEventCard({
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
        width: screenWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.045),
          border: Border.all(color: grisBorde),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: usableHeight * 0.18,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFD6E4EB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenWidth * 0.04),
                  topRight: Radius.circular(screenWidth * 0.04),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.festival_outlined,
                      color: azulFondo.withValues(alpha: 0.3),
                      size: screenWidth * 0.18,
                    ),
                  ),
                  Positioned(
                    top: usableHeight * 0.015,
                    left: screenWidth * 0.04,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: usableHeight * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: amarilloOro,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: Text(
                        'DESTACADO',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.026,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Retiro de Familias 2026',
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.048,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.008),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.grey.shade600,
                        size: screenWidth * 0.045,
                      ),
                      SizedBox(width: screenWidth * 0.015),
                      Text(
                        '28 - 30 de Noviembre',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth * 0.032,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.005),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey.shade600,
                        size: screenWidth * 0.045,
                      ),
                      SizedBox(width: screenWidth * 0.015),
                      Text(
                        'Campamento Los Pinos',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth * 0.032,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.018),
                  SizedBox(
                    width: double.infinity,
                    height: usableHeight * 0.055,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulFondo,
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
                        'Inscribirse ahora',
                        style: TextStyle(
                          fontSize: screenWidth * 0.048,
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

  // Componente: Fila de Próximo Evento
  Widget _buildEventTile({
    required String day,
    required String month,
    required String title,
    required String time,
    required String location,
    required Color iconColor,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
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
            Container(
              width: screenWidth * 0.14,
              height: screenWidth * 0.14,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    month,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: screenWidth * 0.026,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: usableHeight * 0.005),
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.03,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.002),
                  Text(
                    location,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.03,
                    ),
                    overflow: TextOverflow.ellipsis,
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
}
