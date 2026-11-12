/// Expresión regular canónica para UUID v4 / UUID RFC 4122 estándar
/// Formato: 8-4-4-4-12 caracteres hexadecimales.
final RegExp _uuidRegex = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  caseSensitive: false,
);

/// Expresión regular para rutas canónicas de unión de iglesias (`/c/<token>`, `/church/<token>`)
final RegExp _joinPathRegex = RegExp(
  r'/(?:c|church|join)/([a-zA-Z0-9_\-\.]+)',
  caseSensitive: false,
);

/// Expresión regular para tokens/códigos de iglesia válidos:
/// - UUID RFC 4122 (8-4-4-4-12 hex)
/// - Slugs con prefijo: church-18, iglesia-san-pedro
/// - Códigos oficiales públicos de iglesia (ej. PARROQ-1, ATRIO-DEMO, CENTRAL, SAN_PEDRO)
/// - IDs numéricos directos (ej. 1, 18, 22, 42)
final RegExp _validTokenPattern = RegExp(
  r'^(?:[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|(?:church|iglesia)[\-_][0-9a-zA-Z\-_]+|[A-Z0-9_\-]{2,30}|\d{1,8})$',
);

/// Comprueba si un token corresponde a un valor nulo, centinela o booleano defectuoso
/// emitido por serialización incompleta de Python/Odoo (ej: 'False', 'null', 'None').
bool isSentinelToken(String token) {
  final lower = token.trim().toLowerCase();
  return lower.isEmpty ||
      lower == 'false' ||
      lower == 'null' ||
      lower == 'none' ||
      lower == 'undefined';
}

/// Detecta si el payload escaneado corresponde a un QR defectuoso o desactualizado
/// que codifica valores centinelas de Odoo (ej. "/c/False" o "/c/null").
bool isOutdatedOrFalseQr(String? rawInput) {
  if (rawInput == null || rawInput.trim().isEmpty) return false;
  final lower = rawInput.trim().toLowerCase();
  return lower.contains('/c/false') ||
      lower.contains('/c/null') ||
      lower.contains('/c/none') ||
      lower == 'false' ||
      lower == 'null' ||
      lower == 'none';
}

/// Extrae y valida el token o identificador de vinculación (`church_code`, slug o UUID)
/// a partir de cualquier origen de código QR:
/// - URL canónica: "https://atrioapp.odoo19rd.com/c/PARROQ-1" o "https://app.atrio.org/c/6f1c2b1e-..."
/// - URL con trailing slash o parámetros: "https://atrioapp.odoo19rd.com/c/CENTRAL?ref=qr"
/// - URL de fallback/slug de iglesia: "https://atrioapp.odoo19rd.com/c/church-18" o "/c/18"
/// - Ruta relativa o esquema personalizado: "atrio://app/c/PARROQ-1" o "atrio://c/church-18"
/// - Query parameters: "https://atrioapp.odoo19rd.com/join?token=PARROQ-1"
/// - Texto plano del código oficial o UUID recibido directamente del payload del QR.
///
/// Retorna el [String] del token normalizado, o `null` si no es válido o es un valor centinela ('False').
String? joinTokenFromUri(String? rawInput) {
  if (rawInput == null || rawInput.trim().isEmpty) {
    return null;
  }

  final trimmed = rawInput.trim();

  // Caso 1: Extracción por ruta canónica /c/<token>, /church/<token> o /join/<token>
  final pathMatch = _joinPathRegex.firstMatch(trimmed);
  if (pathMatch != null && pathMatch.groupCount >= 1) {
    final token = pathMatch.group(1)?.trim();
    if (token != null && token.isNotEmpty && !isSentinelToken(token)) {
      final uuidInToken = _uuidRegex.firstMatch(token);
      if (uuidInToken != null) {
        return uuidInToken.group(0)!.toLowerCase();
      }
      if (_validTokenPattern.hasMatch(token)) {
        return token;
      }
    }
  }

  // Caso 2: Parseo formal como URI para query parameters o último path segment
  try {
    final uri = Uri.parse(trimmed);

    final queryToken = uri.queryParameters['token'] ??
        uri.queryParameters['c'] ??
        uri.queryParameters['church_id'] ??
        uri.queryParameters['code'];
    if (queryToken != null &&
        queryToken.trim().isNotEmpty &&
        !isSentinelToken(queryToken)) {
      final sanitized = queryToken.trim();
      final uuidInQuery = _uuidRegex.firstMatch(sanitized);
      if (uuidInQuery != null) {
        return uuidInQuery.group(0)!.toLowerCase();
      }
      if (_validTokenPattern.hasMatch(sanitized)) {
        return sanitized;
      }
    }

    final host = uri.host.toLowerCase();
    final scheme = uri.scheme.toLowerCase();
    final isAtrioDomain = host.contains('atrio') ||
        host.contains('odoo19rd') ||
        scheme == 'atrio';

    if (isAtrioDomain && uri.pathSegments.isNotEmpty) {
      final lastSegment = uri.pathSegments.last.trim();
      if (!isSentinelToken(lastSegment)) {
        final uuidInSegment = _uuidRegex.firstMatch(lastSegment);
        if (uuidInSegment != null) {
          return uuidInSegment.group(0)!.toLowerCase();
        }
        if (_validTokenPattern.hasMatch(lastSegment)) {
          return lastSegment;
        }
      }
    }
  } catch (_) {}

  // Caso 3: Fallback por coincidencia directa de UUID v4 en la cadena completa
  final directMatch = _uuidRegex.firstMatch(trimmed);
  if (directMatch != null) {
    return directMatch.group(0)!.toLowerCase();
  }

  // Caso 4: Texto plano que sea un token o church_code directo (ej: "PARROQ-1", "CENTRAL", "church-18", o ID numérico)
  // Se descartan cadenas con esquemas ajenos, palabras reservadas o valores centinela
  if (!isSentinelToken(trimmed) &&
      _validTokenPattern.hasMatch(trimmed) &&
      !trimmed.contains('/') &&
      !trimmed.contains(':')) {
    return trimmed;
  }

  return null;
}
