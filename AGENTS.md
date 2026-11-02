# Directrices de Desarrollo y Memoria del Proyecto ATRIO

---

## 1. Propósito, Misión, Necesidad, Alcance y Limitaciones

### 🎯 Propósito y Misión

**ATRIO** ("_Vive tu Fe en comunidad_") es una plataforma móvil y eclesial diseñada para conectar de forma viva y bidireccional a los feligreses con sus congregaciones locales, pastores y líderes eclesiales. Centraliza la vida espiritual (Biblia con audio dramatizado, emisoras cristianas en vivo, devocionales), la comunión (peticiones pastorales, eventos, voluntariado) y el sostenimiento ministerial (ofrendas, donaciones a causas solidarias y tienda eclesial).

### 💡 Necesidad que Resuelve

1. **Desconexión Pastoral y Comunitaria:** Supera la dispersión en canales informales (WhatsApp, llamadas) al proveer un canal oficial, seguro y trazable entre el creyente y su congregación.
2. **Superación de la Barrera Web para Líderes:** Elimina la dependencia de la consola web de escritorio de Odoo 19 (`action-700`) mediante el **Dashboard Pastoral Móvil**, permitiendo a pastores y líderes atender y responder oraciones, moderar solicitudes y revisar métricas directamente desde su teléfono.
3. **Pauta y Apoyo Comunitario:** Facilita a empresas locales, ministerios y emprendedores cristianos pautar anuncios relevantes y segmentados en un entorno confiable y moderado.

### 🌐 Alcance Funcional

- **Rol `member` (Feligrés):** Exploración y selección de iglesias en mapa interactivo (DO/HN con geolocalización adaptativa), lectura bíblica con audio, transmisión de radios cristianas, radicación de peticiones pastorales personales, ofrendas, compras en la tienda comunitaria y visualización de anuncios en el feed.
- **Rol `church_admin` (Pastor / Administrador de Iglesia):**
  - **Dashboard Pastoral Móvil ([church_admin_dashboard_screen.dart](file:///c:/APPS/ATRIO/lib/screens/church_admin_dashboard_screen.dart)):** KPIs pastorales en vivo (peticiones nuevas, feligreses activos, donaciones en RD$, eventos).
  - **Bandeja de Gestión Pastoral ([admin_requests_screen.dart](file:///c:/APPS/ATRIO/lib/screens/admin_requests_screen.dart)):** Filtros dinámicos, búsqueda y modal pastoral para responder, aprobar o rechazar solicitudes en tiempo real en Odoo 19 (`PUT /admin/requests/{id}`).
  - **Buzón Institucional:** Notificaciones administrativas (`GET /admin/notifications`).
  - **Gestión de Campañas Publicitarias:** Creación, cotización y analítica de anuncios ([ad_models.dart](file:///c:/APPS/ATRIO/lib/modelos/ad_models.dart), [ads_service.dart](file:///c:/APPS/ATRIO/lib/servicios/ads_service.dart)).
- **Módulo de Publicidad y Pauta (Odoo 19):**
  - Segmentación geográfica por país, estado, ciudad e iglesias específicas (`GET /admin/ads/targets`).
  - Cotización reactiva en tiempo real (`POST /admin/ads/quote`) por alcance, semanas y formato.
  - Pasarela híbrida (`/payment` y `/pay-transfer` con PayPal y transferencia bancaria con comprobante).
  - Analítica diaria y series temporales (`GET /admin/ads/{id}/stats`).

### ⚠️ Limitaciones Técnicas y Operativas

1. **Multitenancy y RBAC Estricto:** Cada líder pastoral administra exclusivamente su sede (`church_id`). Ningún administrador puede acceder a peticiones, feligreses ni ofrendas de otra congregación.
2. **Conectividad:** Soporte de lectura y caché local offline mediante SQLite ([atrio_database_helper.dart](file:///c:/APPS/ATRIO/lib/data/atrio_database_helper.dart)), pero toda operación transaccional (respuestas pastorales, donaciones, cotizaciones de anuncios y pagos) requiere conexión activa y autenticada con Odoo 19.
3. **Foco Geográfico Principal:** Cobertura optimizada para República Dominicana (`DO`, centro Santo Domingo) y Honduras (`HN`, centro Tegucigalpa con bounding box oficial en `ExplorarProvider` y búsqueda Places para `'do'` y `'hn'`).

---

## 2. Regla Inquebrantable: Internacionalización y Localización (i18n & l10n)

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

6. **Arquitectura de Widgets (StatelessWidget sobre Métodos Helper Privados):**
   - **Evitar el anti-patrón `Widget _buildX()`:** No encapsular sub-árboles de UI en funciones privadas dentro de la misma clase cuando contengan estado o se reconstruyan con frecuencia.
   - **Extraer en `StatelessWidget` / `StatefulWidget` dedicados:** Favorecer clases widget separadas con constructores `const` para:
     1. Aislar las reconstrucciones de la UI por sub-árbol.
     2. Permitir a Flutter optimizar el ciclo de vida del elemento y reusar el árbol de renderizado.
     3. Evitar que un cambio de estado en el padre reconstruya innecesariamente widgets secundarios estáticos.

---

_Para ver el detalle completo de reglas del proyecto, consulta [.agents/rules/reglas_atrio.md](file:///c:/APPS/ATRIO/.agents/rules/reglas_atrio.md)._
     3. Evitar que un cambio de estado en el padre reconstruya innecesariamente widgets secundarios estáticos.

---
*Para ver el detalle completo de reglas del proyecto, consulta [.agents/rules/reglas_atrio.md](file:///c:/APPS/ATRIO/.agents/rules/reglas_atrio.md).*
