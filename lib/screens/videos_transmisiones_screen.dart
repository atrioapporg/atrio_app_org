import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../modelos/auth_permissions.dart';
import '../modelos/video_model.dart';
import '../providers/admin_provider.dart';
import '../widgets/permission_guard.dart';
import '../widgets/reproductor_streaming_modal.dart';
import 'crear_predica_screen.dart';

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

  String _getLocalizedCategory(String category, AppLocalizations? l10n) {
    switch (category.toLowerCase()) {
      case 'todos':
        return l10n?.categoriaTodos ?? 'Todos';
      case 'en vivo':
        return l10n?.categoriaEnVivo ?? 'En vivo';
      case 'prédicas':
      case 'predicas':
        return l10n?.categoriaPredicas ?? 'Prédicas';
      case 'estudios':
        return l10n?.categoriaEstudios ?? 'Estudios';
      case 'música':
      case 'musica':
        return l10n?.categoriaMusica ?? 'Música';
      default:
        return category;
    }
  }

  // Video / Transmisión destacada principal (preparada para Odoo 19)
  final VideoModel _featuredLiveVideo = VideoModel(
    id: '1',
    titulo: 'Culto Dominical en Vivo',
    canalOIglesia: 'Atrio Iglesia (@AtrioIglesia)',
    predicador: 'Pastor de la Comunidad',
    thumbnailUrl: 'https://img.youtube.com/vi/uE53d7_-Unc/maxresdefault.jpg',
    videoUrl: 'https://youtu.be/s6ixxFXO6vc',
    categoria: 'En vivo',
    sinopsis: 'Acompáñanos en la transmisión en directo del canal oficial de YouTube @AtrioIglesia (ID: UCuW2ZM9B8MEm5FiKBQENjTw). Tiempo de alabanza congregacional, adoración comunitaria y la Palabra de Dios.',
    esEnVivo: true,
    horario: 'Domingo · 10:00 a. m.',
    estadisticas: '1,450 conectados',
    esDestacado: true,
  );

  // Catálogo inicial de 4 videos (total 5 videos con el destacado)
  late final List<VideoModel> _videosList = [
    VideoModel(
      id: '2',
      titulo: 'El ORIGEN de MOISÉS',
      canalOIglesia: 'Atrio Iglesia (@AtrioIglesia)',
      predicador: 'Pastor Andrés Gómez',
      thumbnailUrl: 'https://www.infobae.com/resizer/v2/https%3A%2F%2Fs3.amazonaws.com%2Farc-wordpress-client-uploads%2Finfobae-wp%2Fwp-content%2Fuploads%2F2016%2F11%2F26170514%2FMoises-sf-1.jpg?auth=d34b3503640161fb9119ab9a811445b05a5103b1ddd5f84639a725b40928483b&smart=true&width=992&height=766&quality=85',
      videoUrl: 'https://www.youtube.com/watch?v=UJ7O2Fd4v3M',
      categoria: 'Prédicas',
      sinopsis: 'La palabra de Dios ha sido la guía moral y espiritual del mundo occidental desde hace milenios. Sin embargo, el mensaje divino nos llegó a través de intermediarios. ¿Quiénes fueron los elegidos para traer el mensaje de Dios hacia nosotros?',
      esEnVivo: true,
      horario: 'En vivo ahora',
      estadisticas: '420 en vivo',
      fallbackBgColor: '0xFF1E2D3D',
    ),
    VideoModel(
      id: '4',
      titulo: 'EL LIBRO DE ENOC, LA BIBLIA PROHIBIDAs',
      canalOIglesia: 'Instituto Teológico Atrio',
      predicador: 'Dr. Carlos Morales',
      thumbnailUrl: 'https://images.unsplash.com/photo-1504052434569-70ad5836ab65?auto=format&fit=crop&w=640&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=rjzzHbcmezc',
      categoria: 'Estudios',
      sinopsis: 'Un análisis exegético y teológico versículo a versículo acerca de la justificación por la fe, la soberanía divina y la gracia redentora en Romanos.',
      esEnVivo: false,
      duracion: '58:14',
      estadisticas: 'Hace 3 días · 2,850 vistas',
      fallbackBgColor: '0xFF2E4057',
    ),
    VideoModel(
      id: '5',
      titulo: 'La segunda venida de Jesús',
      canalOIglesia: 'Atrio Worship Band',
      predicador: 'Banda de Alabanza',
      thumbnailUrl: 'https://pensamientopentecostalarminiano.org/wp-content/uploads/2018/11/image_search_15911480031595573924258383821966.jpg?w=768&h=439',
      videoUrl: 'https://www.youtube.com/watch?v=y1VFPMoryFU',
      categoria: 'Música',
      sinopsis: 'El Apocalipsis. El libro más impresionante y extremo de la Biblia. Un texto sagrado que profetiza el final de los tiempos.',
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

  /// Despliega el formulario de publicación de prédica o transmisión en vivo (exclusivo church_admin).
  Future<void> _abrirFormularioCrearPredica() async {
    final result = await Navigator.pushNamed(
      context,
      CrearPredicaScreen.routeName,
    );
    if (!mounted) return;
    if (result == true) {
      final adminProvider = context.read<AdminProvider>();
      await adminProvider.loadAdminSermons();
    }
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
    final l10n = AppLocalizations.of(context);

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
      floatingActionButton: PermissionGuard(
        requireChurchAdmin: true,
        requiredPermission: AppPermissions.managePosts,
        disallowReadOnly: true,
        child: FloatingActionButton.extended(
          onPressed: _abrirFormularioCrearPredica,
          backgroundColor: amarilloOro,
          foregroundColor: azulFondo,
          icon: const Icon(Icons.live_tv_rounded, fontWeight: FontWeight.bold),
          label: Text(
            '+ Transmitir / Prédica',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.034,
            ),
          ),
        ),
      ),
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
                    // Título de la pantalla con botón de retroceso (Back <-) y acción de Admin
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Tooltip(
                            message: l10n?.volver ?? 'Volver',
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
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            l10n?.videosYTransmisiones ??
                                'Videos y transmisiones',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        PermissionGuard(
                          requireChurchAdmin: true,
                          requiredPermission: AppPermissions.managePosts,
                          disallowReadOnly: true,
                          child: GestureDetector(
                            onTap: _abrirFormularioCrearPredica,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.03,
                                vertical: usableHeight * 0.008,
                              ),
                              decoration: BoxDecoration(
                                color: amarilloOro,
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.03,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: azulFondo,
                                    size: screenWidth * 0.042,
                                  ),
                                  SizedBox(width: screenWidth * 0.012),
                                  Text(
                                    '+ Prédica',
                                    style: TextStyle(
                                      color: azulFondo,
                                      fontSize: screenWidth * 0.030,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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
                          hintText:
                              l10n?.buscarVideosPlaceholder ??
                              'Buscar prédicas, canales o temas...',
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
                      l10n: l10n,
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
                                        _getLocalizedCategory(
                                          _categories[index],
                                          l10n,
                                        ),
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
                                          l10n?.noSeEncontraronVideosCategoria ?? 'No se encontraron videos en esta categoría',
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
                                      l10n: l10n,
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
    AppLocalizations? l10n,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth,
        height: usableHeight * 0.22,
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
                    height: usableHeight * 0.22,
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
                  vertical: usableHeight * 0.012,
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
                          Text(
                            l10n?.enVivoBadge ?? 'EN VIVO',
                            style: const TextStyle(
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
                                l10n?.verAhora ?? 'Ver ahora',
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
    AppLocalizations? l10n,
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
                                  ? (l10n?.enVivoBadge ?? 'EN VIVO')
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

  // Modal Inferior de Reproducción Embebida (youtube_player_flutter) y Detalle de Streaming
  void _showVideoDetailsModal(BuildContext context, VideoModel video) {
    ReproductorStreamingModal.mostrar(context, video: video);
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
