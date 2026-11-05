# 📱 ATRIO — Notas de la Versión / Release Notes

**Versión:** `v1.0.1` (`0.1.1+36`)  
**Fecha de Publicación:** 5 de Noviembre de 2026  
**Rama de Entrega:** `App-Review-Notes`  
**Objetivo:** Implementación del sistema de **Notificaciones Matutinas de Palabra y Oración del Día** (System Tray & Lock Screen), validación extremo a extremo de **Notificaciones Push desde Odoo 19**, cumplimiento normativo **Apple App Store / Google Play Store** y optimización de compilación Android/Gradle.

---

## 🌟 Novedades y Mejoras de Hoy (5 de Noviembre de 2026)

### 1. Sistema de Notificaciones Matutinas Locales ("Palabra y Oración del Día")

- **Servicio Dedicado ([`daily_verse_notification_service.dart`](./lib/servicios/daily_verse_notification_service.dart)):**
  - Programación automática recurrente diaria a las **7:00 AM** (`zonedSchedule` con `DateTimeComponents.time`) que funciona **100% offline**, sin depender de conectividad ni sobrecargar el servidor de Odoo 19.
  - **Visibilidad en Pantalla de Bloqueo y System Tray:** Canal nativo `atrio_daily_word_channel` configurado con `Importance.max`, `Priority.high` y `NotificationVisibility.public`.
  - **Estilo Expandido (`BigTextStyleInformation`) y Acción Interactiva:** Soporte completo para versículos y oraciones extensas sin truncamiento, acompañado del botón de acción **`"Amén ›"`** (`AndroidNotificationAction`).
  - **Detección de Zona Horaria en Dart Puro:** Resolución automática del huso horario local del dispositivo (`America/Santo_Domingo` UTC-4, `America/Tegucigalpa` UTC-6 e IANA offsets) sin depender de plugins nativos con conflictos de Kotlin Gradle Plugin.
- **Redirección In-App Directa ([`main.dart`](./lib/main.dart)):**
  - Al pulsar la notificación o el botón `"Amén ›"` (con la app en segundo plano o cerrada), `MyApp.navigatorKey` redirige automáticamente a [`LecturaCapituloScreen`](./lib/screens/lectura_capitulo_screen.dart) abriendo el libro, capítulo y versículo exacto del devocional.
- **Permisos y Receptores Nativos ([`AndroidManifest.xml`](./android/app/src/main/AndroidManifest.xml)):**
  - Gestión de permisos en tiempo de ejecución para Android 13+ (`POST_NOTIFICATIONS`), Android 12+ (`SCHEDULE_EXACT_ALARM` con fallback seguro a `inexactAllowWhileIdle`) e iOS (`alert`, `badge`, `sound`).
  - Receptores `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` (`RECEIVE_BOOT_COMPLETED`) y `ActionBroadcastReceiver` para conservar las alarmas activas tras reiniciar el dispositivo.
- **Internacionalización (`i18n` / `l10n`):**
  - Nuevas claves localizadas en [`app_es.arb`](./lib/l10n/app_es.arb) y [`app_en.arb`](./lib/l10n/app_en.arb) (`dailyWordChannelName`, `dailyWordChannelDescription`, `dailyPrayerMorningTitle`, `dailyPrayerAmenAction`, `dailyPrayerDefaultBody`) con resolución segura de contexto mediante `lookupAppLocalizations`.

### 2. Verificación de Notificaciones Push Pastorales desde Odoo 19

- Validación del flujo completo de emisión de notificaciones desde el panel pastoral `/atrio/manage` en Odoo 19 (`Parroquia Nuestra Señora del Amparo`) y sincronización de tokens FCM vía `POST /atrio/portal/api/devices` y `GET /atrio/portal/api/notifications`.

### 3. Optimización de Compilación Android & Gradle

- Habilitación de **Core Library Desugaring** (`desugar_jdk_libs:2.1.4`) en [`android/app/build.gradle.kts`](./android/app/build.gradle.kts) para soporte completo de APIs temporales de Java 8+ en Android.
- Estandarización de directorios de recursos en `assets/audio/` y `assets/data/`.

---

## 📋 Historial Acumulado de la Versión (`v1.0.0-rc.1`)

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

- **Dart Analyzer:** `dart analyze` ejecutado con **0 errores y 0 advertencias**.
- **Localización:** `flutter gen-l10n` ejecutado con sincronización perfecta ES/EN.
- **Seguridad:** Purgadas credenciales locales del control de versiones (`.gitignore`).
