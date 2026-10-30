# Reglas de Desarrollo del Proyecto ATRIO

## Regla Inquebrantable: Internacionalización y Localización (i18n & l10n)

> **OBLIGATORIO Y NO NEGOCIABLE:** En toda creación, modificación o refactorización de pantallas, componentes o widgets en el proyecto ATRIO, se debe cumplir estrictamente con lo siguiente:

1. **Cero Textos Hardcodeados:**
   - Prohibido dejar cadenas literales para textos visibles en la UI (títulos, botones, labels, placeholders, mensajes de error, alertas).
   - Todo texto debe declararse en [app_es.arb](file:///c:/APPS/ATRIO/lib/l10n/app_es.arb) y [app_en.arb](file:///c:/APPS/ATRIO/lib/l10n/app_en.arb).
   - Consumirse siempre a través de `AppLocalizations.of(context)!`.

2. **Plurales y Género (ICU message syntax con intl 0.20):**
   - No hacer concatenaciones ni ternarios manuales (`count == 1 ? ... : ...`).
   - Usar `{count, plural, =0{...} =1{...} other{...}}` y `{gender, select, male{...} female{...} other{...}}` en los archivos `.arb`.

3. **Formato y Análisis de Fechas, Horas y Números (`intl 0.20`):**
   - Prohibido formatear fechas con `"${date.day}/${date.month}/..."` o números con `toString()`.
   - Emplear siempre `DateFormat` y `NumberFormat` de `intl: ^0.20.3` pasando el locale activo (`Localizations.localeOf(context).toString()`).

4. **Soporte Bidireccional (Bidi / RTL y LTR):**
   - Usar clases direccionales: `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, etc., en lugar de valores absolutos (`left`/`right`) para garantizar correcta adaptabilidad RTL.
   - Usar `BidiFormatter` para contenido bidireccional mixto cuando aplique.

5. **Regeneración de Código:**
   - Cada vez que se agreguen o cambien cadenas en `.arb`, regenerar con `flutter gen-l10n`.

---
*Para ver el detalle completo de reglas del proyecto, consulta [.agents/rules/reglas_atrio.md](file:///c:/APPS/ATRIO/.agents/rules/reglas_atrio.md).*
