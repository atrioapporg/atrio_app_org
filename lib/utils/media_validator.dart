import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Resultado detallado de validación de archivos multimedia (imágenes o videos).
class MediaValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? friendlySuggestion;
  final double sizeInMB;
  final Duration? duration;
  final bool isTooShort;
  final bool isTooLong;

  const MediaValidationResult({
    required this.isValid,
    this.errorMessage,
    this.friendlySuggestion,
    required this.sizeInMB,
    this.duration,
    this.isTooShort = false,
    this.isTooLong = false,
  });

  factory MediaValidationResult.success({
    required double sizeInMB,
    Duration? duration,
  }) {
    return MediaValidationResult(
      isValid: true,
      sizeInMB: sizeInMB,
      duration: duration,
    );
  }

  factory MediaValidationResult.imageExceeded({
    required double sizeInMB,
    required double maxMB,
  }) {
    return MediaValidationResult(
      isValid: false,
      sizeInMB: sizeInMB,
      errorMessage:
          'La imagen pesa ${sizeInMB.toStringAsFixed(2)} MB, superando el límite de ${maxMB.toStringAsFixed(0)} MB.',
      friendlySuggestion:
          'Para optimizar el uso de red y almacenamiento de la comunidad, selecciona una imagen con un peso no mayor a ${maxMB.toStringAsFixed(0)} MB.',
    );
  }

  factory MediaValidationResult.videoTooLong({
    required Duration duration,
    required double sizeInMB,
    String? channelHandle,
  }) {
    final minutos = duration.inMinutes;
    final segundos = duration.inSeconds % 60;
    final duracionStr = '${minutos}m ${segundos.toString().padLeft(2, '0')}s';

    return MediaValidationResult(
      isValid: false,
      isTooLong: true,
      sizeInMB: sizeInMB,
      duration: duration,
      errorMessage:
          'El video dura $duracionStr, superando el límite de 5 minutos para subidas directas.',
      friendlySuggestion:
          'Para videos mayores a 5 minutos, te sugerimos emitir vía streaming o subir el video al canal oficial de la iglesia en YouTube (${channelHandle ?? '@AtrioIglesia'}) y compartir el enlace en ATRIO.',
    );
  }

  factory MediaValidationResult.videoTooShort({
    required Duration duration,
    required double sizeInMB,
  }) {
    return MediaValidationResult(
      isValid: false,
      isTooShort: true,
      sizeInMB: sizeInMB,
      duration: duration,
      errorMessage:
          'El video dura ${duration.inSeconds} segundos. La duración mínima requerida es de 10 segundos.',
      friendlySuggestion:
          'Selecciona un video que tenga una duración de al menos 10 segundos para asegurar una reproducción congregacional adecuada.',
    );
  }
}

/// Validador y guardián de recursos multimedia para ATRIO.
/// Previene abusos de almacenamiento y ancho de banda por parte de usuarios malintencionados.
class MediaValidator {
  const MediaValidator._();

  /// Límite máximo para imágenes: 3 Megabytes (3 * 1024 * 1024 bytes).
  static const int maxImageBytes = 3 * 1024 * 1024;
  static const double maxImageMB = 3.0;

  /// Límites para videos individuales subidos directamente:
  /// - Mínimo: 10 segundos.
  /// - Máximo: 5 minutos (300 segundos).
  static const Duration minVideoDuration = Duration(seconds: 10);
  static const Duration maxVideoDuration = Duration(minutes: 5);

  /// Valida el tamaño en bytes de una imagen.
  static MediaValidationResult validateImageBytes(Uint8List bytes) {
    final double sizeInMB = bytes.lengthInBytes / (1024 * 1024);
    if (bytes.lengthInBytes > maxImageBytes) {
      return MediaValidationResult.imageExceeded(
        sizeInMB: sizeInMB,
        maxMB: maxImageMB,
      );
    }
    return MediaValidationResult.success(sizeInMB: sizeInMB);
  }

  /// Valida un archivo [XFile] de imagen.
  static Future<MediaValidationResult> validateImageFile(XFile file) async {
    final bytes = await file.readAsBytes();
    return validateImageBytes(bytes);
  }

  /// Extrae la duración exacta en segundos de un contenedor MP4 analizando
  /// el átomo `mvhd` (Movie Header Atom, ISO/IEC 14496-12) en puro Dart.
  static Duration? extractMp4Duration(Uint8List bytes) {
    try {
      final data = ByteData.sublistView(bytes);

      Duration? foundDuration;

      void searchAtom(int start, int end) {
        int p = start;
        while (p + 8 <= end) {
          int size = data.getUint32(p);
          if (size == 0) size = end - p;
          if (size < 8) break;

          final tag = String.fromCharCodes(bytes.sublist(p + 4, p + 8));
          if (tag == 'moov' || tag == 'trak' || tag == 'mdia') {
            searchAtom(p + 8, p + size);
            if (foundDuration != null) return;
          } else if (tag == 'mvhd') {
            final version = bytes[p + 8];
            int timescale;
            int durationUnits;
            if (version == 0) {
              timescale = data.getUint32(p + 20);
              durationUnits = data.getUint32(p + 24);
            } else {
              timescale = data.getUint32(p + 28);
              durationUnits = data.getUint64(p + 32);
            }
            if (timescale > 0) {
              final seconds = durationUnits / timescale;
              foundDuration = Duration(milliseconds: (seconds * 1000).round());
            }
            return;
          }
          p += size;
        }
      }

      searchAtom(0, bytes.length);
      return foundDuration;
    } catch (e) {
      debugPrint('[MediaValidator] Error extrayendo duración MP4: $e');
      return null;
    }
  }

