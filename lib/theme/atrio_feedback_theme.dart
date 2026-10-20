import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';

/// Tema personalizado para BetterFeedback adaptado a los colores corporativos de ATRIO.
class AtrioFeedbackTheme {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);

  static FeedbackThemeData get theme => FeedbackThemeData(
        background: azulFondo.withValues(alpha: 0.65),
        feedbackSheetColor: blancoFondo,
        feedbackSheetHeight: 0.42,
        activeFeedbackModeColor: amarilloOro,
        drawColors: [
          amarilloOro,
          const Color(0xFFE53935), // Rojo alerta (bugs)
          azulFondo,
          const Color(0xFF43A047), // Verde
          Colors.white,
        ],
        bottomSheetDescriptionStyle: const TextStyle(
          color: azulFondo,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        bottomSheetTextInputStyle: const TextStyle(
          color: azulFondo,
          fontSize: 14,
        ),
      );
}
