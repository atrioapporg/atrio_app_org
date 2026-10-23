# Reglas de Desarrollo del Proyecto ATRIO

## Internacionalización Obligatoria (i18n) - Regla NO Negociable
La clase `AppLocalizations` de Flutter es la herramienta oficial y nativa para gestionar la internacionalización (i18n) y traducción de la aplicación ([Internationalizing Flutter apps](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)).

**REGLA NO NEGOCIABLE:**
- En cada cambio o actualización de código en cualquier pantalla, componente o widget de Atrio, **NUNCA** se deben dejar textos o cadenas de interfaz de usuario hardcodeados en el código Dart.
- Todo texto visible para el usuario (títulos, botones, placeholders, mensajes de estado, diálogos, etc.) debe:
  1. Definirse tanto en `lib/l10n/app_es.arb` como en `lib/l10n/app_en.arb`.
  2. Regenerar los archivos de localización ejecutando `flutter gen-l10n`.
  3. Consumirse en los widgets mediante `AppLocalizations.of(context)`.