  /// Valida las restricciones de duración de un video individual (entre 10s y 5m).
  static MediaValidationResult validateVideoDuration({
    required Duration duration,
    required double sizeInMB,
    String? channelHandle,
  }) {
    if (duration < minVideoDuration) {
      return MediaValidationResult.videoTooShort(
        duration: duration,
        sizeInMB: sizeInMB,
      );
    }
    if (duration > maxVideoDuration) {
      return MediaValidationResult.videoTooLong(
        duration: duration,
        sizeInMB: sizeInMB,
        channelHandle: channelHandle,
      );
    }
    return MediaValidationResult.success(
      sizeInMB: sizeInMB,
      duration: duration,
    );
  }

  /// Valida un archivo [XFile] de video, extrayendo su duración si es MP4
  /// o utilizando la duración provista externamente.
  static Future<MediaValidationResult> validateVideoFile(
    XFile file, {
    Duration? knownDuration,
    String? channelHandle,
  }) async {
    final length = await file.length();
    final double sizeInMB = length / (1024 * 1024);

    Duration? dur = knownDuration;
    if (dur == null && file.name.toLowerCase().endsWith('.mp4')) {
      final bytes = await file.readAsBytes();
      dur = extractMp4Duration(bytes);
    }

    if (dur != null) {
      return validateVideoDuration(
        duration: dur,
        sizeInMB: sizeInMB,
        channelHandle: channelHandle,
      );
    }

    // Si la duración no pudo determinarse pero se cuenta con el archivo
    return MediaValidationResult.success(sizeInMB: sizeInMB);
  }

  // ===========================================================================
  // MODALES Y ALERTAS AMIGABLES (MATERIAL 3)
  // ===========================================================================

  /// Muestra un modal informativo cuando la imagen seleccionada excede los 3 MB.
  static Future<void> showImageSizeExceededModal(
    BuildContext context, {
    required double sizeInMB,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.image_not_supported_rounded,
            color: Colors.amber.shade900,
            size: screenWidth * 0.08,
          ),
        ),
        title: Text(
          'Imagen demasiado pesada',
          style: TextStyle(
            fontSize: screenWidth * 0.046,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF072B4F),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'La imagen seleccionada tiene un peso de ${sizeInMB.toStringAsFixed(2)} MB, el cual supera el límite permitido de 3 MB.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.034,
                  color: Colors.grey.shade800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF072B4F).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: Color(0xFF072B4F), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este límite protege la velocidad de carga de la app para todos los feligreses.',
                        style: TextStyle(
                          fontSize: screenWidth * 0.030,
                          color: const Color(0xFF072B4F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Entendido, elegiré otra'),
          ),
        ],
      ),
    );
  }

  /// Muestra un modal pedagógico y amigable sugiriendo streaming vía YouTube
  /// o subir el video al canal oficial cuando excede los 5 minutos.
  static Future<void> showVideoDurationExceededModal(
    BuildContext context, {
    required Duration duration,
    String? channelHandle,
    VoidCallback? onUseYoutubeStreaming,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final minutos = duration.inMinutes;
    final segundos = duration.inSeconds % 60;
    final duracionStr = '${minutos}m ${segundos.toString().padLeft(2, '0')}s';
    final canal = channelHandle ?? '@AtrioIglesia';

    return showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
        ),
        titlePadding: EdgeInsets.fromLTRB(
          screenWidth * 0.06,
          screenWidth * 0.06,
          screenWidth * 0.06,
          0,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06,
          vertical: 12,
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFC4302B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.ondemand_video_rounded,
                color: Color(0xFFC4302B),
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Video mayor a 5 minutos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.046,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF072B4F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Duración detectada: $duracionStr',
              style: TextStyle(
                fontSize: screenWidth * 0.032,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para garantizar que la aplicación permanezca rápida, ligera y accesible para toda la comunidad, los videos individuales subidos directamente tienen un límite máximo de 5 minutos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.033,
                  color: Colors.grey.shade800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tips_and_updates_rounded,
                            color: Color(0xFFE5A023), size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Recomendaciones amigables:',
                            style: TextStyle(
                              fontSize: screenWidth * 0.032,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF072B4F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRecomendacionItem(
                      icon: Icons.sensors_rounded,
                      texto:
                          'Haz una transmisión en vivo vía YouTube Live desde OBS / vMix.',
                      screenWidth: screenWidth,
                    ),
                    const SizedBox(height: 6),
                    _buildRecomendacionItem(
                      icon: Icons.video_library_rounded,
                      texto:
                          'Sube este video al canal oficial de la iglesia en YouTube ($canal) y pega aquí el enlace.',
                      screenWidth: screenWidth,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC4302B),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              if (onUseYoutubeStreaming != null) {
                onUseYoutubeStreaming();
              }
            },
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('Usar enlace de YouTube'),
          ),
        ],
      ),
    );
  }

  /// Muestra un modal cuando el video es menor a 10 segundos.
  static Future<void> showVideoTooShortModal(
    BuildContext context, {
    required Duration duration,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
        ),
        icon: const Icon(
          Icons.timelapse_rounded,
          color: Color(0xFF072B4F),
          size: 36,
        ),
        title: Text(
          'Video demasiado corto',
          style: TextStyle(
            fontSize: screenWidth * 0.046,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF072B4F),
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'El video dura solo ${duration.inSeconds} segundos. La duración mínima para un contenido congregacional es de 10 segundos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.034,
              color: Colors.grey.shade800,
              height: 1.35,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  static Widget _buildRecomendacionItem({
    required IconData icon,
    required String texto,
    required double screenWidth,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF072B4F)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: screenWidth * 0.030,
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
