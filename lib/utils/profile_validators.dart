/// Validadores de perfil de usuario para ATRIO.
///
/// Incluye validación estricta de correo electrónico y validación de números
/// telefónicos de República Dominicana (prefijos 809, 829 y 849).
class ProfileValidators {
  ProfileValidators._();

  /// Dominios de correo sugeridos para autocompletado rápido en formularios.
  static const List<String> suggestedEmailDomains = <String>[
    '@gmail.com',
    '@hotmail.com',
    '@outlook.com',
    '@icloud.com',
    '@yahoo.com',
  ];

  /// Prefijos telefónicos válidos para República Dominicana.
  static const List<String> dominicanAreaCodes = <String>['809', '829', '849'];

  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$",
  );

  /// Valida que [value] tenga un formato de correo electrónico válido y sin
  /// puntos consecutivos. Retorna `true` si es válido.
  static bool isValidEmail(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.contains('..')) return false;
    return _emailRegExp.hasMatch(trimmed);
  }

  /// Extrae los 10 dígitos nacionales de un número dominicano, removiendo
  /// caracteres no numéricos y el código de país `+1` / `1` si está presente.
  /// Retorna `null` si no tiene exactamente 10 dígitos tras normalizar.
  static String? normalizeDominicanPhoneDigits(String? value) {
    if (value == null) return null;
    String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('1')) {
      digits = digits.substring(1);
    }
    if (digits.length != 10) return null;
    return digits;
  }

  /// Valida que [value] sea un teléfono celular válido de República Dominicana
  /// de 10 dígitos con prefijo `809`, `829` o `849`.
  static bool isValidDominicanPhone(String? value) {
    final digits = normalizeDominicanPhoneDigits(value);
    if (digits == null) return false;
    final prefix = digits.substring(0, 3);
    return dominicanAreaCodes.contains(prefix);
  }

  /// Formatea un teléfono dominicano válido como `809-555-1234`.
  /// Si no es válido, retorna el texto recortado original.
  static String formatDominicanPhone(String value) {
    final digits = normalizeDominicanPhoneDigits(value);
    if (digits == null) return value.trim();
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
  }

  /// Aplica un [domain] (ej. `'@icloud.com'`) al texto actual del correo,
  /// reemplazando cualquier `@...` parcial o existente al final.
  static String applyEmailDomain(String currentText, String domain) {
    final trimmed = currentText.trim();
    final normalizedDomain = domain.startsWith('@') ? domain : '@$domain';
    if (trimmed.isEmpty) return normalizedDomain;
    final atIndex = trimmed.indexOf('@');
    final localPart = atIndex >= 0 ? trimmed.substring(0, atIndex) : trimmed;
    return '$localPart$normalizedDomain';
  }
}
