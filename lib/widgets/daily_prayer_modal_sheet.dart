import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Modal elegante y moderno para el despliegue in-app de la Oración Matutina / Devocional Diario.
///
/// Diseñado con base en la guía de estilos ATRIO y la estética de la imagen adjunta:
/// - Fondo blanco limpio con esquinas suavemente redondeadas (`Radius.circular(28)`).
/// - Insignia circular destacada superior con icono sagrado/oración (`Icons.wb_sunny_rounded` / `Icons.verified_rounded`),
///   borde perimetral fino y halo suave con tonos verde esmeralda y oro celestial.
/// - Tipografía jerárquica: Título ministerial en azul imperial profundo (`0xFF072B4F`),
///   subtítulo temático en verde pastoral (`0xFF15803D`) y cuerpo de oración con interletrado armónico.
/// - Contenedor con versículo bíblico formateado con estilo devocional (fondo marfil suave `0xFFFDFBF7`, comillas y referencia).
/// - Botón principal con borde delineado redondeado (OutlinedButton/ElevatedButton) para navegar al pasaje bíblico,
///   y botón de texto limpio "Amén" / "Cerrar".
/// - Cumple con la regla inquebrantable de Cero Textos Hardcodeados (`AppLocalizations`).
class DailyPrayerModalSheet extends StatelessWidget {
  final String title;
  final String reference;
  final String body;
  final VoidCallback? onGoToChapter;
  final VoidCallback? onAmen;

  const DailyPrayerModalSheet({
    super.key,
    required this.title,
    required this.reference,
    required this.body,
    this.onGoToChapter,
    this.onAmen,
  });

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFFFFFF);
  static const Color verdeEsmeralda = Color(0xFF15803D);
  static const Color verdeBadgeFondo = Color(0xFFDCFCE7);
  static const Color verdeBadgeBorde = Color(0xFF22C55E);

  static Future<void> mostrar({
    required BuildContext context,
    required String title,
    required String reference,
    required String body,
    VoidCallback? onGoToChapter,
    VoidCallback? onAmen,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DailyPrayerModalSheet(
        title: title,
        reference: reference,
        body: body,
        onGoToChapter: () {
          Navigator.pop(ctx);
          onGoToChapter?.call();
        },
        onAmen: () {
          Navigator.pop(ctx);
          onAmen?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final usableHeight =
        screenHeight - MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: true,
      child: Container(
        width: screenWidth,
        margin: EdgeInsetsDirectional.only(
          bottom: safeAreaBottom > 0 ? 0 : 8,
        ),
        decoration: BoxDecoration(
          color: blancoFondo,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(screenWidth * 0.075),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsetsDirectional.fromSTEB(
          screenWidth * 0.065,
          usableHeight * 0.02,
          screenWidth * 0.065,
          usableHeight * 0.025 + safeAreaBottom,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra indicadora de arrastre sutil y moderna
              Center(
                child: Container(
                  width: screenWidth * 0.11,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.022),

              // Insignia circular de cabecera con estilo de la imagen adjunta
              Container(
                width: screenWidth * 0.155,
                height: screenWidth * 0.155,
                decoration: BoxDecoration(
                  color: verdeBadgeFondo,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: verdeBadgeBorde,
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: verdeBadgeBorde.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.wb_sunny_rounded,
                    color: verdeEsmeralda,
                    size: screenWidth * 0.078,
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.016),

              // Título de la Notificación / Oración Matutina
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.052,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: usableHeight * 0.006),

              // Subtítulo con referencia bíblica y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: verdeEsmeralda,
                    size: screenWidth * 0.038,
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  Text(
                    reference.isNotEmpty
                        ? reference
                        : (l10n?.oracionMatutinaSubtitulo ??
                            'Oración y devocional diario'),
                    style: TextStyle(
                      color: verdeEsmeralda,
                      fontSize: screenWidth * 0.034,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: usableHeight * 0.018),

              // Tarjeta estilizada con el cuerpo de la oración / reflexión
              Container(
                width: double.infinity,
                padding: EdgeInsetsDirectional.all(screenWidth * 0.045),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F2),
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  border: Border.all(
                    color: const Color(0xFFEBE5D8),
                    width: 1,
                  ),
                ),
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF334155),
                    fontSize: screenWidth * 0.038,
                    height: 1.48,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.024),

              // Botón estilizado delineado idéntico a la imagen adjunta: "Ir al capítulo"
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: azulFondo,
                    side: const BorderSide(color: azulFondo, width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    l10n?.irAlCapitulo ?? 'Ir al capítulo',
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: onGoToChapter,
                ),
              ),
              SizedBox(height: usableHeight * 0.01),

              // Botón inferior de texto limpio "Amén"
              TextButton(
                onPressed: onAmen,
                child: Text(
                  l10n?.amen ?? 'Amén',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.w600,
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

