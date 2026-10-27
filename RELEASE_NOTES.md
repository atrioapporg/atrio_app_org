# 🚀 ATRIO App — Release Notes

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
  - **Tarjeta Héroe Principal:** *"Unirme a una iglesia"* con llamada a la acción clara (*"Conectarme a mi iglesia"*) hacia el catálogo.
  - **Opciones Secundarias Compactas:**
    - *"Mi iglesia no está en Atrio"*: Acceso directo al flujo con Google Places.
    - *"Registrar una congregación"*: Información dirigida a pastores y líderes para el portal web Odoo.
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
- **Análisis Estático:** `flutter analyze` (**0 issues, 100% limpio**).
- **Pruebas Automatizadas:**
  - `test/bypass_iglesia_routing_test.dart` (4/4 tests pasados).
  - `test/etapa_3_pantallas_test.dart` (6/6 tests pasados).
  - **Total:** **10/10 tests aprobados al 100%**.
