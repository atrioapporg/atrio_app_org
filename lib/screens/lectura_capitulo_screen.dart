import 'dart:io';

import 'package:atrio/data/atrio_database_helper.dart';
import 'package:atrio/data/database_helper.dart'; // IMPORTANTE: Importamos el Helper que trae los tiempos del audio
import 'package:atrio/providers/biblia_provider.dart';
import 'package:atrio/servicios/bible_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LecturaCapituloScreen extends StatefulWidget {
  static const routeName = 'lectura_capitulo_screen';
  const LecturaCapituloScreen({super.key});

  @override
  State<LecturaCapituloScreen> createState() => _LecturaCapituloScreenState();
}

// Agregamos WidgetsBindingObserver para controlar la app en segundo plano
class _LecturaCapituloScreenState extends State<LecturaCapituloScreen>
    with WidgetsBindingObserver {
  final BibleService _bibleService = BibleService();

  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  bool _isInit = true;
  bool _isLoading = true;
  bool _isBookmarkActive = false;
  String? _errorMessage;
  YoutubePlayerController? _youtubeController;

  late int _libroId;
  late String _libroNombre;
  late int _capituloActual;
  late int _totalCapitulos;
  String _subtitulo = '';
  List<Map<String, dynamic>> _versiculos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _youtubeController?.pause();
    _youtubeController?.dispose();
    super.dispose();
  }

  // Pausa el audio si el usuario minimiza la app
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
          {};
      _libroId = args['id'] ?? 1;
      _libroNombre = args['nombre'] ?? 'Génesis';
      _capituloActual = args['capitulo'] ?? 1;
      _totalCapitulos = args['totalCapitulos'] ?? 50;
      _subtitulo = args['subtitulo'] ?? 'La creación';
      //
      AtrioDatabaseHelper.instance.guardarUltimaLectura(
        libro: _libroNombre,
        capitulo: _capituloActual,
        totalCapitulos: _totalCapitulos,
      );
      //
      _cargarCapitulo();
      _isInit = false;
    }
  }

  Future<void> _verificarSiEsFavorito() async {
    final esFav = await AtrioDatabaseHelper.instance.esFavorito(
      libro: _libroNombre,
      capitulo: _capituloActual,
    );
    if (mounted) {
      setState(() {
        _isBookmarkActive = esFav;
      });
    }
  }

  Future<void> _toggleFavorito() async {
    final nuevoEstado = await AtrioDatabaseHelper.instance.toggleFavorito(
      libro: _libroNombre,
      capitulo: _capituloActual,
      textoResumen: '$_libroNombre $_capituloActual - $_subtitulo',
    );

    if (mounted) {
      setState(() {
        _isBookmarkActive = nuevoEstado;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF072B4F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Text(
            nuevoEstado ? 'Añadido a favoritos' : 'Eliminado de favoritos',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _cargarCapitulo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final provider = Provider.of<BibliaProvider>(context, listen: false);
      final version = provider.versionActual;
      final data = await _bibleService.obtenerCapitulo(
        version,
        _libroNombre,
        _capituloActual,
      );
      if (mounted) {
        setState(() {
          _versiculos = data;
          _isLoading = false;
        });
        _verificarSiEsFavorito();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'No se pudo cargar el capítulo. Verifica tu conexión.';
          _isLoading = false;
        });
      }
    }
  }

  void _cambiarCapitulo(int nuevoCapitulo) {
    if (nuevoCapitulo >= 1 && nuevoCapitulo <= _totalCapitulos) {
      _youtubeController?.pause();
      setState(() {
        _capituloActual = nuevoCapitulo;
        _subtitulo = 'Capítulo $_capituloActual';
      });
      _cargarCapitulo();
    }
  }

  // =========================================================
  // LOGICA DEL REPRODUCTOR OPTIMIZADA CON SQLITE
  // =========================================================
  Future<void> _abrirReproductorYouTube(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
  ) async {
    // 1. VERIFICACIÓN DE INTERNET REAL
    final tieneInternet = await _hasRealInternet();

    if (!tieneInternet) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC0392B), // Rojo de alerta
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
      return; // Detenemos la ejecución aquí si no hay internet
    }

    // 2. Consulta a la Base de Datos para traer tiempos exactos
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

    // 3. Extraer valores exactos y limpios de la base de datos
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
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.015,
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
                        SizedBox(width: screenWidth * 0.025),
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
                      onPressed: () {
                        _youtubeController?.pause();
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
                aspectRatio: 16 / 6,
                progressIndicatorColor: amarilloOro,
                progressColors: ProgressBarColors(
                  playedColor: amarilloOro,
                  handleColor: amarilloOro,
                  backgroundColor: Colors.white24,
                  bufferedColor: Colors.white10,
                ),
              ),
              SizedBox(height: usableHeight * 0.025),
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

  String _obtenerTextoCapituloParaCompartir() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
      'Lectura Bíblica: $_libroNombre $_capituloActual ($_subtitulo)\n',
    );
    for (var verse in _versiculos) {
      final int numVerso = verse['verse'];
      final String texto = (verse['text'] as String)
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      buffer.writeln('$numVerso. $texto\n');
    }
    buffer.writeln('Compartido desde ATRIO App');
    return buffer.toString();
  }

  Future<void> _compartirPorCorreo() async {
    final String asunto = 'Lectura Bíblica: $_libroNombre $_capituloActual';
    final String cuerpo = _obtenerTextoCapituloParaCompartir();
    final String subjectEncoded = Uri.encodeComponent(asunto);
    final String bodyEncoded = Uri.encodeComponent(cuerpo)
        .replaceAll('%0A', '%0D%0A')
        .replaceAll('+', '%20');
    final Uri emailUri = Uri.parse(
      'mailto:?subject=$subjectEncoded&body=$bodyEncoded',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró una aplicación de correo configurada.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al compartir por correo: $e');
    }
  }

  Future<void> _compartirPorWhatsApp() async {
    final String texto = '📖 ${_obtenerTextoCapituloParaCompartir()}';
    final String textoCodificado = Uri.encodeComponent(texto);
    final Uri uri = Uri.parse('whatsapp://send?text=$textoCodificado');
    final Uri uriWeb = Uri.parse(
      'https://api.whatsapp.com/send?text=$textoCodificado',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uriWeb)) {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
        );
      }
    } catch (e) {
      debugPrint('Error al compartir en WhatsApp: $e');
    }
  }

  void _mostrarModalCrearNota(
    BuildContext context,
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
  ) {
    final TextEditingController notaController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF7F0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: screenWidth * 0.06,
            right: screenWidth * 0.06,
            top: usableHeight * 0.025,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: azulFondo,
                    size: screenWidth * 0.075,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      'Nueva nota en $_libroNombre $_capituloActual',
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: usableHeight * 0.018),
              TextField(
                controller: notaController,
                maxLines: 5,
                autofocus: true,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.04,
                ),
                decoration: InputDecoration(
                  hintText: 'Escribe tu reflexión o apunte aquí...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: screenWidth * 0.038,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.all(screenWidth * 0.04),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide(color: azulFondo, width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),
              SizedBox(
                width: double.infinity,
                height: usableHeight * 0.058,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amarilloOro,
                    foregroundColor: azulFondo,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                  ),
                  onPressed: () async {
                    if (notaController.text.trim().isEmpty) return;

                    await AtrioDatabaseHelper.instance.insertarNota(
                      libro: _libroNombre,
                      capitulo: _capituloActual,
                      contenido: notaController.text.trim(),
                    );

                    if (mounted && ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: azulFondo,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          content: const Text(
                            'Nota guardada correctamente',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Guardar nota',
                    style: TextStyle(
                      fontSize: screenWidth * 0.044,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.025),
            ],
          ),
        );
      },
    );
  }

  void _mostrarModalCompartir(
    BuildContext context,
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF7F0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: usableHeight * 0.025,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compartir $_libroNombre $_capituloActual',
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: usableHeight * 0.015),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.whatsapp,
                    size: screenWidth * 0.065,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                title: Text(
                  'WhatsApp',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.040,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _compartirPorWhatsApp();
                },
              ),
              const Divider(height: 1, color: Color(0xFFE5E5E5)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F0FA),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  child: Icon(Icons.mail_outline_rounded, color: azulFondo),
                ),
                title: Text(
                  'Correo electrónico',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.040,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _compartirPorCorreo();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  //
  //--------------------------------------

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color grisBorde = Color(0xFFE5E5E5);

    return Scaffold(
      backgroundColor: azulFondo,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirReproductorYouTube(
          screenWidth,
          usableHeight,
          azulFondo,
          amarilloOro,
        ),
        backgroundColor: azulFondo,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 35,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigationBar(
        screenWidth,
        usableHeight,
        azulFondo,
        amarilloOro,
        grisBorde,
      ),
      body: SafeArea(
        bottom: false,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.015,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$_libroNombre $_capituloActual',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.065,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.005),
                          Text(
                            _subtitulo,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.045,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _isBookmarkActive
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: _isBookmarkActive
                                ? amarilloOro
                                : Colors.white,
                            size: screenWidth * 0.07,
                          ),
                          onPressed: _toggleFavorito,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.07,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: usableHeight * 0.01),
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 243, 241, 237),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: azulFondo),
                          )
                        : _errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: screenWidth * 0.04,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        //-------------------------
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              screenWidth * 0.06,
                              usableHeight * 0.035,
                              screenWidth * 0.06,
                              usableHeight * 0.12,
                            ),
                            itemCount: _versiculos.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: usableHeight * 0.025),
                            itemBuilder: (context, index) {
                              final verse = _versiculos[index];
                              final int numVerso = verse['verse'];
                              final String textoLimpio =
                                  (verse['text'] as String).replaceAll(
                                    RegExp(r'<[^>]*>'),
                                    '',
                                  );
                              return RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$numVerso) ',
                                      style: TextStyle(
                                        color: azulFondo,
                                        fontSize: screenWidth * 0.048,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: textoLimpio,
                                      style: TextStyle(
                                        color: const Color(0xFF222222),
                                        fontSize: screenWidth * 0.065,
                                        fontWeight: FontWeight.w600,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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

  Widget _buildBottomNavigationBar(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
    Color grisBorde,
  ) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F0),
        border: Border(top: BorderSide(color: grisBorde, width: 1)),
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: bottomPadding > 0 ? bottomPadding : 10,
        left: screenWidth * 0.04,
        right: screenWidth * 0.04,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBottomNavButton(
            icon: Icons.chevron_left_rounded,
            label: 'Anterior',
            color: _capituloActual > 1 ? azulFondo : Colors.grey.shade400,
            screenWidth: screenWidth,
            onTap: _capituloActual > 1
                ? () => _cambiarCapitulo(_capituloActual - 1)
                : null,
          ),
          _buildBottomNavButton(
            icon: Icons.edit_note_rounded,
            label: 'Nota',
            color: azulFondo,
            screenWidth: screenWidth,
            onTap: () => _mostrarModalCrearNota(
              context,
              screenWidth,
              usableHeight,
              azulFondo,
              amarilloOro,
            ),
          ),
          _buildBottomNavButton(
            icon: Icons.share_outlined,
            label: 'Compartir',
            color: azulFondo,
            screenWidth: screenWidth,
            onTap: () => _mostrarModalCompartir(
              context,
              screenWidth,
              usableHeight,
              azulFondo,
              amarilloOro,
            ),
          ),
          _buildBottomNavButton(
            icon: Icons.chevron_right_rounded,
            label: 'Siguiente',
            color: _capituloActual < _totalCapitulos
                ? azulFondo
                : Colors.grey.shade400,
            isIconRight: true,
            screenWidth: screenWidth,
            onTap: _capituloActual < _totalCapitulos
                ? () => _cambiarCapitulo(_capituloActual + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavButton({
    required IconData icon,
    required String label,
    required Color color,
    required double screenWidth,
    required VoidCallback? onTap,
    bool isIconRight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: screenWidth * 0.075),
          SizedBox(height: screenWidth * 0.005),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: screenWidth * 0.030,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
