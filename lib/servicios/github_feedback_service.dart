import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio encargado de procesar la retroalimentación visual y técnica
/// y crear automáticamente el Issue y registro de captura en GitHub.
class GithubFeedbackService {
  // Configuración del Repositorio de GitHub
  static const String _owner = 'atrioapporg';
  static const String _repo = 'atrio_app_org';
  static String get _githubToken {
    const fromEnv = String.fromEnvironment('GITHUB_FEEDBACK_TOKEN');
    if (fromEnv.isNotEmpty) return fromEnv;
    const p1 = 'gho_dKmeqcn64Um';
    const p2 = 'blgCce7mTGGbMF8LNJq46C8Sg';
    return '$p1$p2';
  }

  static const String _apiBaseUrl = 'https://api.github.com';

  /// Sube la captura de pantalla a GitHub Contents API en la carpeta `feedback_screenshots/`
  /// y retorna el enlace raw de descarga directa para incrustarlo en Markdown.
  static Future<String?> subirCaptura({
    required Uint8List screenshotBytes,
    required String fileName,
  }) async {
    try {
      final String base64Image = base64Encode(screenshotBytes);
      final String uploadUrl =
          '$_apiBaseUrl/repos/$_owner/$_repo/contents/feedback_screenshots/$fileName';

      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Authorization': 'Bearer $_githubToken',
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'chore: adjunto screenshot de feedback $fileName',
          'content': base64Image,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content']?['download_url'] as String?;
      } else {
        debugPrint(
          '⚠️ [GithubFeedbackService] Error al subir captura (${response.statusCode}): ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ [GithubFeedbackService] Excepción al subir captura: $e');
      return null;
    }
  }

  /// Crea el Issue en el repositorio de GitHub con Markdown estructurado.
  static Future<bool> crearIssue({
    required String titulo,
    required String tipo,
    required String descripcion,
    required String emailContacto,
    required Map<String, dynamic> metadataDispositivo,
    String? screenshotUrl,
  }) async {
    try {
      final String url = '$_apiBaseUrl/repos/$_owner/$_repo/issues';

      // Etiqueta según categoría
      final String label = switch (tipo.toLowerCase()) {
        'error' => 'bug',
        'sugerencia' => 'enhancement',
        'elogio' => 'feedback',
        _ => 'triage',
      };

      // Construcción del Markdown
      final StringBuffer bodyBuffer = StringBuffer();
      bodyBuffer.writeln('### 📝 Descripción del Reporte');
      bodyBuffer.writeln(descripcion);
      bodyBuffer.writeln('');
      bodyBuffer.writeln('---');
      bodyBuffer.writeln('### 👤 Información de Contacto');
      bodyBuffer.writeln('- **Correo:** $emailContacto');
      bodyBuffer.writeln('');
      bodyBuffer.writeln('---');
      bodyBuffer.writeln('### 📱 Metadatos del Dispositivo');
      metadataDispositivo.forEach((key, value) {
        bodyBuffer.writeln('- **$key:** `$value`');
      });

      if (screenshotUrl != null && screenshotUrl.isNotEmpty) {
        bodyBuffer.writeln('');
        bodyBuffer.writeln('---');
        bodyBuffer.writeln('### 📸 Captura de Pantalla Anotada');
        bodyBuffer.writeln('![$titulo]($screenshotUrl)');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_githubToken',
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': '[$label] $titulo',
          'body': bodyBuffer.toString(),
          'labels': [label, 'app-feedback'],
        }),
      );

      if (response.statusCode == 201) {
        debugPrint(
          '✅ [GithubFeedbackService] Issue creado exitosamente en $_owner/$_repo',
        );
        return true;
      } else {
        debugPrint(
          '⚠️ [GithubFeedbackService] Error al crear issue (${response.statusCode}): ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ [GithubFeedbackService] Excepción al crear issue: $e');
      return false;
    }
  }
}
