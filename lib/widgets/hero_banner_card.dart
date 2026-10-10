import 'dart:async';

import 'package:flutter/material.dart';
import 'package:atrio/modelos/hero_banner_mocks.dart';
import 'package:atrio/modelos/palabra_dia_model.dart';
import 'package:atrio/modelos/versiculo_dia.dart';
import 'package:atrio/modelos/video_model.dart';
import 'package:atrio/servicios/versiculo_service.dart';
import 'package:atrio/widgets/modal_versiculo_imagen.dart';

enum HeroBannerTipo { cultoEnVivo, versiculoDelDia, palabraDelDia }

class _BannerSlideData {
  final HeroBannerTipo tipo;
  final String title;
  final String? subtitle;
  final String buttonText;
  final VoidCallback onTap;
  final String backgroundImage;
  final IconData watermarkIcon;
  final Widget topLeading;

  _BannerSlideData({
    required this.tipo,
    required this.title,
    this.subtitle,
    required this.buttonText,
    required this.onTap,
    required this.backgroundImage,
    required this.watermarkIcon,
    required this.topLeading,
  });
}

class HeroBannerCard extends StatefulWidget {
  // Parámetros para modo estático tradicional (retrocompatibilidad)
  final String? title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final VoidCallback? onTap;
  final String? backgroundImage;
  final List<Color>? gradientColors;
  final Color backgroundColor;
  final Widget? topLeading;
  final IconData? watermarkIcon;
  final double? heightFactor;

  // Parámetros para modo dinámico (futuro backend / inyección de datos)
  final List<VideoModel>? cultosEnVivo;
  final List<PalabraDelDiaModel>? palabrasDelDia;
  final VersiculoDia? versiculoDelDia;

  const HeroBannerCard({
    super.key,
    this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.onTap,
    this.backgroundImage,
    this.gradientColors,
    this.backgroundColor = const Color(0xFF0F1E2E),
    this.topLeading,
    this.watermarkIcon,
    this.heightFactor = 0.195,
    this.cultosEnVivo,
    this.palabrasDelDia,
    this.versiculoDelDia,
  });

  @override
  State<HeroBannerCard> createState() => _HeroBannerCardState();
}

