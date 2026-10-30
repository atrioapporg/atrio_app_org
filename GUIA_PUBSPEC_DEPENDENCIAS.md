# Guía Didáctica de Dependencias y Paquetes de ATRIO (`pubspec.yaml`)

Esta guía documenta detalladamente el propósito, la arquitectura y el uso de cada uno de los paquetes y herramientas declarados en el archivo [`pubspec.yaml`](file:///c:/APPS/ATRIO/pubspec.yaml) de la aplicación **ATRIO**.

---

## 1. Framework Base & Localización Oficial (i18n & l10n)

* **`flutter`**: SDK principal que provee el motor gráfico Skia/Impeller, el árbol de widgets reactivos y la API nativa de Flutter.
* **`flutter_localizations`**: Paquete oficial con soporte para internacionalización: cadenas del sistema, calendarios, meses y formatos regionales según el dispositivo del usuario.
* **`intl: ^0.20.3`**: Estándar fundamental para:
  - Formateo y análisis de fechas y horas (`DateFormat`).
  - Formateo de números, monedas y porcentajes (`NumberFormat`).
  - Manejo de plurales y género bajo sintaxis ICU message format (`{count, plural, =0{...} =1{...} other{...}}`).
  - Soporte de texto bidireccional (RTL y LTR) con utilidades direccionales y `BidiFormatter`.

---

## 2. Arquitectura & Gestión de Estado

* **`provider: ^6.1.2`**: Envoltura alrededor de `InheritedWidget` para inyección de dependencias y gestión de estado reactivo (`ChangeNotifierProvider`, `Consumer`, `context.watch/read`). Comunica los modelos de usuario, autenticación y sesión con la interfaz sin acoplar los widgets.

---

## 3. Red, HTTP & Conectividad

* **`http: ^1.6.0`**: Cliente HTTP ligero para consumir las APIs REST de ATRIO y sincronizar con el backend de Odoo.
* **`connectivity_plus: ^6.0.0`**: Monitorea el tipo de red activa en el dispositivo (WiFi, datos móviles, ethernet o desconectado).
* **`internet_connection_checker_plus: ^3.1.1`**: Verifica conectividad real a Internet mediante comprobaciones de ping y socket a servidores DNS, evitando falsos positivos cuando hay WiFi pero sin acceso a la red.

---

## 4. Autenticación e Identidad

* **`google_sign_in: ^5.4.0`**: Integración con Google Identity Services para autenticación OAuth nativa en Android e iOS.
* **`sign_in_with_apple: ^6.1.1`**: Implementación obligatoria de Apple ID en iOS conforme a los lineamientos del App Store para apps que ofrezcan inicio de sesión con terceros.
* *(Opcional / Comentado)* **`flutter_facebook_auth: ^7.2.0`**: Para inicio de sesión mediante credenciales de Facebook.

---

## 5. Almacenamiento Local & Persistencia de Datos

* **`sqflite: ^2.4.2`**: Motor SQLite para persistencia relacional local en SQLite (caché de eventos, iglesias, predicas, miembros y soporte offline).
* **`path: ^1.9.1`**: Utilidad multiplataforma para unir, resolver y manipular rutas del sistema de archivos (`join(await getDatabasesPath(), 'atrio.db')`).
* **`shared_preferences: ^2.5.5`**: Almacén clave-valor para preferencias sencillas y no sensibles (modo oscuro, idioma seleccionado, tutoriales completados).
* **`flutter_secure_storage: ^10.3.4`**: Almacenamiento cifrado por hardware (Android Keystore / iOS Keychain) para guardar de forma segura tokens JWT, claves de sesión y credenciales sensibles.

---

## 6. Geolocalización & Mapas

* **`geolocator: ^14.0.3`**: Gestión de permisos de GPS y obtención de coordenadas (latitud/longitud) para ubicar iglesias y sedes cercanas al usuario.
* **`google_maps_flutter: ^2.18.0`**: Widget interactivo de Google Maps embebido directamente en la interfaz.
* **`google_maps_flutter_android: ^2.19.12`**: Implementación específica de mapas optimizada para el ciclo de vida y renderizado en Android.
* **`google_maps_flutter_platform_interface: ^2.16.1`**: Capa de abstracción que define la interfaz común de Google Maps entre plataformas.
* **`flutter_google_places_sdk: ^0.4.3`**: SDK para autocompletado y búsqueda de direcciones y lugares mediante la API de Google Places.

---

## 7. Multimedia: Audio, Video & Streaming

* **`just_audio: ^0.10.6`**: Reproductor de audio de alto rendimiento para sermones, himnos, música sacra y podcasts.
* **`just_audio_background: ^0.0.1-beta.17`**: Habilita la reproducción de audio en segundo plano con controles en la cortina de notificaciones y la pantalla de bloqueo.
* **`youtube_player_flutter: ^9.1.1`**: Reproductor nativo para visualizar transmisiones y cultos en vivo o videos pregrabados de YouTube.
* **`flutter_inappwebview_android: ^1.1.3`**: Motor WebView para Android utilizado por componentes embebidos web/video.

---

## 8. Interfaz Gráfica, Fuentes & Utilidades de UI

* **`google_fonts: ^9.0.0`**: Descarga y aplica dinámicamente tipografías de Google Fonts sin necesidad de empaquetar archivos `.ttf` manuales.
* **`font_awesome_flutter: ^11.0.0`**: Catálogo de iconos vectoriales FontAwesome complementarios a Material Icons.
* **`image_picker: ^1.2.4`**: Selector multimedia para capturar fotos con la cámara o seleccionarlas de la galería (fotos de perfil, eventos).
* **`url_launcher: ^6.3.2`**: Abre enlaces externos en el navegador web del sistema, envía correos (`mailto:`) o inicia llamadas telefónicas (`tel:`).

---

## 9. Diagnóstico, Soporte & Mantenimiento

* **`csv: ^8.0.0`**: Lector y generador de archivos CSV para importación/exportación de listas de miembros y reportes administrativos.
* **`package_info_plus: ^10.2.2`**: Consulta en tiempo de ejecución la versión de la app, número de build y nombre del paquete.
* **`upgrader: ^13.5.0`**: Detecta automáticamente si existe una nueva versión en Google Play / App Store e insta al usuario a actualizar.
* **`feedback: ^3.1.1`**: Widget interactivo que permite al usuario reportar problemas dibujando directamente sobre una captura de pantalla.

---

## 10. Dependencias de Desarrollo (`dev_dependencies`)

* **`flutter_test`**: Framework oficial de pruebas unitarias y de widgets de Flutter.
* **`flutter_lints: ^6.0.0`**: Conjunto oficial de reglas de análisis estático recomendadas para mantener código Dart limpio y libre de errores comunes.
* **`build_runner: ^2.12.0`**: Motor de ejecución de tareas de generación de código en tiempo de compilación.
* **`flutter_launcher_icons: ^0.14.4`**: Herramienta CLI para generar todos los tamaños y formatos de iconos de la app a partir de una única imagen.
* **`flutter_native_splash: ^2.0.5`**: Generador de pantallas de bienvenida nativas previas al inicio del motor de Flutter (compatible con Android 12+).
