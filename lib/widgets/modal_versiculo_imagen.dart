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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: usableHeight * 0.02,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        child: Container(
          width: screenWidth * 0.98,
          height: usableHeight * 0.94,
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. IMAGEN DE FONDO
              Image.asset(widget.rutaImagenBlanca, fit: BoxFit.cover),

              // 2. ÁREA DE LAS PÁGINAS BLANCAS (Texto del versículo)
              Positioned(
                top: usableHeight * 0.18,
                bottom: usableHeight * 0.23,
                left: screenWidth * 0.12,
                right: screenWidth * 0.12,
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
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: usableHeight * 0.01),
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

                    return Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '«${versiculo.texto}»',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: screenWidth * 0.055,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            if (referenciaLimpia.isNotEmpty) ...[
                              SizedBox(height: usableHeight * 0.02),
                              Text(
                                referenciaLimpia,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 11, 17, 131),
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              SizedBox(height: usableHeight * 0.01),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 3. BOTÓN DE CERRAR DIRECTO (Esquina superior derecha)
              Positioned(
                top: usableHeight * 0.02,
                right: screenWidth * 0.03,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.02),
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
                      size: screenWidth * 0.055,
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
}