class _HeroBannerCardState extends State<HeroBannerCard> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  // Estado del versículo del día obtenido por servicio
  VersiculoDia? _versiculoCargado;
  final VersiculoService _versiculoService = VersiculoService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (_esModoDinamico) {
      _cargarVersiculo();
      _iniciarAutoPlay();
    }
  }

  bool get _esModoDinamico => widget.title == null;

  Future<void> _cargarVersiculo() async {
    if (widget.versiculoDelDia != null) {
      _versiculoCargado = widget.versiculoDelDia;
      return;
    }
    try {
      final v = await _versiculoService.obtenerVersiculoDelDia();
      if (mounted) {
        setState(() {
          _versiculoCargado = v;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _versiculoCargado = VersiculoDia(
            texto: 'Mira que te mando que te esfuerces y seas valiente; no temas ni desmayes.',
            referencia: 'Josué 1:9',
          );
        });
      }
    }
  }

  void _iniciarAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final total = _construirDiapositivas(
        MediaQuery.sizeOf(context).width,
        MediaQuery.sizeOf(context).height,
      ).length;
      if (total <= 1) return;

      final nextIndex = (_currentIndex + 1) % total;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<_BannerSlideData> _construirDiapositivas(
    double screenWidth,
    double screenHeight,
  ) {
    final List<_BannerSlideData> slides = [];

    // 1. La palabra del día
    final listaPalabras = widget.palabrasDelDia ?? palabrasDelDiaMock;
    final palabraActual = listaPalabras.isNotEmpty
        ? listaPalabras.first
        : palabrasDelDiaMock.first;

    slides.add(
      _BannerSlideData(
        tipo: HeroBannerTipo.palabraDelDia,
        title: palabraActual.titulo,
        subtitle: '${palabraActual.autor} · ${palabraActual.citaBiblica}',
        buttonText: 'Leer reflexión',
        backgroundImage:
            palabraActual.imagenFondo ?? 'assets/images/biblia1.jpg',
        watermarkIcon: Icons.auto_stories_rounded,
        onTap: () {
          _mostrarModalPalabra(context, palabraActual);
        },
        topLeading: _buildPalabraBadge(screenWidth, screenHeight),
      ),
    );

    // 2. Versículo del día
    final versiculo =
        _versiculoCargado ??
        widget.versiculoDelDia ??
        VersiculoDia(
          texto: 'Mira que te mando que te esfuerces y seas valiente; no temas ni desmayes.',
          referencia: 'Josué 1:9',
        );

    slides.add(
      _BannerSlideData(
        tipo: HeroBannerTipo.versiculoDelDia,
        title: versiculo.referencia,
        subtitle: '«${versiculo.texto}»',
        buttonText: 'Ver versículo',
        backgroundImage: 'assets/images/biblia3.jpg',
        watermarkIcon: Icons.menu_book_rounded,
        onTap: () {
          ModalVersiculoImagen.mostrar(context, versiculo: versiculo);
        },
        topLeading: _buildVersiculoBadge(screenWidth, screenHeight),
      ),
    );

    // 3. Culto en vivo (si aplica)
    final listaCultos = widget.cultosEnVivo ?? cultosEnVivoMock;
    final cultoActivo = listaCultos.cast<VideoModel?>().firstWhere(
      (c) => c != null && c.esEnVivo,
      orElse: () => null,
    );

    if (cultoActivo != null) {
      slides.add(
        _BannerSlideData(
          tipo: HeroBannerTipo.cultoEnVivo,
          title: cultoActivo.titulo,
          subtitle:
              cultoActivo.horario ??
              cultoActivo.estadisticas ??
              'En vivo ahora',
          buttonText: 'Ver ahora',
          backgroundImage: cultoActivo.thumbnailUrl.isNotEmpty
              ? cultoActivo.thumbnailUrl
              : 'assets/images/culto2.jpg',
          watermarkIcon: Icons.live_tv_rounded,
          onTap: () {
            Navigator.pushNamed(context, 'videos_transmisiones_screen');
          },
          topLeading: _buildLiveBadge(screenWidth, screenHeight),
        ),
      );
    }

    return slides;
  }

  Widget _buildLiveBadge(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.024,
        vertical: screenHeight * 0.0035,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F),
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: screenWidth * 0.02,
            height: screenWidth * 0.02,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: screenWidth * 0.012),
          Text(
            'EN VIVO',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.027,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersiculoBadge(double screenWidth, double screenHeight) {
    const Color dorado = Color(0xFFE5A023);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.024,
        vertical: screenHeight * 0.0035,
      ),
      decoration: BoxDecoration(
        color: dorado.withValues(alpha: 0.22),
        border: Border.all(color: dorado.withValues(alpha: 0.7), width: 0.8),
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: dorado,
            size: screenWidth * 0.032,
          ),
          SizedBox(width: screenWidth * 0.012),
          Text(
            'VERSÍCULO DEL DÍA',
            style: TextStyle(
              color: dorado,
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPalabraBadge(double screenWidth, double screenHeight) {
    const Color azulClaro = Color(0xFF64B5F6);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.024,
        vertical: screenHeight * 0.0035,
      ),
      decoration: BoxDecoration(
        color: azulClaro.withValues(alpha: 0.22),
        border: Border.all(color: azulClaro.withValues(alpha: 0.7), width: 0.8),
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.light_mode_rounded,
            color: azulClaro,
            size: screenWidth * 0.032,
          ),
          SizedBox(width: screenWidth * 0.012),
          Text(
            'PALABRA DEL DÍA',
            style: TextStyle(
              color: azulClaro,
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarModalPalabra(BuildContext context, PalabraDelDiaModel palabra) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final usableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: usableHeight * 0.78,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(screenWidth * 0.07),
          ),
        ),
        child: Column(
          children: [
            // Asa del modal
            SizedBox(height: usableHeight * 0.015),
            Container(
              width: screenWidth * 0.12,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: usableHeight * 0.015),

            // Encabezado
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.025),
                    decoration: BoxDecoration(
                      color: azulFondo.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: azulFondo,
                      size: screenWidth * 0.065,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.035),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Palabra del día',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.032,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          palabra.titulo,
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.046,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.grey.shade600,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // Contenido escroleable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.055),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de la cita bíblica base
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(screenWidth * 0.038),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        border: Border.all(
                          color: amarilloOro.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bookmark_added_rounded,
                            color: amarilloOro,
                            size: screenWidth * 0.055,
                          ),
                          SizedBox(width: screenWidth * 0.025),
                          Expanded(
                            child: Text(
                              'Cita base: ${palabra.citaBiblica}',
                              style: TextStyle(
                                color: azulFondo,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.02),

                    // Autor / Pastor
                    Row(
                      children: [
                        Icon(
                          Icons.person_pin_rounded,
                          color: Colors.grey.shade600,
                          size: screenWidth * 0.042,
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Text(
                          palabra.autor,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: screenWidth * 0.033,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.02),

                    // Texto completo de la reflexión
                    Text(
                      palabra.contenidoCompleto,
                      style: TextStyle(
                        color: const Color(0xFF2C3E50),
                        fontSize: screenWidth * 0.065,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.03),
                  ],
                ),
              ),
            ),

            // Botón inferior
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: usableHeight * 0.015,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulFondo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: usableHeight * 0.015,
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Entendido · Amén',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.055,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    // Si se pasa título explícito, actúa como banner estático clásico
    if (!_esModoDinamico) {
      return _buildCardBase(
        screenWidth: screenWidth,
        usableHeight: usableHeight,
        title: widget.title!,
        subtitle: widget.subtitle,
        buttonText: widget.buttonText,
        onTap: widget.onTap,
        onButtonPressed: widget.onButtonPressed,
        backgroundImage: widget.backgroundImage,
        watermarkIcon: widget.watermarkIcon,
        topLeading: widget.topLeading,
      );
    }

    final slides = _construirDiapositivas(screenWidth, screenHeight);

    return Container(
      width: screenWidth,
      height: usableHeight * (widget.heightFactor ?? 0.195),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.045),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final slide = slides[index];
              return _buildCardBase(
                screenWidth: screenWidth,
                usableHeight: usableHeight,
                title: slide.title,
                subtitle: slide.subtitle,
                buttonText: slide.buttonText,
                onTap: slide.onTap,
                onButtonPressed: slide.onTap,
                backgroundImage: slide.backgroundImage,
                watermarkIcon: slide.watermarkIcon,
                topLeading: slide.topLeading,
              );
            },
          ),

          // Indicador de Paginación (Dots) moderno y flotante
          if (slides.length > 1)
            Positioned(
              right: screenWidth * 0.045,
              bottom: usableHeight * 0.016,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(slides.length, (i) {
                  final bool isActive = i == _currentIndex;
                  final slideTipo = slides[i].tipo;

                  Color dotColor = Colors.white60;
                  if (isActive) {
                    dotColor = slideTipo == HeroBannerTipo.cultoEnVivo
                        ? const Color(0xFFEF5350)
                        : (slideTipo == HeroBannerTipo.versiculoDelDia
                              ? const Color(0xFFE5A023)
                              : const Color(0xFF64B5F6));
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    margin: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.008,
                    ),
                    width: isActive ? screenWidth * 0.045 : screenWidth * 0.016,
                    height: screenWidth * 0.016,
                    decoration: BoxDecoration(
                      color: dotColor,
                      borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardBase({
    required double screenWidth,
    required double usableHeight,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onTap,
    VoidCallback? onButtonPressed,
    String? backgroundImage,
    IconData? watermarkIcon,
    Widget? topLeading,
  }) {
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth,
        height: usableHeight * (widget.heightFactor ?? 0.195),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.045),
          gradient: widget.gradientColors != null
              ? LinearGradient(
                  colors: widget.gradientColors!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(screenWidth * 0.045),
          child: Stack(
            children: [
              // Imagen de fondo con superposición
              if (backgroundImage != null) ...[
                Positioned.fill(
                  child: Image.asset(
                    backgroundImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0.45),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ],

              // Ícono de marca de agua de fondo
              if (watermarkIcon != null)
                Positioned(
                  right: screenWidth * 0.04,
                  top: usableHeight * 0.015,
                  child: Icon(
                    watermarkIcon,
                    size: screenWidth * 0.18,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),

              // Contenido principal
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.042,
                  vertical: usableHeight * 0.013,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (topLeading != null) ...[
                          topLeading,
                          SizedBox(height: usableHeight * 0.006),
                        ],
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: usableHeight * 0.004),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.031,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    if (buttonText != null)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: amarilloOro,
                          foregroundColor: azulFondo,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.025,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.045,
                            vertical: usableHeight * 0.008,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onButtonPressed ?? onTap,
                        child: Text(
                          buttonText,
                          style: TextStyle(
                            fontSize: screenWidth * 0.033,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
}
