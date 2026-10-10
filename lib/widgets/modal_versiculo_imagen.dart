import 'package:flutter/material.dart';
import 'package:atrio/modelos/versiculo_dia.dart';
import 'package:atrio/servicios/versiculo_service.dart';

class ModalVersiculoImagen extends StatefulWidget {
  final String rutaImagenBlanca;
  final VersiculoDia? versiculo;

  const ModalVersiculoImagen({
    super.key,
    this.rutaImagenBlanca = 'assets/images/jesus_libro_blanco.png',
    this.versiculo,
  });

  /// Muestra el modal del versículo del día sin tiempo de autocierre.
  static void mostrar(
    BuildContext context, {
    String rutaImagenBlanca = 'assets/images/jesus_libro_blanco.png',
    VersiculoDia? versiculo,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (ctx) => ModalVersiculoImagen(
        rutaImagenBlanca: rutaImagenBlanca,
        versiculo: versiculo,
      ),
    );
  }

  @override
  State<ModalVersiculoImagen> createState() => _ModalVersiculoImagenState();
}

class _ModalVersiculoImagenState extends State<ModalVersiculoImagen> {
  final VersiculoService _versiculoService = VersiculoService();
  late Future<VersiculoDia> _versiculoFuture;

  @override
  void initState() {
    super.initState();
    if (widget.versiculo != null) {
      _versiculoFuture = Future.value(widget.versiculo!);
    } else {
      _cargarVersiculo();
    }
  }

  void _cargarVersiculo() {
    setState(() {
      _versiculoFuture = _versiculoService.obtenerVersiculoDelDia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final safeAreaTop = media.padding.top;
    final safeAreaBottom = media.padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    // Proporción exacta de la imagen de fondo (688 x 1504)
    const imageAspectRatio = 688.0 / 1504.0;

    // Tamaño máximo dentro de la pantalla para mantener la proporción sin recortar la imagen
    final maxCardWidth = screenWidth * 0.94;
    final maxCardHeight = usableHeight * 0.96;

    double cardHeight = maxCardHeight;
    double cardWidth = cardHeight * imageAspectRatio;

    if (cardWidth > maxCardWidth) {
      cardWidth = maxCardWidth;
      cardHeight = cardWidth / imageAspectRatio;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardWidth * 0.05),
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. IMAGEN DE FONDO
                Image.asset(widget.rutaImagenBlanca, fit: BoxFit.fill),

                // 2. ÁREA DE LAS PÁGINAS BLANCAS (Perfectamente centrada en el libro abierto)
                Positioned(
                  top: cardHeight * 0.235,
                  bottom: cardHeight * 0.355,
                  left: cardWidth * 0.13,
                  right: cardWidth * 0.13,
                  child: FutureBuilder<VersiculoDia>(
                    future: _versiculoFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF072B4F),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'No se pudo cargar el versículo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: (cardWidth * 0.050).clamp(
                                    12.0,
                                    18.0,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: cardHeight * 0.01),
                              IconButton(
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: Color(0xFF072B4F),
                                  size: 32,
                                ),
                                onPressed: _cargarVersiculo,
                              ),
                            ],
                          ),
                        );
                      }

                      final versiculo = snapshot.data!;
                      final String referenciaLimpia = versiculo.referencia
                          .trim()
                          .toUpperCase();

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return Scrollbar(
                            thumbVisibility: false,
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: cardWidth * 0.03,
                                      vertical: cardHeight * 0.015,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          '«${versiculo.texto}»',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: (cardWidth * 0.052).clamp(
                                              14.0,
                                              22.0,
                                            ),
                                            fontWeight: FontWeight.w700,
                                            height: 1.3,
                                          ),
                                        ),
                                        if (referenciaLimpia.isNotEmpty) ...[
                                          SizedBox(height: cardHeight * 0.015),
                                          Text(
                                            referenciaLimpia,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: const Color.fromARGB(
                                                255,
                                                11,
                                                17,
                                                131,
                                              ),
                                              fontSize: (cardWidth * 0.042)
                                                  .clamp(12.0, 18.0),
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // 3. BOTÓN DE CERRAR DIRECTO (Esquina superior derecha)
                Positioned(
                  top: cardHeight * 0.02,
                  right: cardWidth * 0.03,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(cardWidth * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: cardWidth * 0.055,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
