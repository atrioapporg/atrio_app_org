/// Expresión regular canónica para UUID v4 / UUID RFC 4122 estándar
/// Formato: 8-4-4-4-12 caracteres hexadecimales.
final RegExp _uuidRegex = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  caseSensitive: false,
);

/// Expresión regular para rutas canónicas de unión de iglesias (`/c/<uuid>`)
final RegExp _joinPathRegex = RegExp(

  r'/c/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})',
  caseSensitive: false,
);

/// Extrae y valida el UUID de vinculación a partir de cualquier origen:
/// - URL canónica: "https://atrioapp.odoo19rd.com/c/6f1c2b1e-8a3d-4b7e-9c55-2d0e7a41c3f9"
/// - Ruta relativa o esquema personalizado: "atrio://app/c/6f1c2b1e-..."
/// - Texto plano del UUID recibido directamente del payload del QR.
///
/// Retorna el [String] del UUID normalizado en minúsculas, o `null` si no es válido.
String? joinTokenFromUri(String? rawInput) {
  if (rawInput == null || rawInput.trim().isEmpty) {
    return null;
  }

  final trimmed = rawInput.trim();

  // Caso 1: Extracción por ruta canónica /c/<uuid> (prioridad semántica de deep link)
  final pathMatch = _joinPathRegex.firstMatch(trimmed);
  if (pathMatch != null && pathMatch.groupCount >= 1) {
    final token = pathMatch.group(1);
    if (token != null && _uuidRegex.hasMatch(token)) {
      return token.toLowerCase();
    }
  }

  // Caso 2: Parseo como URI formal para extraer el último segmento de ruta
  try {
    final uri = Uri.parse(trimmed);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      final lastSegment = segments.last;
      if (_uuidRegex.hasMatch(lastSegment)) {
        return lastSegment.toLowerCase();
      }
    }
  } catch (_) {
    // Si no es un URI sintácticamente estándar, continuamos con fallback regex
  }

  // Caso 3: Fallback por coincidencia directa de UUID en la cadena completa
  final directMatch = _uuidRegex.firstMatch(trimmed);
  if (directMatch != null) {
    return directMatch.group(0)?.toLowerCase();
  }

  return null;
}
