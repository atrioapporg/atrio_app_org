import 'package:atrio/widgets/hero_banner_card.dart';
import 'package:flutter/material.dart';

class VideosTransmisionesScreen extends StatefulWidget {
  static const routeName = 'videos_transmisiones_screen';

  const VideosTransmisionesScreen({super.key});

  @override
  State<VideosTransmisionesScreen> createState() =>
      _VideosTransmisionesScreenState();
}

class _VideosTransmisionesScreenState extends State<VideosTransmisionesScreen> {
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'En vivo',
    'Prédicas',
    'Estudios',
    'Música',
  ];

  final List<Map<String, dynamic>> _videosList = [
    {
      'title': 'Culto dominical',
      'schedule': 'Domingo · 10:00 a. m.',
      'church': 'Iglesia Comunidad de Esperanza',
      'isLive': true,
      'duration': null,
      'speaker': null,
      'stats': null,
      'thumbIcon': Icons.person_rounded,
      'thumbBg': Color(0xFF1E2D3D),
    },
    {
      'title': 'La fe que mueve montañas',
      'schedule': null,
      'church': null,
      'isLive': false,
      'duration': '45:32',
      'speaker': 'Pastor Andrés Gómez',
      'stats': 'Ayer · 1,230 vistas',
      'thumbIcon': Icons.menu_book_rounded,
      'thumbBg': Color(0xFF5D4037),
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Obtención de métricas relativas dinámicas (Flutter 3.22+)
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
              // 2. Encabezado Superior (Logo + Campana + Título con Botón Volver)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: usableHeight * 0.01),
                    // Fila superior: Logo y Campana con notificación
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: screenWidth * 0.075,
                              height: usableHeight * 0.04,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: amarilloOro,
                                  width: screenWidth * 0.004,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(screenWidth * 0.035),
                                  topRight: Radius.circular(
                                    screenWidth * 0.035,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.add,
                                  color: amarilloOro,
                                  size: screenWidth * 0.045,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'A T R I O',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.028,
                                letterSpacing: screenWidth * 0.008,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        // Campana con punto de alerta
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: screenWidth * 0.075,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: screenWidth * 0.025,
                                height: screenWidth * 0.025,
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
                    SizedBox(height: usableHeight * 0.015),

                    // Título de la pantalla con botón de retroceso (Back <-)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.085,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Expanded(
                          child: Text(
                            'Videos y\ntransmisiones',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.068,
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.015),

                    // Banner Hero: Culto en vivo (en el encabezado oscuro)
                    //
                    HeroBannerCard(
                      title: 'Culto en vivo',
                      subtitle: 'Domingo · 10:00 a. m.',
                      buttonText: 'Ver ahora',
                      backgroundImage: 'assets/images/biblia3.jpg',
                      watermarkIcon: Icons.add,
                      onButtonPressed: () {
                        // Acción para reproducir transmisión
                      },
                    ),
                    //
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: usableHeight * 0.025,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pastillas de Categorías (Pills)
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
                                      horizontal: screenWidth * 0.05,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? azulFondo
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        screenWidth * 0.03,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? azulFondo
                                            : grisBorde,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _categories[index],
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          fontSize: screenWidth * 0.034,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // Lista de Tarjetas de Videos y Transmisiones
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _videosList.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: usableHeight * 0.015),
                            itemBuilder: (context, index) {
                              final item = _videosList[index];
                              return _buildVideoCard(
                                item: item,
                                screenWidth: screenWidth,
                                usableHeight: usableHeight,
                                azulFondo: azulFondo,
                                amarilloOro: amarilloOro,
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

  // Componente: Tarjeta de Video / Transmisión
  Widget _buildVideoCard({
    required Map<String, dynamic> item,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
    required VoidCallback onTap,
  }) {
    final bool isLive = item['isLive'] as bool;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          border: Border.all(color: grisBorde),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Miniatura del video
            Container(
              width: screenWidth * 0.32,
              height: usableHeight * 0.19,
              decoration: BoxDecoration(
                color: item['thumbBg'] as Color,
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      item['thumbIcon'] as IconData,
                      color: Colors.white38,
                      size: screenWidth * 0.12,
                    ),
                  ),
                  // Badge: EN VIVO o Tiempo de duración
                  Positioned(
                    bottom: usableHeight * 0.008,
                    left: isLive ? screenWidth * 0.02 : null,
                    right: isLive ? null : screenWidth * 0.02,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: usableHeight * 0.003,
                      ),
                      decoration: BoxDecoration(
                        color: isLive ? amarilloOro : Colors.black87,
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.012,
                        ),
                      ),
                      child: Text(
                        isLive ? 'EN VIVO' : (item['duration'] as String),
                        style: TextStyle(
                          color: isLive ? azulFondo : Colors.white,
                          fontSize: screenWidth * 0.024,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.035),

            // Información del Video
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: usableHeight * 0.004),
                  if (isLive) ...[
                    Text(
                      item['schedule'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.028,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.002),
                    Text(
                      item['church'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.028,
                      ),
                    ),
                  ] else ...[
                    Text(
                      item['speaker'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.028,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.002),
                    Text(
                      item['stats'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.028,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Menú de 3 puntos
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: azulFondo,
                size: screenWidth * 0.055,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
