# 🚀 ATRIO App — Release Notes

## [2026-10-31] (v0.1.0+25) - Módulo de Publicidad Odoo 19, Dashboard Pastoral Móvil para Admin de Iglesia & Certificación Multi-Agente

### 📌 Resumen Ejecutivo

Esta versión incorpora dos grandes hitos estratégicos en la plataforma ATRIO:
1. **Módulo Completo de Publicidad y Campañas** sincronizado al 100% con los contratos REST de Odoo 19 ERP, permitiendo cotización dinámica por alcance/duración, pagos híbridos (PayPal y transferencia bancaria con comprobantes) y analítica con series temporales.
2. **Dashboard Pastoral Móvil para el Administrador de Iglesia**, permitiendo al párroco o líder pastoral atender y responder solicitudes pastorales en tiempo real, consultar métricas de comunidad y gestionar su congregación directamente desde el móvil sin depender de la consola web de escritorio.

Toda la implementación fue certificada mediante simulación multi-agente en vivo (Miembro, Admin y Supervisor QA), cumpliendo estrictamente con las reglas de internacionalización (`app_es.arb` / `app_en.arb`), soporte Bidi / RTL y arquitectura de widgets desacoplados.

---

### 🌟 Principales Mejoras y Novedades

#### 1. 📢 Módulo Oficial de Publicidad y Pauta Comunitaria (Odoo 19)
- **Modelos y Contratos Sincronizados ([ad_models.dart](file:///c:/APPS/ATRIO/lib/modelos/ad_models.dart)):**
  - Soporte de targets de segmentación por países, estados, ciudades e iglesias específicas (`GET /admin/ads/targets`).
  - Cotización reactiva en tiempo real (`POST /admin/ads/quote`) con desglose de costo base, multiplicadores por formato de entrega (`feed`, `notifications`, `both`), semanas y descuento por volumen.
  - Modelado de cuentas bancarias institucionales para transferencias y gestión de pagos con PayPal en navegador externo.
  - Métricas avanzadas con desglose temporal interactivo (impresiones, clics totales, clics únicos y CTR).
- **Flujos de Creación, Pago y Analítica:**
  - Rediseño de [create_ad_campaign_screen.dart](file:///c:/APPS/ATRIO/lib/screens/create_ad_campaign_screen.dart) con selectores dinámicos, cálculo reactivo de presupuesto y validaciones preventivas.
  - Integración en [ad_payment_screen.dart](file:///c:/APPS/ATRIO/lib/screens/ad_payment_screen.dart) y [ad_stats_screen.dart](file:///c:/APPS/ATRIO/lib/screens/ad_stats_screen.dart) con gráficos de barras diarios y alertas de comprobantes.

#### 2. 🏛️ Dashboard Pastoral Móvil para el Administrador de Iglesia
- **Descubrimiento e Integración REST con Odoo 19:**
  - Conexión nativa con endpoints no documentados de Odoo 19: `GET /admin/requests`, `PUT /admin/requests/{id}`, `GET /admin/stats` y `GET /admin/notifications`.
- **Nueva Pantalla Principal [ChurchAdminDashboardScreen](file:///c:/APPS/ATRIO/lib/screens/church_admin_dashboard_screen.dart):**
  - Encabezado con datos de la congregación, insignia de Líder Pastoral y conexión activa con Odoo 19.
  - Grilla de KPIs en tiempo real: Nuevas Solicitudes, Feligreses Activos, Ofrendas Recaudadas (en formato local RD$) y Eventos del Mes.
  - Barra de accesos directos rápidos a solicitudes, avisos, eventos y pauta publicitaria.
  - Listado de solicitudes prioritarias con atención inmediata mediante botón "Responder Ahora".
- **Bandeja de Gestión Pastoral [AdminRequestsScreen](file:///c:/APPS/ATRIO/lib/screens/admin_requests_screen.dart):**
  - Búsqueda interactiva por feligrés o título.
  - Filtro por estados (*Nueva, En Progreso, Respondida, Rechazada*) y categorías (*Oración, Ayuda, Consejería*).
  - Modal pastoral Material 3 para redactar la respuesta pastoral y actualizar el estado en vivo en Odoo 19.
- **Acceso Directo desde el Perfil ([perfil_screen.dart](file:///c:/APPS/ATRIO/lib/screens/perfil_screen.dart)):**
  - Los administradores y líderes acceden directamente al Dashboard Pastoral y a la Bandeja de Solicitudes desde su perfil, eliminando los antiguos mensajes que remitían a la web.

#### 3. 🤖 Certificación Multi-Agente & QA de Integración
- **Simulación Agente Miembro:** Autenticación, creación de solicitudes, uso de tienda/carrito y ofrendas contra Odoo 19 en vivo.
- **Simulación Agente Admin:** Inspección de buzón (53 notificaciones), consulta de 22 peticiones pastorales y transición exitosa de solicitud #14 de `nueva` a `respondida`.
- **Aislamiento Multitenant (RBAC):** Validación de segregación estricta entre congregaciones (Iglesia 1 vs Iglesia 9) y control de acceso por roles.

#### 4. 📐 Reglas de Calidad y Arquitectura ATRIO (AGENTS.md)
- **100% i18n & l10n:** Cero textos hardcodeados. Todas las cadenas añadidas a `app_es.arb` y `app_en.arb` y regeneradas con `flutter gen-l10n`.
- **Soporte Bidireccional:** Sustitución total de paddings absolutos por `EdgeInsetsDirectional`.
- **Cero Anti-Patrón `_buildX()`:** Componentes UI extraídos en widgets desacoplados con constructores `const`.
- **Tests Automatizados:** 10/10 pruebas unitarias aprobadas en [ads_odoo_integration_test.dart](file:///c:/APPS/ATRIO/test/ads_odoo_integration_test.dart) y [church_admin_dashboard_test.dart](file:///c:/APPS/ATRIO/test/church_admin_dashboard_test.dart).
- **Análisis Estático:** 0 errores y 0 advertencias con `dart analyze`.

---

## [2026-10-27] - Optimización de Navegación, Enrutamiento Estricto de Iglesia y Soporte Regional RD/HN

### 📌 Resumen Ejecutivo

Esta entrega resuelve la fricción en el flujo de usuario (User Journey) de ATRIO, eliminando bucles y pantallas innecesarias cuando un usuario ya cuenta con una congregación vinculada o solicitada. Asimismo, se adaptó la infraestructura de geolocalización y el servicio de Google Places para dar soporte simultáneo a las pruebas activas en **República Dominicana** y **Honduras**, preparando la arquitectura para la futura expansión en toda América.

---

### 🌟 Principales Mejoras y Novedades

#### 1. 🛡️ Enrutamiento Estricto & Bypass de Selección de Iglesia

- **Bypass Automático al Home (`HomeScreen` / `InicioAtrioScreen`):**
  - Si un usuario ya seleccionó, vinculó o solicitó una congregación (incluso en estados `membership_pending`, `change_pending` o guardada localmente), se omite por completo la pantalla de selección y el mapa interactivo.
  - El usuario ingresa directamente a `InicioAtrioScreen`.
  - La gestión o consulta de membresía se realiza desde el banner no intrusivo en la pantalla principal.
- **Auditoría Exhaustiva de Estado en UserModel & Providers:**
  - Implementación de `UserModel.hasSelectedOrLinkedChurch` y `UserProvider.hasSelectedOrLinkedChurch` que auditan:
    - Asignación formal de congregación (`iglesiaId > 0`).
    - Solicitudes pendientes en Odoo (`requestedChurchId` o `requestedChurchData`).
    - Estatus canónicos de membresía (`membership_pending`, `change_pending`).
    - Registros previos persistidos en SQLite (`atrio.db`) y `SharedPreferences`.
  - Actualización en `AppStage.resolveStage` para resolver inmediatamente a `AppStage.memberHome` en lugar de caer en `chooseChurch`.
  - Puntos de entrada protegidos: Inicio de sesión (`InicioSesionScreen`), Registro (`CrearCuentaScreen`) y arranque en `main.dart`.

#### 2. 🎨 Rediseño UX/UI de «Elegir Camino de Iglesia»

- **Archivo:** `lib/screens/elegir_camino_iglesia_screen.dart`
- **Eliminación de sobrecarga cognitiva:** Se eliminaron las tarjetas redundantes y muros de texto denso.
- **Jerarquía visual optimizada:**
  - **Tarjeta Héroe Principal:** _"Unirme a una iglesia"_ con llamada a la acción clara (_"Conectarme a mi iglesia"_) hacia el catálogo.
  - **Opciones Secundarias Compactas:**
    - _"Mi iglesia no está en Atrio"_: Acceso directo al flujo con Google Places.
    - _"Registrar una congregación"_: Información dirigida a pastores y líderes para el portal web Odoo.
- **Guardia de Navegación Asíncrona:** Si la vista es abierta por error teniendo ya una iglesia asignada, redirige automáticamente sin parpadeos visuales.

#### 3. 🗺️ Soporte Geográfico Multi-Región (República Dominicana & Honduras)

- **Filtro Nacional Ampliado en Google Places Autocomplete:**
  - En `RecomendacionIglesiaProvider._executePlacesSearch`, se amplió la búsqueda a `countries: const ['do', 'hn']`.
  - Permite a los desarrolladores del backend de Odoo y usuarios de prueba en Honduras buscar y autocompletar congregaciones locales sin bloqueos regionales.
- **Adquisición Rápida y Precisa de GPS:**
  - En `RecomendarIglesiaMapaScreen`, `SeleccionarIglesiaScreen` e `IglesiasEnMapaScreen`:
    1. `Geolocator.getLastKnownPosition()` para fijar la cámara al instante sin esperas.
    2. `Geolocator.getCurrentPosition()` para afinar la precisión a nivel exacto de calle.
- **Cámara Inicial y Fallback Adaptativo por País:**
  - Ante permisos denegados o GPS inactivo, la cámara se orienta según la región del usuario o dispositivo:
    - **Honduras (`HN`):** Se centra en **Tegucigalpa** (`LatLng(14.0818, -87.2068)`).
    - **República Dominicana (`DO`):** Se centra en **Santo Domingo** (`LatLng(18.4812, -69.9158)`).
- **Delimitación Geográfica Oficial de Honduras (Bounding Box):**
  - En `ExplorarProvider`, se integraron las coordenadas oficiales de Honduras (`lat: 12.9 a 16.6`, `lng: -89.5 a -83.0`), bandera e identificación (`'HN': 'Honduras'`, `'HN': '🇭🇳'`).
- **Soporte de Modal de Ayuda Maps:**
  - En `ModalAyudaMaps`, el formulario adapta dinámicamente la etiqueta de país para los reportes locales.

---

### 🧪 Pruebas y Validación Técnica
rio adapta dinámicamente la etiqueta de país para los reportes locales.

---

### 🧪 Pruebas y Validación Técnica

- **Análisis Estático:** `flutter analyze` (**0 issues, 100% limpio**).
- **Pruebas Automatizadas:**
  - `test/bypass_iglesia_routing_test.dart` (4/4 tests pasados).
  - `test/etapa_3_pantallas_test.dart` (6/6 tests pasados).
  - **Total:** **10/10 tests aprobados al 100%**.
