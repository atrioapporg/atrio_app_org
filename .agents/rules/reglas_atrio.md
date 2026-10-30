# Reglas de Desarrollo del Proyecto ATRIO

## Internacionalización y Localización (i18n & l10n) - Regla Inquebrantable

> **OBLIGATORIO Y NO NEGOCIABLE:** Aplica estrictamente a **toda creación, modificación o refactorización** de pantallas, vistas, componentes o widgets en ATRIO.

El proyecto utiliza `AppLocalizations` junto con `intl: ^0.20.3` (`flutter_localizations`) como estándar único y obligatorio ([Internationalizing Flutter apps](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)).

---

### 1. Cero Textos Hardcodeados (Zero Hardcoded Strings)
- **NUNCA** dejar cadenas de texto, mensajes de error, etiquetas, títulos, botones, tooltips, placeholders o diálogos hardcodeados en el código Dart.
- Todo texto que se muestre al usuario debe definirse en:
  - `lib/l10n/app_es.arb` (Plantilla base en español).
  - `lib/l10n/app_en.arb` (Traducción en inglés).
- Siempre debe consumirse en la UI mediante:
  ```dart
  AppLocalizations.of(context)!.miCadena
  ```

---

### 2. Soporte de Plurales y Selección por Género
- **Plurales (`{count, plural, ...}`):**
  - No concatenar cadenas ni hacer `count == 1 ? '1 elemento' : '$count elementos'` en Dart.
  - Usar la sintaxis estándar ARB / ICU de `intl`:
    ```json
    "itemsCount": "{count, plural, =0{No hay elementos} =1{1 elemento} other{{count} elementos}}",
    "@itemsCount": {
      "placeholders": {
        "count": { "type": "num", "format": "compact" }
      }
    }
    ```
- **Género (`{gender, select, ...}`):**
  - Utilizar sintaxis select para variaciones gramaticales de género cuando aplique:
    ```json
    "userRole": "{gender, select, male{Hermano} female{Hermana} other{Miembro}}",
    "@userRole": {
      "placeholders": {
        "gender": { "type": "String" }
      }
    }
    ```

---

### 3. Formato y Análisis de Fechas, Horas y Números (`intl 0.20`)
- **NUNCA** formatear fechas manualmente con `"${date.day}/${date.month}/${date.year}"` ni números con `toString()`.
- Usar las utilidades de formato de `intl` respetando el Locale activo:
  - **Fechas / Horas (`DateFormat`):**
    ```dart
    final locale = Localizations.localeOf(context).toString();
    final formattedDate = DateFormat.yMMMMd(locale).format(fecha);
    final formattedTime = DateFormat.jm(locale).format(fecha);
    ```
  - **Números, Monedas y Porcentajes (`NumberFormat`):**
    ```dart
    final currency = NumberFormat.simpleCurrency(locale: locale).format(monto);
    final percent = NumberFormat.percentPattern(locale).format(ratio);
    ```
  - **Análisis (Parsing):** Usar `DateFormat.parse` / `NumberFormat.parse` configurados con el locale correspondiente para entradas del usuario.

---

### 4. Soporte Bidireccional (Bidi / RTL & LTR)
- Toda pantalla y componente debe respetar el flujo de lectura y dirección del texto:
  - Usar propiedades direccionales: `EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderDirectional`, `PositionedDirectional`.
  - Evitar el uso rígido de `left` y `right` cuando se trate de márgenes, paddings o posiciones que deban adaptarse a RTL.
  - Comprobar que los layouts flex (`Row`, `Stack`) no asuman exclusivamente orientación LTR.
  - En cadenas con contenido mixto (LTR y RTL) o números/variables dentro de texto bidireccional, usar `BidiFormatter` de `package:intl/intl.dart` si es requerido.

### 5. Flujo de Trabajo Obligatorio al Crear o Refactorizar Pantallas
1. **Identificar textos:** Extraer todas las cadenas, plurales o formatos parametrizados.
2. **Declarar en ARB:** Agregar las claves y descripciones en `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`.
3. **Regenerar código:** Ejecutar `flutter gen-l10n`.
4. **Implementar en Widget:** Llamar a `AppLocalizations.of(context)!` y a `DateFormat` / `NumberFormat` con el locale activo.
5. **Verificar dirección:** Comprobar uso de `*Directional` para compatibilidad bidi.

---

### 6. Arquitectura de Widgets (StatelessWidget sobre Métodos Helper Privados)
- **Evitar el anti-patrón `Widget _buildX()`:** No encapsular sub-árboles de UI en funciones privadas dentro de la misma clase cuando contengan estado o se reconstruyan con frecuencia.
- **Extraer en `StatelessWidget` / `StatefulWidget` dedicados:** Favorecer clases widget separadas con constructores `const` para:
  1. Aislar las reconstrucciones de la UI por sub-árbol.
  2. Permitir a Flutter optimizar el ciclo de vida del elemento y reusar el árbol de renderizado.
  3. Evitar que un cambio de estado en el padre reconstruya innecesariamente widgets secundarios estáticos.

