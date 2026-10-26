import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../l10n/app_localizations.dart';
import '../modelos/video_model.dart';
import '../utils/youtube_helper.dart';

/// Modal interactivo embebido para reproducción de streaming y videos en la app ATRIO.
/// Utiliza [youtube_player_flutter] con ciclo de vida completo y fallback seguro.
class ReproductorStreamingModal extends StatefulWidget {
  final VideoModel video;
  final bool autoPlay;
  final Widget Function(BuildContext, YoutubePlayerController)? playerBuilder;

  const ReproductorStreamingModal({
    super.key,
    required this.video,
    this.autoPlay = true,
    this.playerBuilder,
  });

  /// Método de utilidad estático para desplegar el reproductor en un Bottom Sheet modal.
  static Future<void> mostrar(
    BuildContext context, {
    required VideoModel video,
    bool autoPlay = true,
    Widget Function(BuildContext, YoutubePlayerController)? playerBuilder,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => ReproductorStreamingModal(
        video: video,
        autoPlay: autoPlay,
        playerBuilder: playerBuilder,
      ),
    );
  }

  @override
  State<ReproductorStreamingModal> createState() =>
      _ReproductorStreamingModalState();
}

class _ReproductorStreamingModalState extends State<ReproductorStreamingModal> {
  YoutubePlayerController? _controller;
  String? _youtubeVideoId;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _inicializarReproductor();
  }

  void _inicializarReproductor() {
    // 1. Extraer ID usando YoutubeHelper
    String? id = YoutubeHelper.extractId(widget.video.videoUrl);

    // Fallback: verificar si el ID del modelo ya es un ID de 11 caracteres
    if (id == null && widget.video.id.length == 11) {
      id = widget.video.id;
    }

    _youtubeVideoId = id;

    if (_youtubeVideoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: _youtubeVideoId!,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
          isLive: widget.video.esEnVivo,
          mute: false,
          enableCaption: true,
          useHybridComposition: true,
          loop: false,
          forceHD: false,
        ),
      )..addListener(_onPlayerStateChange);

      _isPlaying = widget.autoPlay;
    }
  }

  void _onPlayerStateChange() {
    if (!mounted || _controller == null) return;
    final isCurrentlyPlaying = _controller!.value.isPlaying;
    if (isCurrentlyPlaying != _isPlaying) {
      setState(() {
        _isPlaying = isCurrentlyPlaying;
      });
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.removeListener(_onPlayerStateChange);
      _controller!.pause();
      _controller!.dispose();
    }
    // Restaurar orientaciones en caso de que estuviese en fullscreen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  Future<void> _abrirExternamente() async {
    final rawUrl = widget.video.videoUrl.isNotEmpty
        ? widget.video.videoUrl
        : (_youtubeVideoId != null
            ? YoutubeHelper.buildWatchUrl(_youtubeVideoId!)
            : null);

    if (rawUrl == null) return;
    final uri = Uri.tryParse(rawUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;
    final l10n = AppLocalizations.of(context);

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color rojoLive = Color(0xFFE53935);

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: usableHeight * 0.90,
        ),
        decoration: BoxDecoration(
          color: blancoFondo,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(screenWidth * 0.06),
            topRight: Radius.circular(screenWidth * 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Manija de arrastre superior
            Container(
              margin: EdgeInsets.only(
                top: usableHeight * 0.012,
                bottom: usableHeight * 0.010,
              ),
              width: screenWidth * 0.12,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 2. Contenido scrolleable
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  bottom: safeAreaBottom + usableHeight * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Área del Reproductor Embebido 16:9
                    _buildPlayerArea(
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      amarilloOro: amarilloOro,
                      rojoLive: rojoLive,
                      azulFondo: azulFondo,
                    ),
                    SizedBox(height: usableHeight * 0.018),

                    // Badges (Categoría, En Vivo, Duración)
                    _buildMetaBadges(
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      azulFondo: azulFondo,
                      rojoLive: rojoLive,
                      l10n: l10n,
                    ),
                    SizedBox(height: usableHeight * 0.010),

                    // Título del Video
                    Text(
                      widget.video.titulo,
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.046,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.006),

                    // Predicador y Canal / Congregación
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_rounded,
                          size: screenWidth * 0.04,
                          color: amarilloOro,
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Expanded(
                          child: Text(
                            widget.video.predicador != null
                                ? '${widget.video.predicador!} · ${widget.video.canalOIglesia}'
                                : widget.video.canalOIglesia,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: screenWidth * 0.032,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.015),

                    // Sinopsis / Descripción
                    if (widget.video.sinopsis.isNotEmpty) ...[
                      Text(
                        l10n?.descripcion ?? 'Descripción',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.034,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.005),
                      Text(
                        widget.video.sinopsis,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: screenWidth * 0.030,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.02),
                    ],

                    // Barra de Acciones del Reproductor
                    _buildActionButtons(
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      azulFondo: azulFondo,
                      amarilloOro: amarilloOro,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ÁREA DEL REPRODUCTOR (16:9 con soporte de tests y fallback)
  // ===========================================================================

  Widget _buildPlayerArea({
    required double screenWidth,
    required double usableHeight,
    required Color amarilloOro,
    required Color rojoLive,
    required Color azulFondo,
  }) {
    final double playerHeight = (screenWidth - (screenWidth * 0.10)) * (9 / 16);

    // Caso 1: No hay ID de YouTube válido reconocido -> Fallback
    if (_youtubeVideoId == null || _controller == null) {
      return Container(
        width: screenWidth,
        height: playerHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E2E),
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: usableHeight * 0.01,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Builder(
            builder: (context) {
              final isChannel = YoutubeHelper.isChannelUrl(widget.video.videoUrl);
              final isChannelLive = YoutubeHelper.isChannelLiveUrl(widget.video.videoUrl);
              final channelHandle = YoutubeHelper.extractChannelHandle(widget.video.videoUrl);

              if (isChannel) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC4302B),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isChannelLive ? Icons.sensors_rounded : Icons.subscriptions_rounded,
                        color: Colors.white,
                        size: screenWidth * 0.08,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.008),
                    Text(
                      isChannelLive
                          ? 'Transmisión Oficial en Directo'
                          : 'Canal Oficial de YouTube',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.004),
                    Text(
                      channelHandle != null
                          ? 'Canal $channelHandle · YouTube'
                          : widget.video.canalOIglesia,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.028,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.010),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4302B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: _abrirExternamente,
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                      label: Text(
                        isChannelLive ? 'Ver en vivo en YouTube' : 'Abrir Canal en YouTube',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.ondemand_video_rounded,
                    color: amarilloOro,
                    size: screenWidth * 0.10,
                  ),
                  SizedBox(height: usableHeight * 0.008),
                  Text(
                    'Reproducción externa requerida',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.004),
                  Text(
                    'Este contenido no incluye un ID de YouTube reproducible directamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenWidth * 0.028,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.010),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: amarilloOro,
                      foregroundColor: azulFondo,
                      elevation: 0,
                    ),
                    onPressed: _abrirExternamente,
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Abrir enlace original'),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    // Caso 2: El reproductor está activo y listo
    return Container(
      width: screenWidth,
      height: playerHeight,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        child: _buildYoutubePlayerWidget(),
      ),
    );
  }

  Widget _buildYoutubePlayerWidget() {
    // Si se inyecta un constructor de reproductor para testing/mocking
    if (widget.playerBuilder != null && _controller != null) {
      return widget.playerBuilder!(context, _controller!);
    }

    // Entorno de pruebas de Flutter (donde no existe InAppWebViewPlatform nativo)
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Container(
        key: const Key('reproductor_youtube_embebido'),
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_circle_filled_rounded,
                color: Color(0xFFE5A023),
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'YouTube Embebido: $_youtubeVideoId',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              if (widget.video.esEnVivo)
                const Text(
                  'Transmisión en Vivo',
                  style: TextStyle(color: Color(0xFFE53935), fontSize: 11),
                ),
            ],
          ),
        ),
      );
    }

    // Reproductor real en producción para Android/iOS
    return YoutubePlayer(
      key: const Key('reproductor_youtube_embebido'),
      controller: _controller!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: const Color(0xFFE5A023),
      progressColors: const ProgressBarColors(
        playedColor: Color(0xFFE5A023),
        handleColor: Color(0xFFE5A023),
        bufferedColor: Colors.white30,
        backgroundColor: Colors.white12,
      ),
      topActions: [
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            _controller!.metadata.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.0,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
        ),
      ],
      onReady: () {
        debugPrint('[ReproductorStreaming] Reproductor listo');
      },
    );
  }

  // ===========================================================================
  // BADGES Y METADATOS DEL STREAMING
  // ===========================================================================

  Widget _buildMetaBadges({
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color rojoLive,
    required AppLocalizations? l10n,
  }) {
    return Wrap(
      spacing: screenWidth * 0.02,
      runSpacing: usableHeight * 0.006,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Categoría
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
            widget.video.categoria,
            style: TextStyle(
              color: azulFondo,
              fontSize: screenWidth * 0.028,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.02),

        // Badge En Vivo
        if (widget.video.esEnVivo) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.025,
              vertical: usableHeight * 0.004,
            ),
            decoration: BoxDecoration(
              color: rojoLive,
              borderRadius: BorderRadius.circular(screenWidth * 0.015),
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
                SizedBox(width: screenWidth * 0.012),
                Text(
                  l10n?.enVivoBadge ?? 'EN VIVO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.026,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
        ],

        // Duración o Estadísticas
        if (widget.video.duracion != null && !widget.video.esEnVivo) ...[
          Text(
            widget.video.duracion!,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: screenWidth * 0.028,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (widget.video.estadisticas != null) ...[
          Text(
            widget.video.estadisticas!,
            style: TextStyle(
              color: widget.video.esEnVivo ? rojoLive : Colors.grey.shade600,
              fontSize: screenWidth * 0.028,
              fontWeight: widget.video.esEnVivo ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // BOTONES DE ACCIÓN
  // ===========================================================================

  Widget _buildActionButtons({
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required AppLocalizations? l10n,
  }) {
    return Row(
      children: [
        // Botón Primario: Reproducir / Pausar
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: amarilloOro,
              foregroundColor: azulFondo,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                vertical: usableHeight * 0.015,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
            ),
            onPressed: _controller != null ? _togglePlayPause : _abrirExternamente,
            icon: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: screenWidth * 0.05,
            ),
            label: Text(
              _isPlaying
                  ? 'Pausar'
                  : (widget.video.esEnVivo
                      ? (l10n?.verTransmisionEnVivo ?? 'Ver transmisión en vivo')
                      : (l10n?.reproducirAhora ?? 'Reproducir ahora')),
              style: TextStyle(
                fontSize: screenWidth * 0.034,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.025),

        // Botón Secundario: Abrir en YouTube Oficial
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: azulFondo,
            side: BorderSide(color: azulFondo, width: 1.2),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.035,
              vertical: usableHeight * 0.015,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
          ),
          onPressed: _abrirExternamente,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.open_in_new_rounded,
                size: screenWidth * 0.045,
                color: azulFondo,
              ),
              SizedBox(width: screenWidth * 0.01),
              Text(
                'YouTube',
                style: TextStyle(
                  fontSize: screenWidth * 0.030,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: screenWidth * 0.025),

        // Botón Compartir
        IconButton.outlined(
          style: IconButton.styleFrom(
            foregroundColor: azulFondo,
            side: BorderSide(color: Colors.grey.shade400),
          ),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.video.videoUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.enlaceCopiadoPortapapeles(widget.video.titulo) ??
                      'Enlace copiado al portapapeles',
                ),
                backgroundColor: azulFondo,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          icon: Icon(
            Icons.share_outlined,
            size: screenWidth * 0.048,
          ),
        ),
      ],
    );
  }
}
