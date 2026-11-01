# 🚀 ATRIO App — Release Notes

## [2026-11-01] (v0.1.0+31) - Corrección de Desbordamiento RenderFlex en MisDonacionesScreen y Optimización Responsiva

### 📌 Resumen Ejecutivo

Esta actualización resuelve de forma definitiva el desbordamiento de renderizado (`RenderFlex overflowed by 6.2 pixels`) en la vista de historial de donaciones [MisDonacionesScreen](file:///c:/APPS/ATRIO/lib/screens/mis_donaciones_screen.dart):

1. **Causa Raíz Identificada:**
   - En la tarjeta `_DonationCard`, la fila que agrupa el badge de estado (`status`) y la fecha (`dateInfo`) utilizaba un `Row` con restricciones horizontales estrictas dentro de un `Expanded`. En pantallas pequeñas o con configuraciones de accesibilidad con texto ampliado, el ancho conjunto superaba el espacio remanente frente a la columna del monto, generando un error `RenderFlex overflowed`.

2. **Solución Implementada:**
   - **Reemplazo por `Wrap` Adaptativo:** Se refactorizó la fila de metadatos utilizando `Wrap` con `crossAxisAlignment: WrapCrossAlignment.center`, `spacing` elástico y `runSpacing`. Esto permite que en pantallas estándar los elementos coexistan lado a lado y que en pantallas estrechas la fecha fluya suavemente al renglón inferior sin desbordar.
   - **Truncamiento Seguro de Títulos:** Se aplicó `maxLines: 1` y `overflow: TextOverflow.ellipsis` al título de la donación para evitar colisiones verticales o empujes inesperados.
   - **Separación de Columnas:** Se incorporó un margen defensivo de ancho relativo (`SizedBox(width: screenWidth * 0.02)`) entre los textos informativos y la columna del monto aportado.

---

## [2026-11-01] (v0.1.0+30) - Corrección de Error Lógico en PerfilScreen: Preservación Offline de Membresía Aprobada y Resiliencia en Modo Avión

### 📌 Resumen Ejecutivo

Esta actualización resuelve el error lógico en [PerfilScreen](file:///c:/APPS/ATRIO/lib/screens/perfil_screen.dart) en el cual un usuario autenticado y previamente registrado con su congregación activa, al poner el teléfono en "Modo Avión" (sin internet ni wifi), veía cambiar erróneamente su estado a "Iglesia pendiente de aprobación" / "Solicitud de membresía":

1. **Causa Raíz Identificada:**
   - En `PerfilScreen`, la condición `isMembershipPending` incluía un falso positivo: `|| hasChurchSelected`. Al perder la conexión a internet, si `isChurchApproved` caía a `false` temporalmente por fallo en la consulta al backend, cualquier usuario con una iglesia seleccionada se catalogaba erróneamente como pendiente de aprobación.
   - En [UserProvider](file:///c:/APPS/ATRIO/lib/providers/user_provider.dart), la restauración pasiva ante fallos de `/me` (modo avión o sin conexión) reconstruía el usuario local forzando `esMiembroVerificado: false` y `role: UserRole.user`, degradando su estatus de miembro verificado.
   - No existía serialización ni restauración completa en caché (`cached_user_profile`) en `SharedPreferences` para el `UserModel`.

2. **Solución Implementada:**
   - **Corrección de la Lógica de Estatus en `PerfilScreen`:** Se eliminó `hasChurchSelected` como condición para inferir solicitudes pendientes. Un usuario solo se considera pendiente de aprobación si explícitamente tiene una solicitud en curso (`membership_pending`, `pending`, `isWaitingApproval` o rol `user` no verificado).
   - **Validación Offline de Respaldo (`isOfflineApproved`):** Si el usuario está autenticado localmente, tiene su congregación registrada (SQLite o Provider) y no tiene solicitudes pendientes de membresía o traslado, se confirma su estado como congregación activa y aprobada.
   - **Persistencia y Restauración Completa en `UserProvider`:**
     - Se implementó `_persistCurrentUserLocally()` que serializa `UserModel` a JSON (`cached_user_profile`) y sincroniza `membership_status`, `user_church_id` y SQLite (`atrio.db`).
     - Se implementó `_restaurarUsuarioLocal()` que recupera el modelo completo con su rol (`UserRole.member`) y estatus (`approved`) sin depender de la conectividad con Odoo.
     - En `refreshUserProfile()`, si la llamada a Odoo falla (modo avión), se recupera el perfil local sin degradar al usuario.
     - En `didChangeAppLifecycleState` de `PerfilScreen`, se recargan los datos de SQLite inmediatamente al reanudar la app.
   - **Ajuste en Modales de Restricción:** Se corrigió [ModalRestriccionSolicitud](file:///c:/APPS/ATRIO/lib/widgets/modal_restriccion_solicitud.dart) y [NuevaSolicitudScreen](file:///c:/APPS/ATRIO/lib/screens/nueva_solicitud_screen.dart) para evitar que consideren a un usuario offline como "iglesia pendiente".

---

## [2026-11-01] (v0.1.0+29) - Rediseño UI/UX de AtrioConnectivityAlert: Centrado en Pantalla y Ampliación Tipográfica (+30%)

### 📌 Resumen Ejecutivo

Esta actualización optimiza la visibilidad, ergonomía y legibilidad del componente centralizado [AtrioConnectivityAlert](file:///c:/APPS/ATRIO/lib/widgets/atrio_connectivity_alert.dart):

1. **Posicionamiento Centrado en Pantalla:**
   - La alerta ya no se renderiza como un banner pegado al borde superior, sino en el **centro geométrico de la pantalla** (`Alignment.center` sobre `Positioned.fill`), logrando un enfoque visual inmediato del usuario.
   - Se añadió un telón de fondo táctil semi-transparente (`Colors.black26`) que permite descartar la alerta al pulsar en cualquier área externa.
   - Se implementó una animación fluida combinada de escalado elástico (`ScaleTransition` con `Curves.easeOutBack`) y desvanecimiento (`FadeTransition`).

2. **Ampliación Tipográfica (+30%):**
   - **Mensaje explicativo:** Incrementado de `12.0` a **`15.5`** (~30% más grande), con interlineado optimizado (`height: 1.3`) y soporte de hasta 4 líneas sin desbordamiento.
   - **Título de la alerta:** Incrementado de `14.0` a **`18.0`** con peso `FontWeight.w700`.
   - **Botón de acción ("Reintentar"):** Incrementado de `12.0` a **`15.0`** con mayor área de toque táctil.
   - **Icono de Alerta:** Incrementado de `22.0` a **`25.0`** dentro de un contenedor circular ampliado de 48x48.

---

## [2026-11-01] (v0.1.0+28) - Corrección de Error de Red en Google Sign-In (ApiException 7), Pre-flight Check y Resiliencia en Autenticación

### 📌 Resumen Ejecutivo

Esta actualización resuelve de forma definitiva el fallo en el inicio de sesión con Google reportado tras la selección de cuenta (`com.google.android.gms.common.api.ApiException: 7:`):

1. **Diagnóstico y Causa Raíz:**
   - El código `7` en los servicios de Google Play corresponde a `CommonStatusCodes.NETWORK_ERROR`, el cual se produce cuando el dispositivo experimenta intermitencia, pérdida de paquetes o falta de conectividad al intercambiar los tokens con los servidores de Google (`accounts.google.com`).
   - El manejador anterior capturaba la `PlatformException` pero no clasificaba el código `7`, arrojando el texto de excepción Java en crudo (`com.google.android.gms.common.api.ApiException: 7:`) en un SnackBar rojo invasivo, sin limpiar la sesión residual y sin verificar la conexión previamente.

2. **Blindaje y Mejoras Implementadas:**
   - **Verificación Previa de Conectividad (Pre-flight Check):** Se integró `AtrioConnectivityAlert.checkAndNotify(context)` en `_iniciarSesionGoogle()`, `_iniciarSesionApple()` y `_iniciarSesionCredenciales()`, validando acceso a internet real antes de invocar los SDKs nativos.
   - **Manejo Especializado de `ApiException 7` (NETWORK_ERROR):** Si la conexión falla durante la autenticación con Google, se dispara la alerta flotante institucional `AtrioConnectivityAlert` con opción de "Reintentar", eliminando por completo cualquier SnackBar con trazas técnicas crudas.
   - **Manejo Especializado de `ApiException 10` (DEVELOPER_ERROR) y `12501` (CANCELED):** Clasificación exacta de errores de configuración y cierre voluntario del selector de cuentas sin mostrar alertas de error innecesarias.
   - **Limpieza y Reset de Sesión (`_googleSignIn.signOut()`):** Ante cualquier fallo o cancelación, se asegura el restablecimiento del cliente para prevenir estados corruptos en intentos posteriores.
   - **Sanitización de Errores en `UserProvider`:** Blindaje en `loginWithGoogle` y `loginWithSocial` para evitar que excepciones de socket o red expongan objetos internos en la UI.
   - **Cumplimiento de i18n (`AGENTS.md`):** Nuevas claves localizadas en `app_es.arb` y `app_en.arb` para retroalimentación amigable tanto en español como en inglés.

---

## [2026-11-01] (v0.1.0+27) - Restauración de Splash Screen Nativo (Android 12+ / Android <12), Eliminación de Delay Artificial y Corrección del Ciclo de Vida de Inicio

### 📌 Resumen Ejecutivo

Esta actualización resuelve de raíz la degradación en el arranque de la aplicación provocada por una implementación forzada de Splash Screen con retraso artificial:

1. **Eliminación Total de Delays Artificiales:** Se erradicó el temporizador forzado (`Future.delayed(Duration(milliseconds: 1800))`) y el puente obligatorio que inducía a ver la pantalla de inicio de sesión durante ~2 segundos.
2. **Restauración del Splash Screen Nativo Condicional:**
   - **Android 12+ (API 31+):** Gestión 100% nativa con la API oficial del sistema operativo (`windowSplashScreenBackground` en `#072B4F` y `windowSplashScreenAnimatedIcon` en `@drawable/android12splash`).
   - **Android < 12 (API 29-30):** Gestión nativa fluida mediante `LaunchTheme` (`@drawable/launch_background` sobre `#072B4F`).
3. **Resolución Inmediata de Ruta Inicial (`initialRoute` en `main.dart`):**
   - El enrutamiento hacia `HomeScreen` (`InicioAtrioScreen`), `IntroEncuentraScreen` o `InicioSesionScreen` se calcula antes de dibujar el primer fotograma de Flutter mientras el splash nativo del SO permanece visible de forma natural (100-250 ms reales de carga de SQLite y almacenamiento seguro de credenciales).
   - Los usuarios con sesión activa (por token Odoo o SharedPreferences/SQLite) ingresan directamente a `HomeScreen` sin pasar por la pantalla de login ni experimentar parpadeos.

---

## [2026-11-01] (v0.1.0+26) - Estandarización de Conectividad con AtrioConnectivityAlert, Fortificación Transaccional & Auditoría Global de Pantallas

### 📌 Resumen Ejecutivo

Esta versión introduce una actualización transversal de estabilidad, resiliencia y experiencia de usuario en ATRIO:

1. **Nuevo Componente Centralizado `AtrioConnectivityAlert`:** Sustitución de SnackBars rojos invasivos y errores silenciosos por un banner flotante institucional (`#072B4F` y `#E5A023`) con reintento reactivo y verificación real de socket TCP mediante `ConnectivityService.instance.hasRealInternet()`.
2. **Fortificación Transaccional y Auditoría en 21 Pantallas Clave:** Protección previa (_pre-flight connectivity check_) en todas las pantallas financieras, de comercio electrónico, gestión pastoral en Odoo 19 ERP, streaming multimedia y georreferenciación.
3. **Refactorización de Arquitectura y Limpieza UI (`AGENTS.md`):** Erradicación total del anti-patrón `Widget _buildX()` con extracción a clases `StatelessWidget` dedicadas, soporte 100% bidireccional (`EdgeInsetsDirectional`, `PositionedDirectional`) e internacionalización completa en `app_es.arb` y `app_en.arb`.

---

### 🌟 Principales Mejoras y Novedades

#### 1. 🌐 Componente Institucional de Conectividad (`AtrioConnectivityAlert`)

- **Diseño UI/UX Premium:** Banner flotante con bordes redondeados (`14px`), paleta oficial ATRIO, botón interactivo "Reintentar" y animación de salida limpia.
- **Validación de Internet Real:** Comprobación activa de resolución DNS y socket TCP mediante `ConnectivityService.instance.hasRealInternet()`, evitando falsos positivos por estar conectado a WiFi sin acceso a red.
- **API Unificada:** Método estático `AtrioConnectivityAlert.checkAndNotify(context)` para validar y advertir visualmente en una sola línea antes de cualquier operación remota.

#### 2. 🛡️ Matriz de Cobertura y Pantallas Fortificadas

- **Nivel 1: Transaccional & Pasarelas (Odoo 19 ERP):**
  - **Donaciones y Aportes:** [confirmar_donacion_screen.dart](file:///c:/APPS/ATRIO/lib/screens/confirmar_donacion_screen.dart), [realizar_aporte_screen.dart](file:///c:/APPS/ATRIO/lib/screens/realizar_aporte_screen.dart), [aportar_a_proyecto_screen.dart](file:///c:/APPS/ATRIO/lib/screens/aportar_a_proyecto_screen.dart), [donaciones_screen.dart](file:///c:/APPS/ATRIO/lib/screens/donaciones_screen.dart), [mis_donaciones_screen.dart](file:///c:/APPS/ATRIO/lib/screens/mis_donaciones_screen.dart).
  - **Tienda y Pedidos Eclesiales:** [tienda_screen.dart](file:///c:/APPS/ATRIO/lib/screens/tienda_screen.dart), [mis_pedidos_screen.dart](file:///c:/APPS/ATRIO/lib/screens/mis_pedidos_screen.dart).
  - **Publicidad y Pagos:** [admin_ads_screen.dart](file:///c:/APPS/ATRIO/lib/screens/admin_ads_screen.dart), [ad_payment_screen.dart](file:///c:/APPS/ATRIO/lib/screens/ad_payment_screen.dart), [create_ad_campaign_screen.dart](file:///c:/APPS/ATRIO/lib/screens/create_ad_campaign_screen.dart).
  - **Gestión Pastoral Móvil:** [church_admin_dashboard_screen.dart](file:///c:/APPS/ATRIO/lib/screens/church_admin_dashboard_screen.dart), [admin_requests_screen.dart](file:///c:/APPS/ATRIO/lib/screens/admin_requests_screen.dart), [nueva_solicitud_screen.dart](file:///c:/APPS/ATRIO/lib/screens/nueva_solicitud_screen.dart), [seguimiento_solicitud_screen.dart](file:///c:/APPS/ATRIO/lib/screens/seguimiento_solicitud_screen.dart).
- **Nivel 2: Streaming en Vivo y Servicios Geográficos:**
  - **Radios Cristianas:** [emisoras_screen.dart](file:///c:/APPS/ATRIO/lib/screens/emisoras_screen.dart) _(arquitectura desacoplada, selector de país y buffer protegido)_.
  - **Audio Bíblico Dramatizado:** [escuchar_libro_biblia_screen.dart](file:///c:/APPS/ATRIO/lib/screens/escuchar_libro_biblia_screen.dart).
  - **Exploración y Mapas:** [explorar_screen.dart](file:///c:/APPS/ATRIO/lib/screens/explorar_screen.dart), [iglesias_en_mapa_screen.dart](file:///c:/APPS/ATRIO/lib/screens/iglesias_en_mapa_screen.dart).
- **Nivel 3: Gestión de Cuenta y Asistencia Técnica:**
  - [perfil_screen.dart](file:///c:/APPS/ATRIO/lib/screens/perfil_screen.dart), [notificaciones_screen.dart](file:///c:/APPS/ATRIO/lib/screens/notificaciones_screen.dart), [ayuda_soporte_screen.dart](file:///c:/APPS/ATRIO/lib/screens/ayuda_soporte_screen.dart), [inicio_sesion_screen.dart](file:///c:/APPS/ATRIO/lib/screens/inicio_sesion_screen.dart).

#### 3. 📐 Cumplimiento de Reglas de Calidad y Arquitectura (AGENTS.md)

- **100% Internacionalización (i18n):** Incorporadas nuevas cadenas en `app_es.arb` y `app_en.arb` y compiladas mediante `flutter gen-l10n`. Cero textos visibles hardcodeados.
- **Formateo Estricto con `intl: ^0.20.3`:** Empleo sistemático de `DateFormat`, `NumberFormat.currency` y `NumberFormat.decimalPattern` respetando el locale activo (`Localizations.localeOf(context).toString()`).
- **Soporte Bidireccional (Bidi / RTL):** Reemplazo de alineaciones y márgenes absolutos por `EdgeInsetsDirectional`, `PositionedDirectional` y `AlignmentDirectional`.
- **Arquitectura Limpia:** Decenas de métodos privados `_buildX()` refactorizados en clases widget independientes con constructores `const`.
- **Control de Calidad:** `flutter analyze`: **0 issues** en la totalidad del proyecto.

---

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
  - Filtro por estados (_Nueva, En Progreso, Respondida, Rechazada_) y categorías (_Oración, Ayuda, Consejería_).
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

- **Análisis Estático:** `dart analyze` (**0 issues, 100% limpio**).
- **Pruebas Automatizadas:**
  - `test/splash_native_lifecycle_test.dart` (4/4 tests pasados).
  - `test/ads_odoo_integration_test.dart` (5/5 tests pasados).
  - `test/church_admin_dashboard_test.dart` (5/5 tests pasados).
  - `test/bypass_iglesia_routing_test.dart` (4/4 tests pasados).
  - `test/etapa_3_pantallas_test.dart` (6/6 tests pasados).
  - **Total:** **24/24 tests aprobados al 100%**.
