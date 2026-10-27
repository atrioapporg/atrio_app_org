import 'package:flutter/material.dart';

import '../modelos/church_recommendation_model.dart';
import 'inicio_atrio_screen.dart';

/// Pantalla de confirmación de recomendación exitosa (Imagen 2 de referencia).
/// Optimizada bajo estándares de UI/UX para Flutter:
/// - Micro-animación de entrada (Scale & Fade In)
/// - Jerarquía visual clara con contraste cromático corporativo
/// - Respeto al escalado de texto y accesibilidad
class ExitoRecomendacionScreen extends StatelessWidget {
  static const String routeName = 'exito_recomendacion_screen';

  final ChurchRecommendationModel? recommendation;

  const ExitoRecomendacionScreen({super.key, this.recommendation});

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color azulOscuro = Color(0xFF03182E);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color amarilloClaro = Color(0xFFFEF3C7);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color textoGris = Color(0xFF64748B);
  static const Color textoDorado = Color(0xFFB45309);

  @override
  Widget build(BuildContext context) {
    final rec =
        recommendation ??
        ModalRoute.of(context)?.settings.arguments
            as ChurchRecommendationModel?;

    final churchName = (rec?.name != null && rec!.name.isNotEmpty)
        ? rec.name
        : 'tu iglesia';
    final address = (rec?.address != null && rec!.address!.isNotEmpty)
        ? rec.address!
        : (rec?.city != null
              ? '${rec!.city}, ${rec.country ?? ""}'
              : 'Dirección registrada en Google Maps');
    final daysLeft = rec?.daysLeft ?? 30;

    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: azulOscuro,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? 40 : 20,
              vertical: 24,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.88, end: 1.0),
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: ((scale - 0.88) / 0.12).clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 36,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 36,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ícono Pin Dorado con Halo Suave (Imagen 2)
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: amarilloClaro,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: amarilloOro.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: amarilloOro,
                          size: 46,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Título Principal
                      const Text(
                        '¡Gracias por recomendar tu iglesia!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textoOscuro,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtítulo con Nombre de la Iglesia
                      Text(
                        'Recomendaste $churchName.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Frase de Plazo y Compromiso de Atrio (Texto Dorado Oficial)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Atrio la va a contactar para sumarla (quedan $daysLeft días). Cuando se inscriba te avisamos y tu pedido de ingreso ya estará enviado.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: textoDorado,
                            fontSize: 13.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Fila de Dirección con Ícono de Ubicación
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.place_outlined,
                                size: 16,
                                color: textoGris,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                address,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: textoGris,
                                  fontSize: 12.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Botón Primario: Ir al Inicio
                      SizedBox(
                        width: 180,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azulFondo,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: azulFondo.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              InicioAtrioScreen.routeName,
                              (route) => false,
                            );
                          },
                          child: const Text(
                            'Ir al Inicio',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
