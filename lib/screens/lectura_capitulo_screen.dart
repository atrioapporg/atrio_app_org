// ignore_for_file: unused_field
import 'dart:io';

import 'package:atrio/data/atrio_database_helper.dart';
import 'package:atrio/data/database_helper.dart';
import 'package:atrio/providers/biblia_provider.dart';
import 'package:atrio/servicios/bible_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LecturaCapituloScreen extends StatefulWidget {
  static const routeName = 'lectura_capitulo_screen';
  const LecturaCapituloScreen({super.key});

  @override
  State<LecturaCapituloScreen> createState() => _LecturaCapituloScreenState();
}

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
  int? _versoAutoPlay;
  int? _versoFinAutoPlay;
  bool _debeAutoPlay = false;
  final ScrollController _scrollController = ScrollController();

  // Lista de fuentes optimizadas para lectura
  static const List<String> _fuentesDisponibles = [
    'Inter',
    'Roboto',
    'Open Sans',
    'Noto Sans',
    'Source Sans 3',
    'IBM Plex Sans',
    'Merriweather',
  ];

  TextStyle _getFontStyle(TextStyle baseStyle, String fontName) {
    switch (fontName) {
      case 'Roboto':
        return GoogleFonts.roboto(textStyle: baseStyle);
      case 'Open Sans':
        return GoogleFonts.openSans(textStyle: baseStyle);
      case 'Noto Sans':
        return GoogleFonts.notoSans(textStyle: baseStyle);
      case 'Source Sans 3':
        return GoogleFonts.sourceSans3(textStyle: baseStyle);
      case 'IBM Plex Sans':
        return GoogleFonts.ibmPlexSans(textStyle: baseStyle);
      case 'Merriweather':
        return GoogleFonts.merriweather(textStyle: baseStyle);
      case 'Inter':
      default:
        return GoogleFonts.inter(textStyle: baseStyle);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
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
      _totalCapitulos = args['totalCapitulos'] ?? args['capitulos'] ?? 50;
      _subtitulo = args['subtitulo'] ?? 'La creación';
      _versoAutoPlay = args['verso'] as int?;
      _versoFinAutoPlay = args['versoFin'] as int? ?? _versoAutoPlay;
      _debeAutoPlay = args['autoPlay'] == true;

      AtrioDatabaseHelper.instance.guardarUltimaLectura(
        libro: _libroNombre,
        capitulo: _capituloActual,
        totalCapitulos: _totalCapitulos,
      );

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
        _libroId > 0 ? _libroId.toString() : _libroNombre,
        _capituloActual,
      );
      if (mounted) {
        setState(() {
          _versiculos = data;
          _isLoading = false;
        });
        _verificarSiEsFavorito();

        if (_versoAutoPlay != null) {
          final int versoTarget = _versoAutoPlay!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final screenWidth = MediaQuery.sizeOf(context).width;
            final screenHeight = MediaQuery.sizeOf(context).height;
            final safeAreaTop = MediaQuery.of(context).padding.top;
            final safeAreaBottom = MediaQuery.of(context).padding.bottom;
            final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

            final Color colorHeader = provider.modoLectura == ModoLectura.noche
                ? const Color(0xFF162231)
                : const Color(0xFF072B4F);
            final Color colorAcento = provider.modoLectura == ModoLectura.noche
                ? const Color(0xFFF59E0B)
                : (provider.modoLectura == ModoLectura.suave
                      ? const Color(0xFF0F4C81)
                      : const Color(0xFFC28518));

            final indexVerso = _versiculos.indexWhere(
              (v) => v['verse'] == versoTarget,
            );
            if (indexVerso > 0 && _scrollController.hasClients) {
              final double posicionAprox = (indexVerso * 90.0).clamp(
                0.0,
                _scrollController.position.maxScrollExtent,
              );
              _scrollController.animateTo(
                posicionAprox,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            }

            if (_debeAutoPlay) {
              _debeAutoPlay = false;
              _abrirReproductorYouTube(
                screenWidth,
                usableHeight,
                colorHeader,
                colorAcento,
              );
            }
          });
        }
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

  void _cambiarModoLectura(BibliaProvider provider) {
    switch (provider.modoLectura) {
      case ModoLectura.calido:
        provider.actualizarModoLectura(ModoLectura.suave);
        _mostrarMensaje('Modo Claro Suave');
        break;
      case ModoLectura.suave:
        provider.actualizarModoLectura(ModoLectura.noche);
        _mostrarMensaje('Modo Lectura Nocturna');
        break;
      case ModoLectura.noche:
        provider.actualizarModoLectura(ModoLectura.calido);
        _mostrarMensaje('Modo Papiro Cálido');
        break;
    }
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          texto,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        width: 220,
      ),
    );
  }

  // =========================================================
  // MODAL DE AJUSTES DE LECTURA (SINCRONIZADO CON PROVIDER)
  // =========================================================
  void _mostrarOpcionesDeLectura(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF7F0),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      builder: (ctx) {
        return Consumer<BibliaProvider>(
          builder: (context, provider, child) {
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ajustes de lectura',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: azulFondo,
                          size: screenWidth * 0.06,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.02),
                  Text(
                    'Tamaño de letra',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.01),
                  Row(
                    children: [
                      Text(
                        'A',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: provider.fontScale,
                          min: 0.8,
                          max: 2.0,
                          divisions: 12,
                          activeColor: amarilloOro,
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (val) {
                            provider.actualizarAjustesVisuales(
                              val,
                              provider.selectedFont,
                            );
                          },
                        ),
                      ),
                      Text(
                        'A',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.02),
                  Text(
                    'Tipo de fuente',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.015),
                  Wrap(
                    spacing: screenWidth * 0.02,
                    runSpacing: usableHeight * 0.01,
                    children: _fuentesDisponibles.map((font) {
                      final isSelected = provider.selectedFont == font;
                      return ChoiceChip(
                        label: Text(
                          font,
                          style: TextStyle(
                            color: isSelected
                                ? azulFondo
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: amarilloOro.withValues(alpha: 0.3),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? amarilloOro
                                : Colors.grey.shade300,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            provider.actualizarAjustesVisuales(
                              provider.fontScale,
                              font,
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: usableHeight * 0.02),
                  Text(
                    'Modo de lectura',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.015),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(
                            Icons.wb_incandescent_outlined,
                            size: 18,
                          ),
                          label: const Text('Papiro'),
                          selected: provider.modoLectura == ModoLectura.calido,
                          selectedColor: const Color(0xFFC28518)
                              .withValues(alpha: 0.25),
                          backgroundColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              provider.actualizarModoLectura(
                                ModoLectura.calido,
                              );
                              Navigator.pop(ctx);
                              _mostrarMensaje('Modo Papiro Cálido');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.wb_sunny_rounded, size: 18),
                          label: const Text('Claro'),
                          selected: provider.modoLectura == ModoLectura.suave,
                          selectedColor: const Color(0xFF0F4C81)
                              .withValues(alpha: 0.2),
                          backgroundColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              provider.actualizarModoLectura(ModoLectura.suave);
                              Navigator.pop(ctx);
                              _mostrarMensaje('Modo Claro Suave');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.nightlight_round, size: 18),
                          label: const Text('Noche'),
                          selected: provider.modoLectura == ModoLectura.noche,
                          selectedColor: const Color(0xFFF59E0B)
                              .withValues(alpha: 0.25),
                          backgroundColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              provider.actualizarModoLectura(ModoLectura.noche);
                              Navigator.pop(ctx);
                              _mostrarMensaje('Modo Lectura Nocturna');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.04),
                ],
              ),
            );
          },
        );
      },
    );
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
    final tieneInternet = await _hasRealInternet();
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

    final dataCapitulo = await DatabaseHelper.instance.getCapitulo(
      _libroNombre,
      _capituloActual,
    );

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
                          '$_libroNombre $_capituloActual (Audio Dramatizado)',
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
      final String texto = BibleService.limpiarTextoVerso(
        verse['text'] as String?,
      );
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

  @override
  Widget build(BuildContext context) {
    // Escucha directa del estado global en BibliaProvider
    final provider = Provider.of<BibliaProvider>(context);
    final fontScale = provider.fontScale;
    final selectedFont = provider.selectedFont;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    // Configuración cromática según el modo de lectura (pensado para no fatigar ojos cansados)
    final Color colorTarjeta;
    final Color colorTextoPrincipal;
    final Color colorTextoSecundario;
    final Color colorAcento;
    final Color colorBorde;
    final Color colorHeader;
    final Color colorHeaderTexto;
    final Color colorBottomNav;

    switch (provider.modoLectura) {
      case ModoLectura.calido:
        colorTarjeta = const Color(0xFFF9F5EC); // Tono papiro/crema cálido
        colorTextoPrincipal = const Color(0xFF26211C); // Carbón cálido suave
        colorTextoSecundario = const Color(0xFF5D5347);
        colorAcento = const Color(0xFFC28518);
        colorBorde = const Color(0xFFE9E0CF);
        colorHeader = const Color(0xFF072B4F);
        colorHeaderTexto = Colors.white;
        colorBottomNav = const Color(0xFFFAF7F0);
        break;
      case ModoLectura.suave:
        colorTarjeta = const Color(0xFFF4F6F9);
        colorTextoPrincipal = const Color(0xFF1E293B);
        colorTextoSecundario = const Color(0xFF64748B);
        colorAcento = const Color(0xFF0F4C81);
        colorBorde = const Color(0xFFE2E8F0);
        colorHeader = const Color(0xFF072B4F);
        colorHeaderTexto = Colors.white;
        colorBottomNav = const Color(0xFFFAF7F0);
        break;
      case ModoLectura.noche:
        colorTarjeta = const Color(
          0xFF0E1721,
        ); // Fondo noche profundo para descanso visual
        colorTextoPrincipal = const Color(
          0xFFE2E8F0,
        ); // Texto suavemente contrastado
        colorTextoSecundario = const Color(0xFF94A3B8);
        colorAcento = const Color(0xFFF59E0B);
        colorBorde = const Color(0xFF27384E);
        colorHeader = const Color(0xFF162231);
        colorHeaderTexto = const Color(0xFFE2E8F0);
        colorBottomNav = const Color(0xFF162231);
        break;
    }

    final bool esNoche = provider.modoLectura == ModoLectura.noche;

    return Scaffold(
      backgroundColor: colorHeader,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirReproductorYouTube(
          screenWidth,
          usableHeight,
          colorHeader,
          colorAcento,
        ),
        backgroundColor: esNoche
            ? const Color(0xFF1E293B)
            : const Color(0xFF072B4F),
        shape: const CircleBorder(),
        elevation: 4,
        child: Icon(
          Icons.play_arrow_rounded,
          color: esNoche ? colorAcento : Colors.white,
          size: 35,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigationBar(
        screenWidth,
        usableHeight,
        colorHeader,
        colorAcento,
        colorBorde,
        colorBottomNav,
        colorTextoPrincipal,
        esNoche,
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
                  vertical: usableHeight * 0.01,
                ),
                child: Column(
                  children: [
                    // Fila superior: Botón de regreso a la izquierda y gestión de tema/lectura a la derecha
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
                              color: colorHeaderTexto,
                              size: screenWidth * 0.07,
                            ),
                          ),
                        ),
                        // Iconos de gestión de tema y configuración
                        Row(
                          children: [
                            // Botón alternar modo de lectura (Papiro / Claro / Noche)
                            IconButton(
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              tooltip: 'Cambiar tono de lectura',
                              icon: Icon(
                                provider.modoLectura == ModoLectura.noche
                                    ? Icons.nightlight_round
                                    : provider.modoLectura == ModoLectura.calido
                                    ? Icons.wb_incandescent_outlined
                                    : Icons.wb_sunny_rounded,
                                color: colorAcento,
                                size: screenWidth * 0.065,
                              ),
                              onPressed: () => _cambiarModoLectura(provider),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            IconButton(
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              tooltip: 'Opciones de lectura',
                              icon: Icon(
                                Icons.text_format_rounded,
                                color: colorHeaderTexto,
                                size: screenWidth * 0.07,
                              ),
                              onPressed: () => _mostrarOpcionesDeLectura(
                                screenWidth,
                                usableHeight,
                                colorHeader,
                                colorAcento,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            IconButton(
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              tooltip: _isBookmarkActive
                                  ? 'Quitar de favoritos'
                                  : 'Añadir a favoritos',
                              icon: Icon(
                                _isBookmarkActive
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: _isBookmarkActive
                                    ? colorAcento
                                    : colorHeaderTexto,
                                size: screenWidth * 0.07,
                              ),
                              onPressed: _toggleFavorito,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.008),
                    // Línea inferior: Nombre del libro y número de capítulo
                    Column(
                      children: [
                        Text(
                          '$_libroNombre $_capituloActual',
                          style: _getFontStyle(
                            TextStyle(
                              color: colorHeaderTexto,
                              fontSize: screenWidth * 0.065,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            selectedFont,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_subtitulo.isNotEmpty) ...[
                          SizedBox(height: usableHeight * 0.004),
                          Text(
                            _subtitulo,
                            style: _getFontStyle(
                              TextStyle(
                                color: esNoche
                                    ? colorTextoSecundario
                                    : colorHeaderTexto.withValues(alpha: 0.75),
                                fontSize: screenWidth * 0.042,
                              ),
                              selectedFont,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: usableHeight * 0.01),
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: colorTarjeta,
                    borderRadius: const BorderRadius.only(
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
                        ? Center(
                            child: CircularProgressIndicator(
                              color: colorAcento,
                            ),
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
                        : ListView.separated(
                            controller: _scrollController,
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
                                  BibleService.limpiarTextoVerso(
                                    verse['text'] as String?,
                                  );
                              final baseFontSize =
                                  (screenWidth * 0.052) * fontScale;
                              final numberFontSize =
                                  (screenWidth * 0.048) * fontScale;

                              return RichText(
                                text: TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => _abrirReproductorYouTube(
                                          screenWidth,
                                          usableHeight,
                                          colorHeader,
                                          colorAcento,
                                        ),
                                        child: Container(
                                          margin: EdgeInsets.only(
                                            right: screenWidth * 0.015,
                                            bottom: 2.0,
                                          ),
                                          padding: EdgeInsets.all(
                                            screenWidth * 0.012,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorAcento.withValues(
                                              alpha: 0.12,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.play_arrow_rounded,
                                            size: numberFontSize * 0.88,
                                            color: colorAcento,
                                          ),
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$numVerso) ',
                                      style: _getFontStyle(
                                        TextStyle(
                                          color: colorAcento,
                                          fontSize: numberFontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        selectedFont,
                                      ),
                                    ),
                                    TextSpan(
                                      text: textoLimpio,
                                      style: _getFontStyle(
                                        TextStyle(
                                          color: colorTextoPrincipal,
                                          fontSize: baseFontSize,
                                          fontWeight: FontWeight.w600,
                                          height: 1.45,
                                        ),
                                        selectedFont,
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
    Color colorBottomNav,
    Color colorTextoPrincipal,
    bool esNoche,
  ) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final Color colorBoton = esNoche ? colorTextoPrincipal : azulFondo;
    final Color colorDeshabilitado = esNoche
        ? Colors.grey.shade600
        : Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: colorBottomNav,
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
            color: _capituloActual > 1 ? colorBoton : colorDeshabilitado,
            screenWidth: screenWidth,
            onTap: _capituloActual > 1
                ? () => _cambiarCapitulo(_capituloActual - 1)
                : null,
          ),
          _buildBottomNavButton(
            icon: Icons.edit_note_rounded,
            label: 'Nota',
            color: colorBoton,
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
            color: colorBoton,
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
                ? colorBoton
                : colorDeshabilitado,
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
