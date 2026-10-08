import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../data/database_helper.dart';
import '../servicios/connectivity_service.dart';

class EscucharLibroBibliaScreen extends StatefulWidget {
  static const routeName = 'escuchar_libro_biblia_screen';

  const EscucharLibroBibliaScreen({super.key});

  @override
  State<EscucharLibroBibliaScreen> createState() =>
      _EscucharLibroBibliaScreenState();
}

class _EscucharLibroBibliaScreenState extends State<EscucharLibroBibliaScreen>
    with WidgetsBindingObserver {
  bool _isAntiguoTestamento = false;
  String _filtroBusqueda = '';
  final TextEditingController _searchController = TextEditingController();
  bool _mostrandoBuscador = false;

  YoutubePlayerController? _youtubeController;
  String _libroNombre = '';
  int _capituloActual = 1;

  final List<Map<String, dynamic>> _antiguoTestamento = [
    {
      'id': 1,
      'nombre': 'Génesis',
      'capitulos': 50,
      'color': const Color(0xFF4CAF50),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 2,
      'nombre': 'Éxodo',
      'capitulos': 40,
      'color': const Color(0xFFFF9800),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 3,
      'nombre': 'Levítico',
      'capitulos': 27,
      'color': const Color(0xFF29B6F6),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 4,
      'nombre': 'Números',
      'capitulos': 36,
      'color': const Color(0xFF5C6BC0),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 5,
      'nombre': 'Deuteronomio',
      'capitulos': 34,
      'color': const Color(0xFFAB47BC),
      'icon': Icons.book_rounded,
    },
    {
      'id': 6,
      'nombre': 'Josué',
      'capitulos': 24,
      'color': const Color(0xFF26A69A),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 7,
      'nombre': 'Jueces',
      'capitulos': 21,
      'color': const Color(0xFFFFB74D),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 8,
      'nombre': 'Rut',
      'capitulos': 4,
      'color': const Color(0xFF7E57C2),
      'icon': Icons.book_rounded,
    },
    {
      'id': 9,
      'nombre': '1 Samuel',
      'capitulos': 31,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 10,
      'nombre': '2 Samuel',
      'capitulos': 24,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 11,
      'nombre': '1 Reyes',
      'capitulos': 22,
      'color': const Color(0xFFFFA726),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 12,
      'nombre': '2 Reyes',
      'capitulos': 25,
      'color': const Color(0xFFFFA726),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 13,
      'nombre': '1 Crónicas',
      'capitulos': 29,
      'color': const Color(0xFF42A5F5),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 14,
      'nombre': '2 Crónicas',
      'capitulos': 36,
      'color': const Color(0xFF42A5F5),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 15,
      'nombre': 'Esdras',
      'capitulos': 10,
      'color': const Color(0xFF8D6E63),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 16,
      'nombre': 'Nehemías',
      'capitulos': 13,
      'color': const Color(0xFF8D6E63),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 17,
      'nombre': 'Ester',
      'capitulos': 10,
      'color': const Color(0xFFEC407A),
      'icon': Icons.book_rounded,
    },
    {
      'id': 18,
      'nombre': 'Job',
      'capitulos': 42,
      'color': const Color(0xFF78909C),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 19,
      'nombre': 'Salmos',
      'capitulos': 150,
      'color': const Color(0xFF26C6DA),
      'icon': Icons.music_note_rounded,
    },
    {
      'id': 20,
      'nombre': 'Proverbios',
      'capitulos': 31,
      'color': const Color(0xFFFFA726),
      'icon': Icons.lightbulb_rounded,
    },
    {
      'id': 21,
      'nombre': 'Eclesiastés',
      'capitulos': 12,
      'color': const Color(0xFF78909C),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 22,
      'nombre': 'Cantares',
      'capitulos': 8,
      'color': const Color(0xFFF06292),
      'icon': Icons.favorite_rounded,
    },
    {
      'id': 23,
      'nombre': 'Isaías',
      'capitulos': 66,
      'color': const Color(0xFFAB47BC),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 24,
      'nombre': 'Jeremías',
      'capitulos': 52,
      'color': const Color(0xFF5C6BC0),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 25,
      'nombre': 'Lamentaciones',
      'capitulos': 5,
      'color': const Color(0xFF5C6BC0),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 26,
      'nombre': 'Ezequiel',
      'capitulos': 48,
      'color': const Color(0xFF26A69A),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 27,
      'nombre': 'Daniel',
      'capitulos': 12,
      'color': const Color(0xFFFFA726),
      'icon': Icons.lightbulb_rounded,
    },
    {
      'id': 28,
      'nombre': 'Oseas',
      'capitulos': 14,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 29,
      'nombre': 'Joel',
      'capitulos': 3,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 30,
      'nombre': 'Amós',
      'capitulos': 9,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 31,
      'nombre': 'Abdías',
      'capitulos': 1,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 32,
      'nombre': 'Jonás',
      'capitulos': 4,
      'color': const Color(0xFF29B6F6),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 33,
      'nombre': 'Miqueas',
      'capitulos': 7,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 34,
      'nombre': 'Nahúm',
      'capitulos': 3,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 35,
      'nombre': 'Habacuc',
      'capitulos': 3,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 36,
      'nombre': 'Sofonías',
      'capitulos': 3,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 37,
      'nombre': 'Hageo',
      'capitulos': 2,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 38,
      'nombre': 'Zacarías',
      'capitulos': 14,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 39,
      'nombre': 'Malaquías',
      'capitulos': 4,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
  ];

  final List<Map<String, dynamic>> _nuevoTestamento = [
    {
      'id': 40,
      'nombre': 'Mateo',
      'capitulos': 28,
      'color': const Color(0xFF4CAF50),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 41,
      'nombre': 'Marcos',
      'capitulos': 16,
      'color': const Color(0xFFFF9800),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 42,
      'nombre': 'Lucas',
      'capitulos': 24,
      'color': const Color(0xFF29B6F6),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 43,
      'nombre': 'Juan',
      'capitulos': 21,
      'color': const Color(0xFFAB47BC),
      'icon': Icons.book_rounded,
    },
    {
      'id': 44,
      'nombre': 'Hechos',
      'capitulos': 28,
      'color': const Color(0xFFE53935),
      'icon': Icons.explore_rounded,
    },
    {
      'id': 45,
      'nombre': 'Romanos',
      'capitulos': 16,
      'color': const Color(0xFF5C6BC0),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 46,
      'nombre': '1 Corintios',
      'capitulos': 16,
      'color': const Color(0xFF26A69A),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 47,
      'nombre': '2 Corintios',
      'capitulos': 13,
      'color': const Color(0xFF26A69A),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 48,
      'nombre': 'Gálatas',
      'capitulos': 6,
      'color': const Color(0xFFFFA726),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 49,
      'nombre': 'Efesios',
      'capitulos': 6,
      'color': const Color(0xFF7E57C2),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 50,
      'nombre': 'Filipenses',
      'capitulos': 4,
      'color': const Color(0xFFEC407A),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 51,
      'nombre': 'Colosenses',
      'capitulos': 4,
      'color': const Color(0xFF42A5F5),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 52,
      'nombre': '1 Tesalonicenses',
      'capitulos': 5,
      'color': const Color(0xFF8D6E63),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 53,
      'nombre': '2 Tesalonicenses',
      'capitulos': 3,
      'color': const Color(0xFF8D6E63),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 54,
      'nombre': '1 Timoteo',
      'capitulos': 6,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 55,
      'nombre': '2 Timoteo',
      'capitulos': 4,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 56,
      'nombre': 'Tito',
      'capitulos': 3,
      'color': const Color(0xFF26C6DA),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 57,
      'nombre': 'Filemón',
      'capitulos': 1,
      'color': const Color(0xFF78909C),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 58,
      'nombre': 'Hebreos',
      'capitulos': 13,
      'color': const Color(0xFF5C6BC0),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 59,
      'nombre': 'Santiago',
      'capitulos': 5,
      'color': const Color(0xFFFFA726),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 60,
      'nombre': '1 Pedro',
      'capitulos': 5,
      'color': const Color(0xFF4CAF50),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 61,
      'nombre': '2 Pedro',
      'capitulos': 3,
      'color': const Color(0xFF4CAF50),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 62,
      'nombre': '1 Juan',
      'capitulos': 5,
      'color': const Color(0xFFAB47BC),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 63,
      'nombre': '2 Juan',
      'capitulos': 1,
      'color': const Color(0xFFAB47BC),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 64,
      'nombre': '3 Juan',
      'capitulos': 1,
      'color': const Color(0xFFAB47BC),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 65,
      'nombre': 'Judas',
      'capitulos': 1,
      'color': const Color(0xFFE53935),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 66,
      'nombre': 'Apocalipsis',
      'capitulos': 22,
      'color': const Color(0xFFD32F2F),
      'icon': Icons.wb_sunny_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _youtubeController?.pause();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_youtubeController != null && _youtubeController!.value.isPlaying) {
        _youtubeController?.pause();
      }
    }
  }

  // =========================================================
  // LOGICA DEL REPRODUCTOR CON SQLITE Y VALIDACION DE RED
  // =========================================================
  Future<void> _abrirReproductorYouTube(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
  ) async {
    // 1. Verificación previa de conexión a Internet real
    final tieneInternet = await ConnectivityService.instance.hasRealInternet();
    if (!tieneInternet) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC0392B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          content: Row(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'No hay conexión a internet para reproducir el audio.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // 2. Consulta a la Base de Datos de manera asíncrona
    final dataCapitulo = await DatabaseHelper.instance.getCapitulo(
      _libroNombre,
      _capituloActual,
    );

    // Verificamos si existe el libro/capítulo en la BD
    if (dataCapitulo == null ||
        dataCapitulo['video_id'] == null ||
        dataCapitulo['video_id'].toString().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: azulFondo,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          content: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: amarilloOro,
                size: screenWidth * 0.055,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'El audio dramatizado de $_libroNombre estará disponible próximamente.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // 3. Extraer valores exactos
    final String videoId = dataCapitulo['video_id'] as String;
    final int startSeconds = dataCapitulo['start_seconds'] as int;
    final int endSeconds = dataCapitulo['end_seconds'] as int;

    _youtubeController?.dispose();
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        hideControls: false,
        startAt: startSeconds,
        useHybridComposition: true,
      ),
    );

    bool capituloTerminado = false;
    VoidCallback? listenerCapitulo;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      builder: (ctx) {
        listenerCapitulo = () {
          if (_youtubeController == null || capituloTerminado) return;

          final int posicionActual =
              _youtubeController!.value.position.inSeconds;

          // Verifica finalización exacta desde SQLite
          if (posicionActual >= endSeconds && endSeconds > startSeconds) {
            capituloTerminado = true;
            _youtubeController?.pause();
            if (Navigator.canPop(ctx)) {
              Navigator.pop(ctx);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: azulFondo,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'Fin de la lectura de $_libroNombre $_capituloActual',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        };

        _youtubeController!.addListener(listenerCapitulo!);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.005,
                  vertical: usableHeight * 0.005,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.headphones_rounded,
                          color: amarilloOro,
                          size: screenWidth * 0.055,
                        ),
                        SizedBox(width: screenWidth * 0.007),
                        Text(
                          '$_libroNombre $_capituloActual (Audio)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.042,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
                aspectRatio: 16 / 6,
                progressIndicatorColor: amarilloOro,
                progressColors: const ProgressBarColors(
                  playedColor: Color(0xFFE5A023),
                  handleColor: Color(0xFFE5A023),
                  backgroundColor: Colors.white24,
                  bufferedColor: Colors.white10,
                ),
              ),
              SizedBox(height: usableHeight * 0.012),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (listenerCapitulo != null && _youtubeController != null) {
        _youtubeController?.removeListener(listenerCapitulo!);
      }
      _youtubeController?.pause();
      _youtubeController?.dispose();
      _youtubeController = null;
    });
  }

  // =========================================================
  // CARÁTULA DE CAPÍTULOS (BOTTOM SHEET)
  // =========================================================
  void _mostrarSelectorCapitulos(
    String nombreLibro,
    int totalCapitulos,
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.08),
        ),
      ),
      builder: (BuildContext ctx) {
        return SizedBox(
          height: usableHeight * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado de la Carátula (X, Título central, Botón Opciones)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.015),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.black87,
                          size: screenWidth * 0.06,
                        ),
                      ),
                    ),
                    Text(
                      'Libros',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.015),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.black87,
                        size: screenWidth * 0.06,
                      ),
                    ),
                  ],
                ),
              ),

              // Nombre del Libro
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Text(
                  nombreLibro,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),

              // Grid de Capítulos
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: screenWidth * 0.03,
                    mainAxisSpacing: screenWidth * 0.03,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: totalCapitulos + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.025,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: Colors.black87,
                            size: screenWidth * 0.06,
                          ),
                        ),
                      );
                    }

                    final int numeroCapitulo = index;
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        setState(() {
                          _libroNombre = nombreLibro;
                          _capituloActual = numeroCapitulo;
                        });

                        await _abrirReproductorYouTube(
                          screenWidth,
                          usableHeight,
                          azulFondo,
                          amarilloOro,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.025,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$numeroCapitulo',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: usableHeight * 0.02),
            ],
          ),
        );
      },
    );
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

    final listaBase = _isAntiguoTestamento
        ? _antiguoTestamento
        : _nuevoTestamento;
    final librosFiltrados = listaBase.where((libro) {
      final nombre = (libro['nombre'] as String).toLowerCase();
      return nombre.contains(_filtroBusqueda.toLowerCase());
    }).toList();

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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        Text(
                          'Escuchar Biblia',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _mostrandoBuscador = !_mostrandoBuscador;
                              if (!_mostrandoBuscador) {
                                _searchController.clear();
                                _filtroBusqueda = '';
                              }
                            });
                          },
                          icon: Icon(
                            _mostrandoBuscador
                                ? Icons.close
                                : Icons.search_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.07,
                          ),
                        ),
                      ],
                    ),
                    if (_mostrandoBuscador) ...[
                      SizedBox(height: usableHeight * 0.012),
                      Container(
                        height: usableHeight * 0.05,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (val) {
                            setState(() {
                              _filtroBusqueda = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Filtrar por nombre de libro...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: screenWidth * 0.035,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade600,
                              size: screenWidth * 0.05,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: usableHeight * 0.012,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                        SizedBox(height: usableHeight * 0.02),
                        // Switch de Pestañas
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                          ),
                          child: Container(
                            height: usableHeight * 0.055,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8ECEF),
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.03,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _isAntiguoTestamento = true,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _isAntiguoTestamento
                                            ? azulFondo
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          screenWidth * 0.025,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Antiguo Testamento',
                                          style: TextStyle(
                                            color: _isAntiguoTestamento
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.034,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _isAntiguoTestamento = false,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: !_isAntiguoTestamento
                                            ? azulFondo
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          screenWidth * 0.025,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Nuevo Testamento',
                                          style: TextStyle(
                                            color: !_isAntiguoTestamento
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.034,
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
                        SizedBox(height: usableHeight * 0.015),
                        // Lista de Libros
                        Expanded(
                          child: librosFiltrados.isEmpty
                              ? Center(
                                  child: Text(
                                    'No se encontraron libros',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: screenWidth * 0.038,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.05,
                                    vertical: usableHeight * 0.01,
                                  ),
                                  itemCount: librosFiltrados.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(height: usableHeight * 0.012),
                                  itemBuilder: (context, index) {
                                    final libro = librosFiltrados[index];
                                    return _buildBookTile(
                                      nombre: libro['nombre'] as String,
                                      capitulos: libro['capitulos'] as int,
                                      colorIcono: libro['color'] as Color,
                                      icono: libro['icon'] as IconData,
                                      screenWidth: screenWidth,
                                      usableHeight: usableHeight,
                                      azulFondo: azulFondo,
                                      amarilloOro: amarilloOro,
                                      grisBorde: grisBorde,
                                    );
                                  },
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

  Widget _buildBookTile({
    required String nombre,
    required int capitulos,
    required Color colorIcono,
    required IconData icono,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        border: Border.all(color: grisBorde),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          onTap: () {
            _mostrarSelectorCapitulos(
              nombre,
              capitulos,
              screenWidth,
              usableHeight,
              azulFondo,
              amarilloOro,
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: usableHeight * 0.014,
            ),
            child: Row(
              children: [
                Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    color: colorIcono.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  child: Icon(
                    icono,
                    color: colorIcono,
                    size: screenWidth * 0.065,
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.042,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.003),
                      Text(
                        '$capitulos capítulos',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.headphones_rounded,
                  color: Colors.grey.shade400,
                  size: screenWidth * 0.06,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
