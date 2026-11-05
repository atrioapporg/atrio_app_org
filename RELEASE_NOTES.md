# 📱 ATRIO — Notas de la Versión / Release Notes

**Versión:** `v1.0.0-rc.1`  
**Fecha de Publicación:** 5 de Noviembre de 2026  
**Rama de Entrega:** `App-Review-Notes`  
**Objetivo:** Cumplimiento total de políticas de revisión de **Apple App Store** y **Google Play Store**, especificación de arquitectura backend Odoo 19 y auditoría/refactorización UI/UX integral en pantallas neurálgicas.

---

## 🌟 Novedades y Mejoras Principales

### 1. Cumplimiento Normativo App Store & Google Play (Etapas 1 a 6)

- **Apple Guideline 3.1.1 (Donaciones Caritativas y Recaudación de Fondos):**
  - Implementación de la pasarela web externa oficial (`SFSafariViewController` en iOS y `Chrome Custom Tabs` en Android) vía Odoo 19 (`https://atrioapp.odoo19rd.com/donaciones`), garantizando que las ofrendas y donaciones voluntarias no utilicen el sistema de compras dentro de la aplicación (_In-App Purchase_).
  - Verificación institucional previa (**KYC**): Módulo de ofrendas habilitado exclusivamente para congregaciones verificadas con estatus legal (República Dominicana: _ISFL Ley 122-05_ | Honduras: _Personería Jurídica y RTN_).
- **Apple Guideline 5.1.1(v) (Eliminación de Cuenta y Datos Personales):**
  - Incorporación del flujo de eliminación incondicional, inmediata e irreversible de cuenta y datos personales directamente desde la pantalla de Perfil (`DELETE /atrio/portal/api/auth/account` o `POST /auth/delete_account`), con diálogo de confirmación y advertencias de consecuencias.
- **Apple Guideline 1.2 & Google Play (Seguridad de Contenido Generado por Usuarios - UGC):**
  - Sistema de moderación y tolerancia cero en avisos comunitarios, peticiones y publicaciones.
  - Menú contextual interactivo para **reportar contenido inapropiado** (revisado por el equipo en < 24 horas) y **bloquear al autor** de forma inmediata (`POST /atrio/portal/api/ugc/report` y `POST /atrio/portal/api/ugc/block-user`).
- **Términos de Servicio y EULA:**
  - Actualización de los Términos y Política de Privacidad reflejando la retención de datos, tolerancia cero ante lenguaje abusivo y directrices de donaciones.
- **Especificación Técnica Odoo 19 Backend:**
  - Documento [`ESPECIFICACION_BACKEND_ODOO19_COMPLIANCE.md`](./ESPECIFICACION_BACKEND_ODOO19_COMPLIANCE.md) para el equipo de Claude Code con contratos de datos, modelos relacionales y endpoints requeridos.

---

### 2. Depuración de Métodos de Pago y Pasarelas

- Eliminación de leyendas y botones de pago redundantes (`Transferencia Bancaria`, `Apple Pay`, `Google Pay`, `PayPal`) en las pantallas:
  - [`realizar_aporte_screen.dart`](./lib/screens/realizar_aporte_screen.dart)
  - [`aportar_a_proyecto_screen.dart`](./lib/screens/aportar_a_proyecto_screen.dart)
  - [`confirmar_donacion_screen.dart`](./lib/screens/confirmar_donacion_screen.dart)
- Todas las transacciones ahora se dirigen de manera homogénea y transparente al canal web seguro de la congregación con trazabilidad contable.

---

### 3. Auditoría y Refactorización UI/UX Integral (`ui-ux-pro-max`)

#### A. Pantalla de Perfil ([`perfil_screen.dart`](./lib/screens/perfil_screen.dart))

- **Cero Textos Hardcodeados:** 20 nuevas claves en `app_es.arb` y `app_en.arb` eliminando textos literales y erradicando mojibake histórico (`ó`, `í`, `é`).
- **Touch Targets (WCAG 2.5.5):** Botón principal de estado de iglesia elevado de 38dp a **48dp** ergonómico.
- **Accesibilidad y Contraste (WCAG AAA):** Botón de edición con `tooltip` y accesibilidad semántica; contraste tipográfico sobre degradados oscuros elevado a **> 7:1**.
- **Direccionalidad Bidi:** Adopción de `EdgeInsetsDirectional.fromSTEB` en modales.

#### B. Pantalla de Inicio ([`inicio_atrio_screen.dart`](./lib/screens/inicio_atrio_screen.dart))

- **Optimización de Rendimiento:** Desacoplamiento del `setState()` global en el banner rotativo de avisos, eliminando la reconstrucción continua de la pantalla cada 3–5 segundos.
- **Feedback Táctil:** Reemplazo de `GestureDetector` por `Material` + `InkWell` interactivo en la matriz de 8 acciones y en las tarjetas del feed, ofreciendo confirmación háptica/visual (_ripple_).
- **Ergonomía Táctil:** Botón de cierre del modal emergente ampliado de 22x22dp a **48x48dp**. Botones de escaneo QR y notificaciones estandarizados a 48dp con soporte TalkBack/VoiceOver.
- **Contraste de Etiquetas:** Ajuste de contraste en chips a **> 5.5:1** (WCAG AA).

#### C. Pantalla de Iglesia ([`iglesia_screen.dart`](./lib/screens/iglesia_screen.dart))

- **Internacionalización Completa:** Plantillas de correo y mensajes de compartir Plus Code migradas a formato ICU con parámetros.
- **Áreas Táctiles:** Botón "Ver ahora" (próximo culto) elevado a 44dp y menú de seguridad UGC envuelto en contenedor táctil de **48x48dp**.
- **Accesibilidad Semántica:** Calificación por estrellas y contador de reseñas verbalizados audiblemente mediante `Semantics`.

---

## 🛠️ Verificación y Calidad de Código
 (próximo culto) elevado a 44dp y menú de seguridad UGC envuelto en contenedor táctil de **48x48dp**.
- **Accesibilidad Semántica:** Calificación por estrellas y contador de reseñas verbalizados audiblemente mediante `Semantics`.

---

## 🛠️ Verificación y Calidad de Código

- **Dart Analyzer:** `dart analyze` ejecutado con **0 errores y 0 advertencias**.
- **Localización:** `flutter gen-l10n` ejecutado con sincronización perfecta ES/EN.
- **Seguridad:** Purgadas credenciales locales del control de versiones (`.gitignore`).
