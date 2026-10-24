# Guía de Implementación Paso a Paso: Inicio de Sesión, Estados y Suscripción en ATRIO

> **Documento base:** `Z:\Antonyy\ATRIO VARIOS\GUIA_FLUTTER_INICIO_Y_SUSCRIPCION.md`  
> **Proyecto:** ATRIO Flutter App (`c:\APPS\ATRIO`)  
> **Fecha de formulación:** Octubre 2026  
> **Objetivo:** Plan de acción quirúrgico y por etapas para implementar exclusivamente los componentes faltantes o incompletos del flujo de autenticación, selección de iglesia, esperas de aprobación/activación y máquina de estados en Odoo 19, preservando intacto todo lo que ya funciona correctamente.

---

## Índice

1. [Diagnóstico: Lo que Ya Funciona vs. Lo Inconcluso y Faltante](#1-diagnóstico-lo-que-ya-funciona-vs-lo-inconcluso-y-faltante)
2. [Arquitectura de la Solución y Máquina de Estados](#2-arquitectura-de-la-solución-y-máquina-de-estados)
3. [Etapa 1: Modelo de Datos y Máquina de Estados (`UserModel` y `AppStage`)](#etapa-1-modelo-de-datos-y-máquina-de-estados-usermodel-y-appstage)
4. [Etapa 2: Endpoints y Cliente HTTP (`AtrioApi`)](#etapa-2-endpoints-y-cliente-http-atrioapi)
5. [Etapa 3: Pantallas de Espera y Selección de Camino](#etapa-3-pantallas-de-espera-y-selección-de-camino)
6. [Etapa 4: Integración en Pantallas Existentes (Login, Google, Registro y Mapa)](#etapa-4-integración-en-pantallas-existentes-login-google-registro-y-mapa)
7. [Etapa 5: Enrutamiento, Ciclo de Vida y Notificaciones Push](#etapa-5-enrutamiento-ciclo-de-vida-y-notificaciones-push)
8. [Etapa 6: Checklist de Validación y Casos de Prueba](#etapa-6-checklist-de-validación-y-casos-de-prueba)

---

## 1. Diagnóstico: Lo que Ya Funciona vs. Lo Inconcluso y Faltante

Tras una auditoría minuciosa del código fuente actual en `c:\APPS\ATRIO`, este es el estado comparativo:

### ✅ Lo que YA ESTÁ IMPLEMENTADO y NO SE DEBE TOCAR
* **Paquetes base instalados:** `http`, `flutter_secure_storage`, `google_sign_in`, `shared_preferences` están en `pubspec.yaml` y operativos.
* **Cliente base `AtrioApi`:** Gestión de token Bearer, cabeceras estándar, concurrencia de renovación ante 401 (`_safeRefresh`), almacenamiento seguro de tokens (`TokenStorageService`) y endpoints de catálogo (`/churches`, `/plans`, `/me`, `/requests`, etc.).
* **Servicio de Notificaciones Push:** `DeviceNotificationService` ya maneja `POST /devices` y `DELETE /devices` para registrar/desregistrar dispositivos en Odoo.
* **Recuperación de contraseña:** `RecuperarClaveScreen` ya llama a `api.requestPasswordReset()` conforme al estándar seguro de Odoo.
* **Exploración de Iglesias:** `ExplorarProvider` y `SeleccionarIglesiaScreen` ya cuentan con soporte para mapas de Google, búsqueda con debounce y filtrado geográfico.

### ⚠️ Lo que ESTÁ A MEDIAS o INCONCLUSO
1. **Modelo `UserModel` (`lib/modelos/user_model.dart`):**  
   Parsea rol y permisos, pero **no extrae** `membership_status` (`none`, `membership_pending`, `change_pending`), `requested_church_id` ni `church.has_active_subscription`. La app desconoce si la iglesia del usuario está pendiente de activación o si su membresía está en espera de aprobación pastoral.
2. **Inicio con Google (`lib/screens/inicio_sesion_screen.dart`):**  
   Captura el `idToken` de Google, pero lo envía a un endpoint genérico `/auth/social_login` con fallback simulado en lugar del endpoint oficial de Odoo `POST /atrio/portal/api/auth/google`. Además, no maneja los errores tipados (`email_not_verified`, `account_exists`, `invalid_google_token`).
3. **Selección de Iglesia en el Mapa (`lib/screens/seleccionar_iglesia_screen.dart`):**  
   Al presionar "Seleccionar iglesia", genera datos ficticios y los guarda en SQLite/Provider local, **sin llamar a `POST /membership/request` (`api.requestMembership`)** en Odoo. El backend nunca recibe la solicitud de membresía.
4. **Registro con correo (`lib/screens/crear_cuenta_screen.dart`):**  
   Llama a `POST /register`, pero tiene hardcodeado `church_id = 1` y tras el registro intenta mandar directo a `InicioAtrioScreen` sin validar si la solicitud quedó en aprobación pendiente.

### ❌ Lo que FALTA TOTALMENTE (Por Desarrollar)
1. **Máquina de Estados de Pantalla (`AppStage` y `resolveStage`):**  
   Lógica centralizada que determine la vista según el payload de `GET /me`.
2. **Pantalla "Elegir Iglesia o Crear la Suya" (`AppStage.chooseChurch`):**  
   Para usuarios autenticados sin iglesia (`role: "user"`, `membership_status: "none"`).
3. **Pantalla "Esperando Aprobación" (`AppStage.waitingApproval`):**  
   Para usuarios con `membership_status == "membership_pending"`. Con visualización de la congregación solicitada y botón "Actualizar" (`GET /me`).
4. **Pantalla "Iglesia Pendiente de Activación" (`AppStage.churchPendingActivation`):**  
   Para administradores de iglesia con `has_active_subscription == false`.
5. **Endpoint `POST /me/church` (`createMyChurch`):**  
   Para que un usuario ya registrado pueda dar de alta su iglesia desde la app.
6. **Manejo de cambio pendiente de iglesia (`change_pending`):**  
   Banner o notificación dentro de `InicioAtrioScreen`.

---

## 2. Arquitectura de la Solución y Máquina de Estados

La app se gobernará mediante una máquina de estados declarativa alimentada por `GET /me` (o la respuesta de `/auth/login` y `/auth/google`):

```
                                      [ Inicio / Apertura de App ]
                                                    │
                                            ¿Token Válido?
                                            ├── NO ──> [ AppStage.welcome ] (InicioSesionScreen)
                                            └── SÍ ──> GET /me
                                                           │
              ┌───────────────────────────┬────────────────┴───────────────────────────┐
              │                           │                                            │
    role == 'platform_admin'     membership_status ==                role == 'church_admin'
              │                 'membership_pending'                                   │
              ▼                           │                          ┌─────────────────┴─────────────────┐
    [ AppStage.platformAdmin ]            ▼                          ▼                                   ▼
    (Selector Super Admin)      [ AppStage.waitingApproval ]   has_active_subscription?          has_active_subscription?
                                (Esperando Aprobación)                == false                            == true
                                                                     │                                   │
                                                                     ▼                                   ▼
                                                      [ AppStage.churchPendingActivation ]      [ AppStage.adminHome ]
                                                      (Activación Atrio)                        (Inicio Admin)
              ┌───────────────────────────┬───────────────────────────┐
              │                           │                           │
    role == 'member'            membership_status ==        role == 'user' / membership_status == 'none'
    has_active_sub == true      'change_pending'                      │
              │                           │                           ▼
              ▼                           ▼                [ AppStage.chooseChurch ]
    [ AppStage.memberHome ]     [ AppStage.memberHome ]    ("Unirme a iglesia" o "Registrar iglesia")
    (Inicio Normal)             (+ Banner "Cambio Pendiente")
```

---

## Etapa 1: Modelo de Datos y Máquina de Estados (`UserModel` y `AppStage`)

### 1.1 Modificar `UserModel` (`lib/modelos/user_model.dart`)
* **Agregar nuevos campos inmutables:**
  * `final String membershipStatus;` (Valores: `'none'`, `'membership_pending'`, `'change_pending'`, etc. Default: `'none'`).
  * `final int? requestedChurchId;`
  * `final Map<String, dynamic>? requestedChurchData;`
  * `final bool hasActiveSubscription;` (Directo de `church['has_active_subscription'] == true`).
* **Actualizar `UserModel.fromOdooJson(Map<String, dynamic> odooData)`:**
  * Extraer `membership_status` directamente del nivel raíz o dentro de `member['status']`.
  * Extraer `requested_church_id` del nivel raíz.
  * Extraer `has_active_subscription` desde `church['has_active_subscription'] == true`.
  * Mantener retrocompatibilidad absoluta con las propiedades ya existentes (`role`, `permissions`, `isReadOnly`, etc.).

### 1.2 Crear el Enum y Función `resolveStage` (`lib/modelos/app_stage.dart`)
Crear un archivo desacoplado y comprobable mediante pruebas unitarias:
```dart
enum AppStage {
  welcome,
  chooseChurch,
  waitingApproval,
  churchPendingActivation,
  memberHome,
  adminHome,
  platformAdmin,
}

AppStage resolveStage(Map<String, dynamic>? me) {
  if (me == null) return AppStage.welcome;
  
  final role = me['role'] as String?;
  final status = me['membership_status'] as String?;
  final church = me['church'] as Map<String, dynamic>?;
  final bool activeSubscription = church?['has_active_subscription'] == true;

  if (role == 'platform_admin') return AppStage.platformAdmin;
  if (status == 'membership_pending') return AppStage.waitingApproval;
  if (role == 'church_admin') {
    return activeSubscription ? AppStage.adminHome : AppStage.churchPendingActivation;
  }
  if (role == 'member' && activeSubscription) {
    return AppStage.memberHome;
  }
  if (status == 'change_pending') {
    return AppStage.memberHome;
  }
  
  // role == 'user' o sin iglesia vinculada
  return AppStage.chooseChurch;
}
```

### 1.3 Integrar `AppStage` en `UserProvider` (`lib/providers/user_provider.dart`)
* Añadir getter `AppStage get currentStage => resolveStage(_rawMeData);`.
* Almacenar `Map<String, dynamic>? _rawMeData;` cada vez que se invoque exitosamente `_api.me()`, `login()` o `loginWithGoogle()`.
* Añadir método `Future<AppStage> checkCurrentStage()` para consultas rápidas al resumir la aplicación (`didChangeAppLifecycleState`).

---

## Etapa 2: Endpoints y Cliente HTTP (`AtrioApi`)

### 2.1 Método Oficial `loginWithGoogle` en `AtrioApi` (`lib/atrio_api.dart`)
Reemplazar la llamada a endpoints genéricos de fallback por la implementación oficial:
```dart
Future<Map<String, dynamic>> loginWithGoogle({
  required String idToken,
  String deviceName = 'Flutter App',
}) async {
  final data = await _send(
    'POST',
    '/auth/google',
    body: {
      'id_token': idToken,
      'device_name': deviceName,
    },
    retryAuth: false,
  );

  token = (data['token'] ?? data['access_token']) as String?;
  refreshToken = data['refresh_token'] as String?;

  if (storageService != null && token != null && refreshToken != null) {
    await storageService!.saveTokens(
      accessToken: token!,
      refreshToken: refreshToken!,
    );
  }

  return data;
}
```

### 2.2 Endpoint `createMyChurch` en `AtrioApi` (`lib/atrio_api.dart`)
Permite a usuarios autenticados crear una congregación:
```dart
Future<Map<String, dynamic>> createMyChurch(Map<String, dynamic> churchData) {
  return _send(
    'POST',
    '/me/church',
    body: churchData,
  );
}
```

### 2.3 Perfeccionamiento de `_traducirErrorOdoo` en `UserProvider`
Asegurar que los siguientes códigos de error devueltos por Odoo se traduzcan exactamente como exige la guía:
* `invalid_credentials` ➔ `"Correo o contraseña incorrectos."`
* `email_taken` ➔ `"Ese correo ya tiene una cuenta registrada. Inicia sesión o recupera tu contraseña."`
* `weak_password` ➔ `"La contraseña debe tener un mínimo de 8 caracteres."`
* `church_not_found` ➔ `"La iglesia seleccionada ya no está disponible."`
* `already_member` ➔ `"Ya eres miembro de una iglesia activa."`
* `account_exists` ➔ `"Ya existe una cuenta con este correo. Ingresa con tu contraseña."`
* `email_not_verified` ➔ `"Tu cuenta de Google no tiene el correo electrónico verificado."`
* `invalid_google_token` ➔ `"El token de autenticación de Google no es válido o ha expirado."`
* `signup_disabled` ➔ `"El registro de nuevos usuarios no está disponible en este momento."`
* `google_disabled` ➔ `"El inicio de sesión con Google está temporalmente desactivado."`

---

## Etapa 3: Pantallas de Espera y Selección de Camino

### 3.1 Pantalla: Elegir Camino (`lib/screens/elegir_camino_iglesia_screen.dart`)
* **Cuándo se muestra:** `AppStage.chooseChurch` (Usuario nuevo registrado por correo o Google).
* **Componentes UI:**
  * Encabezado con bienvenida cálida y nombre del usuario.
  * **Opción A:** Tarjeta/Botón *"Unirme a una iglesia existente"* ➔ Navega a `SeleccionarIglesiaScreen`.
  * **Opción B:** Tarjeta/Botón *"Registrar mi congregación"* ➔ Navega a `CrearMiIglesiaScreen`.
  * Botón secundario *"Explorar como invitado"* (Permite navegar con permisos mínimos de `user`).
  * Botón para cerrar sesión de manera segura.

### 3.2 Pantalla: Esperando Aprobación (`lib/screens/esperando_aprobacion_screen.dart`)
* **Cuándo se muestra:** `AppStage.waitingApproval` (`membership_status == 'membership_pending'`).
* **Componentes UI:**
  * Ilustración de espera / icono de reloj de arena o iglesia.
  * Título: *"Solicitud en revisión"*.
  * Nombre y logo de la iglesia a la que solicitó ingreso (`requested_church_id` / datos devueltos en `/me`).
  * Mensaje informativo: *"El pastor o administrador de la iglesia debe aprobar tu solicitud para que puedas acceder a las actividades y muro congregacional."*
  * Botón principal con spinner: *"Comprobar estado"* ➔ Ejecuta `await userProvider.refreshUserProfile()` y re-evalúa `AppStage`.
  * **Manejo de rechazo:** Si al refrescar, `membership_status` vuelve a `'none'`, muestra diálogo o aviso: *"Tu solicitud no fue aprobada por la administración. Puedes elegir otra iglesia."* y redirige a `AppStage.chooseChurch`.
  * Botón secundario: *"Cerrar sesión"*.

### 3.3 Pantalla: Iglesia Pendiente de Activación (`lib/screens/iglesia_pendiente_activacion_screen.dart`)
* **Cuándo se muestra:** `AppStage.churchPendingActivation` (`role == 'church_admin'` & `has_active_subscription == false`).
* **Componentes UI:**
  * Tarjeta distintiva dorada/azul con el nombre de la congregación creada.
  * Mensaje explicativo: *"Tu iglesia ha sido registrada exitosamente. El equipo de ATRIO está validando los datos para asignar el plan de suscripción correspondiente."*
  * Enlace/Botón informativo: *"Mientras tanto, puedes completar los datos de tu iglesia ingresando desde un navegador a la consola web: atrioapp.odoo19rd.com/atrio/manage"*
  * Botón principal: *"Actualizar estado"* ➔ Ejecuta `GET /me`. Si `church.has_active_subscription == true`, transiciona automáticamente a `AppStage.adminHome`.
  * Botón secundario para cerrar sesión.

### 3.4 Pantalla: Formulario para Crear Iglesia (`lib/screens/crear_mi_iglesia_screen.dart`)
* **Cuándo se invoca:** Desde `ElegirCaminoIglesiaScreen` para usuario autenticado.
* **Campos del formulario:**
  * Nombre de la iglesia (`name` - obligatorio).
  * Teléfono congregacional (`phone` - opcional).
  * Dirección física (`address` - opcional).
  * Ciudad (`city` - opcional).
  * Coordenadas GPS opcionales (o autodetectadas vía `Geolocator`).
* **Acción al guardar:**
  * Invoca `api.createMyChurch(payload)`.
  * Al responder 201: refresca `/me` y salta de inmediato a `AppStage.churchPendingActivation`.

---

## Etapa 4: Integración en Pantallas Existentes (Login, Google, Registro y Mapa)

### 4.1 Enrutador Central de Flujo en `InicioSesionScreen` (`lib/screens/inicio_sesion_screen.dart`)
* Reemplazar `_redirigirUsuarioPostLogin` por un método que evalúe `AppStage`:
```dart
void _navegarSegunStage(AppStage stage) {
  switch (stage) {
    case AppStage.welcome:
      break;
    case AppStage.chooseChurch:
      Navigator.pushNamedAndRemoveUntil(context, ElegirCaminoIglesiaScreen.routeName, (r) => false);
      break;
    case AppStage.waitingApproval:
      Navigator.pushNamedAndRemoveUntil(context, EsperandoAprobacionScreen.routeName, (r) => false);
      break;
    case AppStage.churchPendingActivation:
      Navigator.pushNamedAndRemoveUntil(context, IglesiaPendienteActivacionScreen.routeName, (r) => false);
      break;
    case AppStage.memberHome:
    case AppStage.adminHome:
    case AppStage.platformAdmin:
      Navigator.pushNamedAndRemoveUntil(context, InicioAtrioScreen.routeName, (r) => false);
      break;
  }
}
```
* **En el botón de Google:**
  * Obtener el `idToken` de GoogleSignIn.
  * Llamar a `userProvider.api.loginWithGoogle(idToken: idToken)`.
  * Si `data['created'] == true`, mostrar bienvenida breve y navegar a `AppStage.chooseChurch`.
  * Capturar excepciones `AtrioApiException` con switch en `e.code`:
    * `'account_exists'`: Mostrar SnackBar/Diálogo *"Ya tienes una cuenta registrada con este correo. Ingresa con tu contraseña."*
    * `'email_not_verified'`: *"Tu cuenta de Google no tiene el correo verificado."*
    * Realizar `googleSignIn.signOut()` si ocurre un error para permitir reintentar con otra cuenta.

### 4.2 En `SeleccionarIglesiaScreen` (`lib/screens/seleccionar_iglesia_screen.dart`)
* En el método `_registrarIglesia(iglesia)`:
  * Si el usuario **está autenticado**:
    * Ejecutar `await userProvider.api.requestMembership(iglesia.id)`.
    * Actualizar `userProvider.refreshUserProfile()`.
    * Navegar hacia `EsperandoAprobacionScreen.routeName`.
  * Si el usuario es un **invitado no autenticado**:
    * Mantener el guardado de selección local en SQLite y `IglesiaProvider` y redirigir a `InicioAtrioScreen`.

### 4.3 En `CrearCuentaScreen` (`lib/screens/crear_cuenta_screen.dart`)
* Validar que la contraseña cumpla con mínimo 8 caracteres (según API de Odoo: `weak_password`).
* Permitir llegar a esta pantalla habiendo seleccionado previamente una iglesia (recibiendo `church_id` por argumentos) o sin ella.
* Al completar el registro exitoso:
  * Iniciar sesión automáticamente (`login`).
  * Consultar `resolveStage` y redirigir a `EsperandoAprobacionScreen` o `ElegirCaminoIglesiaScreen`.

### 4.4 En `InicioAtrioScreen` (`lib/screens/inicio_atrio_screen.dart`)
* Si `userProvider.currentUser?.membershipStatus == 'change_pending'`:
  * Mostrar un banner discreto en la parte superior:  
    `"Has solicitado cambio de iglesia. Tu solicitud está en revisión por la nueva congregación."`

---

## Etapa 5: Enrutamiento, Ciclo de Vida y Notificaciones Push

### 5.1 Registro Central de Rutas en `lib/main.dart`
Agregar en `MyApp._routes`:
```dart
ElegirCaminoIglesiaScreen.routeName: (_) => const ElegirCaminoIglesiaScreen(),
EsperandoAprobacionScreen.routeName: (_) => const EsperandoAprobacionScreen(),
IglesiaPendienteActivacionScreen.routeName: (_) => const IglesiaPendienteActivacionScreen(),
CrearMiIglesiaScreen.routeName: (_) => const CrearMiIglesiaScreen(),
```

### 5.2 Determinación de Ruta Inicial en `main()`
En `lib/main.dart`, en el arranque de la app:
```dart
// Si hay tokens guardados, intentar auto-login y resolver stage
if (isLoggedIn) {
  // Inicializar UserProvider pasivamente
  // Si stage == waitingApproval -> EsperandoAprobacionScreen
  // Si stage == churchPendingActivation -> IglesiaPendienteActivacionScreen
  // Si stage == chooseChurch -> ElegirCaminoIglesiaScreen
  // Si stage == memberHome / adminHome -> InicioAtrioScreen
}
```

### 5.3 Ciclo de Vida: Reconexión al Volver a Primer Plano
En el widget principal o `InicioAtrioScreen` / pantallas de espera:
* Observar `WidgetsBindingObserver.didChangeAppLifecycleState`.
* Cuando el estado sea `AppLifecycleState.resumed`:
  * Ejecutar en segundo plano `userProvider.refreshUserProfile()`.
  * Si el stage cambió (por ejemplo: el pastor aprobó la membresía mientras la app estaba en segundo plano), la UI se actualizará automáticamente sin obligar al usuario a reiniciar la app.

### 5.4 Manejo de Notificaciones Push (`DeviceNotificationService`)
* Escuchar notificaciones entrantes cuando `data['type'] == 'membership'` con `status == 'approved'`:
  * Llamar inmediatamente a `userProvider.refreshUserProfile()`.
  * Navegar dinámicamente a `InicioAtrioScreen` con mensaje: *"¡Tu membresía ha sido aprobada!"*.

---

## Etapa 6: Checklist de Validación y Casos de Prueba

| # | Caso de Prueba | Comportamiento Esperado | Estado |
|---|----------------|-------------------------|:------:|
| 1 | **Registro correo + solicitud iglesia** | Completa formulario con iglesia ➔ `POST /register` ➔ `POST /auth/login` ➔ Cae en `EsperandoAprobacionScreen`. | [x] |
| 2 | **Pastor aprueba solicitud** | Pastor aprueba en Odoo ➔ Usuario pulsa "Actualizar" (o llega push) ➔ `GET /me` devuelve `role: member` ➔ Pasa a `InicioAtrioScreen`. | [x] |
| 3 | **Pastor rechaza solicitud** | Pastor rechaza en Odoo ➔ Usuario pulsa "Actualizar" ➔ `membership_status` vuelve a `none` ➔ Alerta de rechazo ➔ Pasa a `ElegirCaminoIglesiaScreen`. | [x] |
| 4 | **Creación de iglesia con cuenta nueva** | Formulario de iglesia ➔ `POST /churches/register` ➔ Login ➔ Cae en `IglesiaPendienteActivacionScreen`. | [x] |
| 5 | **Activación de iglesia por Atrio** | Atrio activa suscripción ➔ Usuario pulsa "Actualizar" ➔ `has_active_subscription == true` ➔ Pasa a `InicioAtrioScreen` (Admin). | [x] |
| 6 | **Google con usuario nuevo** | `signIn()` ➔ `POST /auth/google` devuelve `created: true` ➔ Cae en `ElegirCaminoIglesiaScreen`. | [x] |
| 7 | **Google con usuario existente** | `signIn()` ➔ `POST /auth/google` devuelve `created: false` ➔ Entra directo a su perfil/home según su membresía. | [x] |
| 8 | **Google con correo no verificado** | Google no verified ➔ Odoo responde 400 `email_not_verified` ➔ Se muestra advertencia amigable sin trabar la app. | [x] |
| 9 | **Google con correo existente con contraseña** | Correo ya registrado sin Google ➔ Odoo responde 409 `account_exists` ➔ Pide contraseña tradicional. | [x] |
| 10 | **Solicitud de cambio de iglesia** | Miembro activo pide cambio en el mapa ➔ `POST /membership/request` ➔ Estado `change_pending` ➔ Mantiene acceso con aviso visible. | [x] |
| 11 | **Token expirado (30 min)** | App abierta o en background ➔ Llamada recibe 401 ➔ `AtrioApi` renueva silenciosamente con `/auth/refresh` y completa la petición sin cerrar sesión. | [x] |
| 12 | **Cierre de sesión seguro** | Clic en Cerrar sesión ➔ `DELETE /devices` ➔ `POST /auth/logout` ➔ Limpia almacenamiento seguro y SQLite ➔ Cae en `InicioSesionScreen`. | [x] |

---

> **Regla de oro de implementación:** Cada etapa debe verificarse con `flutter analyze` asegurando cero linter errors y respetando las pantallas y utilidades visuales ya pulidas en el proyecto.
