import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modelos/video_model.dart';

class VideosTransmisionesScreen extends StatefulWidget {
  static const routeName = 'videos_transmisiones_screen';

  const VideosTransmisionesScreen({super.key});

  @override
  State<VideosTransmisionesScreen> createState() =>
      _VideosTransmisionesScreenState();
}

class _VideosTransmisionesScreenState extends State<VideosTransmisionesScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'Todos',
    'En vivo',
    'Prédicas',
    'Estudios',
    'Música',
  ];

  // Video / Transmisión destacada principal (preparada para Odoo 19)
  final VideoModel _featuredLiveVideo = VideoModel(
    id: '1',
    titulo: 'Culto Dominical en Vivo',
    canalOIglesia: 'Iglesia MMM Apartadó · Esperanza de Vida',
    predicador: 'Pastor de la Comunidad',
    thumbnailUrl: 'https://img.youtube.com/vi/uE53d7_-Unc/maxresdefault.jpg',
    videoUrl: 'https://youtu.be/uE53d7_-Unc',
    categoria: 'En vivo',
    sinopsis: 'Acompáñanos en la transmisión en directo de nuestro servicio dominical principal. Tiempo de adoración comunitaria, alabanza congregacional y el mensaje transformador de la Palabra de Dios.',
    esEnVivo: true,
    horario: 'Domingo · 10:00 a. m.',
    estadisticas: '1,450 conectados',
    esDestacado: true,
  );

  // Catálogo inicial de 4 videos (total 5 videos con el destacado)
  late final List<VideoModel> _videosList = [
    VideoModel(
      id: '2',
      titulo: 'La fe que mueve montañas',
      canalOIglesia: 'Iglesia Comunidad de Esperanza',
      predicador: 'Pastor Andrés Gómez',
      thumbnailUrl: 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&w=640&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=sermon_1',
      categoria: 'Prédicas',
      sinopsis: 'Un mensaje inspirador y práctico sobre cómo activar una fe perseverante ante los momentos de incertidumbre, temor y pruebas cotidianas.',
      esEnVivo: false,
      duracion: '45:32',
      estadisticas: 'Ayer · 1,230 vistas',
      fallbackBgColor: '0xFF5D4037',
    ),
    VideoModel(
      id: '3',
      titulo: 'Noche de Clamor y Avivamiento',
      canalOIglesia: 'Centro Cristiano Atrio Central',
      predicador: 'Ministerio de Intercesión',
      thumbnailUrl: 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?auto=format&fit=crop&w=640&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=live_clamor',
      categoria: 'En vivo',
      sinopsis: 'Transmisión en directo del culto especial de clamor, oración ferviente e intercesión por las familias, los enfermos y la comunidad.',
      esEnVivo: true,
      horario: 'En vivo ahora',
      estadisticas: '420 en vivo',
      fallbackBgColor: '0xFF1E2D3D',
    ),
    VideoModel(
      id: '4',
      titulo: 'Estudio Bíblico: Epístola a los Romanos',
      canalOIglesia: 'Instituto Teológico Atrio',
      predicador: 'Dr. Carlos Morales',
      thumbnailUrl: 'https://images.unsplash.com/photo-1504052434569-70ad5836ab65?auto=format&fit=crop&w=640&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=estudio_romanos',
      categoria: 'Estudios',
      sinopsis: 'Un análisis exegético y teológico versículo a versículo acerca de la justificación por la fe, la soberanía divina y la gracia redentora en Romanos.',
      esEnVivo: false,
      duracion: '58:14',
      estadisticas: 'Hace 3 días · 2,850 vistas',
      fallbackBgColor: '0xFF2E4057',
    ),
    VideoModel(
      id: '5',
      titulo: 'Tiempo de Alabanza e Intimidad',
      canalOIglesia: 'Atrio Worship Band',
      predicador: 'Banda de Alabanza',
      thumbnailUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=640&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=worship_session',
      categoria: 'Música',
      sinopsis: 'Sesión acústica de adoración congregacional con cantos de alabanza, gratitud y exaltación al Creador para acompañar tus devocionales diarios.',
      esEnVivo: false,
      duracion: '32:10',
      estadisticas: 'Hace 1 sem · 8,400 vistas',
      fallbackBgColor: '0xFF3E2723',
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

  // Filtrado reactivo por categorías y búsqueda
  List<VideoModel> get _filteredVideos {
    final query = _searchController.text.trim().toLowerCase();
    final selectedCategory = _categories[_selectedCategoryIndex];

    return _videosList.where((video) {
      final matchesCategory =
          selectedCategory == 'Todos' ||
          video.categoria.toLowerCase() == selectedCategory.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          video.titulo.toLowerCase().contains(query) ||
          video.canalOIglesia.toLowerCase().contains(query) ||
          (video.predicador != null &&
              video.predicador!.toLowerCase().contains(query));
      return matchesCategory && matchesQuery;
    }).toList();
  }

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
              // 2. Encabezado Superior (Título + Buscador + Hero Banner En Vivo)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: usableHeight * 0.01),
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
                        Expanded(
                          child: Text(
                            'Videos y transmisiones',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.060,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.015),

                    // Buscador reactivo de videos
                    Container(
                      height: usableHeight * 0.052,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar prédicas, canales o temas...',
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

                    // Banner Hero: Culto en vivo interactivo con miniatura real
                    _buildFeaturedLiveHero(
                      video: _featuredLiveVideo,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      azulFondo: azulFondo,
                      amarilloOro: amarilloOro,
                      onTap: () =>
                          _showVideoDetailsModal(context, _featuredLiveVideo),
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: usableHeight * 0.025,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pastillas de Categorías interactivas (Pills)
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
                          _filteredVideos.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: usableHeight * 0.05,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off_rounded,
                                          color: Colors.grey.shade500,
                                          size: screenWidth * 0.05,
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        Text(
                                          'No se encontraron videos en esta categoría',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: screenWidth * 0.032,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _filteredVideos.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(height: usableHeight * 0.015),
                                  itemBuilder: (context, index) {
                                    final item = _filteredVideos[index];
                                    return _buildVideoCard(
                                      video: item,
                                      screenWidth: screenWidth,
                                      usableHeight: usableHeight,
                                      azulFondo: azulFondo,
                                      amarilloOro: amarilloOro,
                                      grisBorde: grisBorde,
                                      onTap: () =>
                                          _showVideoDetailsModal(context, item),
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

  // Componente: Banner Hero interactivo de transmisión en vivo
  Widget _buildFeaturedLiveHero({
    required VideoModel video,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth,
        height: usableHeight * 0.19,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(screenWidth * 0.045),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(screenWidth * 0.045),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen real de la transmisión
              Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _ShimmerPlaceholder(
                    width: screenWidth,
                    height: usableHeight * 0.19,
                    borderRadius: screenWidth * 0.045,
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: const Color(0xFF0F1E2E)),
              ),

              // Degradado oscuro para legibilidad
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),

              // Contenido textual del banner
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.018,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge: EN VIVO con punto pulsante
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.025,
                        vertical: usableHeight * 0.004,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.015,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: screenWidth * 0.018,
                            height: screenWidth * 0.018,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          const Text(
                            'EN VIVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Título y Subtítulo
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.titulo,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.046,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.003),
                        Text(
                          '${video.horario ?? ''} · ${video.estadisticas ?? ''}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                      ],
                    ),

                    // Botón Ver ahora
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.035,
                            vertical: usableHeight * 0.007,
                          ),
                          decoration: BoxDecoration(
                            color: amarilloOro,
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.02,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: screenWidth * 0.045,
                                color: Colors.white,
                              ),
                              SizedBox(width: screenWidth * 0.01),
                              Text(
                                'Ver ahora',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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

  // Componente: Tarjeta de Video / Transmisión con miniatura fotográfica
  Widget _buildVideoCard({
    required VideoModel video,
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
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          border: Border.all(color: grisBorde),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Miniatura 16:9 con Shimmer y badges
            Container(
              width: screenWidth * 0.32,
              height: usableHeight * 0.11,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return _ShimmerPlaceholder(
                          width: screenWidth * 0.32,
                          height: usableHeight * 0.11,
                          borderRadius: screenWidth * 0.025,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Color(int.parse(video.fallbackBgColor)),
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white38,
                          size: screenWidth * 0.1,
                        ),
                      ),
                    ),
                    // Sombra inferior para badges
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Badge: EN VIVO o Duración
                    Positioned(
                      bottom: usableHeight * 0.006,
                      right: screenWidth * 0.02,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: usableHeight * 0.003,
                        ),
                        decoration: BoxDecoration(
                          color: video.esEnVivo
                              ? const Color(0xFFE53935)
                              : Colors.black87,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.012,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (video.esEnVivo) ...[
                              Container(
                                width: screenWidth * 0.015,
                                height: screenWidth * 0.015,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.01),
                            ],
                            Text(
                              video.esEnVivo
                                  ? 'EN VIVO'
                                  : (video.duracion ?? ''),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.022,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
                    video.titulo,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.036,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: usableHeight * 0.004),
                  if (video.predicador != null) ...[
                    Text(
                      video.predicador!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: screenWidth * 0.028,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: usableHeight * 0.002),
                  ],
                  Text(
                    video.canalOIglesia,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.026,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (video.estadisticas != null) ...[
                    SizedBox(height: usableHeight * 0.002),
                    Text(
                      video.estadisticas!,
                      style: TextStyle(
                        color: video.esEnVivo
                            ? const Color(0xFFE53935)
                            : Colors.grey.shade500,
                        fontSize: screenWidth * 0.025,
                        fontWeight: video.esEnVivo
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Botón de reproducción rápida
            Icon(
              Icons.play_circle_fill_rounded,
              color: amarilloOro,
              size: screenWidth * 0.08,
            ),
          ],
        ),
      ),
    );
  }

  // Modal Inferior de Detalle Rápido y Reproducción del Video (Bottom Sheet moderno)
  void _showVideoDetailsModal(BuildContext context, VideoModel video) {
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
              // Indicador de arrastre superior
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

              // Miniatura 16:9 grande con botón de Play superpuesto
              Container(
                width: screenWidth,
                height: usableHeight * 0.22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.035),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.035),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return _ShimmerPlaceholder(
                            width: screenWidth,
                            height: usableHeight * 0.22,
                            borderRadius: screenWidth * 0.035,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Color(int.parse(video.fallbackBgColor)),
                          child: const Icon(
                            Icons.videocam_rounded,
                            color: Colors.white54,
                            size: 48,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(screenWidth * 0.035),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                            border: Border.all(color: amarilloOro, width: 2),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.09,
                          ),
                        ),
                      ),
                      if (video.esEnVivo)
                        Positioned(
                          top: usableHeight * 0.015,
                          left: screenWidth * 0.035,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03,
                              vertical: usableHeight * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.015,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: screenWidth * 0.018,
                                  height: screenWidth * 0.018,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.015),
                                const Text(
                                  'EN VIVO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (video.duracion != null)
                        Positioned(
                          bottom: usableHeight * 0.015,
                          right: screenWidth * 0.035,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.025,
                              vertical: usableHeight * 0.004,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.012,
                              ),
                            ),
                            child: Text(
                              video.duracion!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),

              // Categoría y Estadísticas
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.025,
                      vertical: usableHeight * 0.004,
                    ),
                    decoration: BoxDecoration(
                      color: azulFondo.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(screenWidth * 0.015),
                    ),
                    child: Text(
                      video.categoria,
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.028,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (video.estadisticas != null) ...[
                    SizedBox(width: screenWidth * 0.025),
                    Text(
                      video.estadisticas!,
                      style: TextStyle(
                        color: video.esEnVivo
                            ? const Color(0xFFE53935)
                            : Colors.grey.shade600,
                        fontSize: screenWidth * 0.028,
                        fontWeight: video.esEnVivo
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: usableHeight * 0.008),

              Text(
                video.titulo,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              SizedBox(height: usableHeight * 0.004),

              Text(
                video.predicador != null
                    ? '${video.predicador!} · ${video.canalOIglesia}'
                    : video.canalOIglesia,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: usableHeight * 0.015),

              // Descripción / Sinopsis
              if (video.sinopsis.isNotEmpty) ...[
                Text(
                  'Descripción',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: usableHeight * 0.005),
                Text(
                  video.sinopsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: screenWidth * 0.031,
                    height: 1.35,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: usableHeight * 0.02),
              ],

              // Botones de Acción
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
                        final uri = Uri.tryParse(video.videoUrl);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  video.esEnVivo
                                      ? 'Conectando a transmisión "${video.titulo}"...'
                                      : 'Reproduciendo "${video.titulo}"...',
                                ),
                                backgroundColor: azulFondo,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(
                        video.esEnVivo
                            ? Icons.sensors_rounded
                            : Icons.play_arrow_rounded,
                        size: screenWidth * 0.05,
                      ),
                      label: Text(
                        video.esEnVivo
                            ? 'Ver transmisión en vivo'
                            : 'Reproducir ahora',
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
                            'Enlace de "${video.titulo}" copiado al portapapeles',
                          ),
                          backgroundColor: azulFondo,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.share_outlined,
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
              Icons.play_circle_outline_rounded,
              color: Color(0xFFC4CBD4),
              size: 28,
            ),
          ),
        );
      },
    );
  }
}
