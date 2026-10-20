import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:atrio/main.dart';
import 'package:atrio/servicios/github_feedback_service.dart';
import 'package:atrio/utils/dispositivo_helper.dart';

class FeedbackHandler {
  static Future<void> procesarFeedback(
    UserFeedback feedback, {
    BuildContext? context,
  }) async {
    // 1. FORZAR CIERRE INMEDIATO DE BETTERFEEDBACK:
    // Restaura el viewport de la app al 100% eliminando la escala de captura (ScaleAndClip)
    final navContext = MyApp.navigatorKey.currentContext ?? context;
    if (navContext != null && navContext.mounted) {
      try {
        BetterFeedback.of(navContext).hide();
      } catch (_) {}
    }

    // 2. Notificación flotante de progreso (no bloqueante, no interrumpe la navegación ni el viewport)
    MyApp.scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 15),
        backgroundColor: const Color(0xFF072B4F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Color(0xFFE5A023),
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Enviando reporte a soporte técnico...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // 3. Extraer datos del formulario
      final extras = feedback.extra ?? {};
      final String tipo = extras['tipo'] ?? 'error';
      final String titulo = extras['titulo'] ?? 'Reporte de Usuario';
      final String descripcion = extras['descripcion'] ?? feedback.text;
      final String email = extras['email'] ?? 'No proporcionado';

      // 4. Metadatos del dispositivo
      final metadata = DispositivoHelper.obtenerMetadatos(navContext);

      // 5. Subir screenshot a GitHub
      final String fileName =
          'feedback_${DateTime.now().millisecondsSinceEpoch}.png';
      final String? screenshotUrl = await GithubFeedbackService.subirCaptura(
        screenshotBytes: feedback.screenshot,
        fileName: fileName,
      );

      // 6. Crear Issue en GitHub
      final bool exito = await GithubFeedbackService.crearIssue(
        titulo: titulo,
        tipo: tipo,
        descripcion: descripcion,
        emailContacto: email,
        metadataDispositivo: metadata,
        screenshotUrl: screenshotUrl,
      );

      // 7. Notificar resultado final al usuario
      MyApp.scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: exito
              ? const Color(0xFF072B4F)
              : const Color(0xFFD32F2F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          content: Row(
            children: [
              Icon(
                exito
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: const Color(0xFFE5A023),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exito
                      ? '¡Gracias! Tu reporte ha sido recibido por el equipo técnico.'
                      : 'No se pudo registrar el reporte. Por favor intenta de nuevo.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      MyApp.scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          content: Text(
            'Error al procesar el reporte. Inténtalo de nuevo.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }
}
