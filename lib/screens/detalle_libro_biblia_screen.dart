import 'package:atrio/servicios/bible_service.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class DetalleLibroBibliaScreen extends StatefulWidget {
  static const routeName = 'detalle_libro_biblia_screen';

  const DetalleLibroBibliaScreen({super.key});

  @override
  State<DetalleLibroBibliaScreen> createState() =>
      _DetalleLibroBibliaScreenState();
}

class _DetalleLibroBibliaScreenState extends State<DetalleLibroBibliaScreen> {
  bool _isCapitulosTab = true;
  bool _isBookmarkActive = false;
  final BibleService _bibleService = BibleService();
  Future<Map<String, String>>? _infoLibroFuture;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final Map<String, dynamic> args =
          (ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?) ??
          {};
      final String nombreLibro = args['nombre'] ?? 'Génesis';

      // Inicializamos la petición a la API
      _infoLibroFuture = _bibleService.obtenerInfoLibro(nombreLibro);
      _isInit = false;
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

    final l10n = AppLocalizations.of(context);
    final Map<String, dynamic> args =
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ??
        {};

    final String nombreLibro =
        args['nombre'] ?? (l10n?.libroGenesis ?? 'Génesis');
    final int totalCapitulos = args['capitulos'] ?? 50;
    final String subtitulo = args['subtitulo'] ?? '';
    final Color colorIcono = args['color'] ?? const Color(0xFF4CAF50);
    final IconData icono = args['icon'] ?? Icons.menu_book_rounded;
    final String textoCapitulos = totalCapitulos == 1
        ? (l10n?.unCapitulo ?? '1 capítulo')
        : (l10n?.totalCapitulos('$totalCapitulos') ?? '$totalCapitulos capítulos');

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // Encabezado Superior
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.015,
                ),
                child: Row(
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
                    Container(
                      width: screenWidth * 0.11,
                      height: screenWidth * 0.11,
                      decoration: BoxDecoration(
                        color: colorIcono,
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.025,
                        ),
                      ),
                      child: Icon(
                        icono,
                        color: Colors.white,
                        size: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.035),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreLibro,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            textoCapitulos,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.032,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isBookmarkActive = !_isBookmarkActive;
                        });
                      },
                      icon: Icon(
                        _isBookmarkActive
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: _isBookmarkActive ? amarilloOro : Colors.white,
                        size: screenWidth * 0.07,
                      ),
                    ),
                  ],
                ),
              ),

              // Contenedor Blanco Inferior
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
                    child: Column(
                      children: [
                        // Tabs: Capítulos / Información
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: grisBorde, width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildTabItem(
                                title: l10n?.capitulosTab ?? 'Capítulos',
                                isSelected: _isCapitulosTab,
                                screenWidth: screenWidth,
                                usableHeight: usableHeight,
                                azulFondo: azulFondo,
                                onTap: () =>
                                    setState(() => _isCapitulosTab = true),
                              ),
                              _buildTabItem(
                                title: l10n?.informacionTab ?? 'Información',
                                isSelected: !_isCapitulosTab,
                                screenWidth: screenWidth,
                                usableHeight: usableHeight,
                                azulFondo: azulFondo,
                                onTap: () =>
                                    setState(() => _isCapitulosTab = false),
                              ),
                            ],
                          ),
                        ),

                        // Renderizado de Lista o Información Dinámica
                        Expanded(
                          child: _isCapitulosTab
                              ? ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.05,
                                    vertical: usableHeight * 0.015,
                                  ),
                                  itemCount: totalCapitulos,
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                        color: grisBorde,
                                        height: 1,
                                      ),
                                  itemBuilder: (context, index) {
                                    final int numCapitulo = index + 1;
                                    return _buildChapterTile(
                                      chapterNumber: numCapitulo,
                                      title: l10n?.capituloNumero('$numCapitulo') ??
                                          'Capítulo $numCapitulo',
                                      screenWidth: screenWidth,
                                      usableHeight: usableHeight,
                                      azulFondo: azulFondo,
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          'lectura_capitulo_screen', // Llama a la ruta nueva
                                          arguments: {
                                            'id': args['id'], // Asumiendo que guardaste el ID del libro en variables arriba
                                            'nombre': nombreLibro,
                                            'capitulos': totalCapitulos,
                                            'capitulo': numCapitulo, // El número de capítulo tocado
                                            'subtitulo':
                                                subtitulo, // Título temático
                                          },
                                        );
                                      },
                                    );
                                  },
                                )
                              : _buildInfoTab(
                                  screenWidth,
                                  usableHeight,
                                  azulFondo,
                                  l10n,
                                ),
                        ),
                      ],
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

  Widget _buildTabItem({
    required String title,
    required bool isSelected,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: usableHeight * 0.018),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? azulFondo : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? azulFondo : Colors.grey.shade600,
                fontSize: screenWidth * 0.038,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChapterTile({
    required int chapterNumber,
    required String title,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: usableHeight * 0.016,
            horizontal: screenWidth * 0.02,
          ),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.09,
                height: screenWidth * 0.09,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Center(
                  child: Text(
                    '$chapterNumber',
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: screenWidth * 0.055,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pestaña de información dinámica consumida vía API
  Widget _buildInfoTab(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    AppLocalizations? l10n,
  ) {
    return FutureBuilder<Map<String, String>>(
      future: _infoLibroFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE5A023)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Text(
                l10n?.errorCargarInfoLibro ??
                    'No se pudo cargar la información de la API.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: screenWidth * 0.036,
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(screenWidth * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.acercaDelLibro ?? 'Acerca del libro',
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.050,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: usableHeight * 0.015),
              Text(
                data['descripcion']!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: screenWidth * 0.060,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
