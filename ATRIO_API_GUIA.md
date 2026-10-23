# API de Atrio — Guía de integración

Versión del módulo: **19.0.4** · Documentación interactiva: consola Atrio Plataforma → **Documentación API** · Especificación: `GET /atrio/portal/api/openapi.json` (requiere sesión).

## Índice

1. [Datos generales](#1-datos-generales)
2. [Autenticación](#2-autenticación)
3. [Contraseñas](#3-contraseñas)
4. [Errores](#4-errores)
5. [Roles y permisos](#5-roles-y-permisos)
6. [Super Admin (solo lectura)](#6-super-admin-solo-lectura)
7. [Moderación de Atrio](#7-moderación-de-atrio)
8. [Donaciones y publicidad](#8-donaciones-y-publicidad)
9. [Referencia de endpoints](#9-referencia-de-endpoints)

---

## 1. Datos generales

| Concepto | Valor |
| --- | --- |
| URL base | `https://atrioapp.odoo19rd.com/atrio/portal/api` |
| Autenticación | `Authorization: Bearer <token>` obtenido en `POST /auth/login` |
| Base de datos | `X-Odoo-Database: <base>`, solo si el servidor aloja varias bases |
| Formato | JSON UTF-8 · vacíos como `null` · fechas `YYYY-MM-DD` · datetimes en UTC ISO 8601 · imágenes como URL |
| Idempotencia | `Idempotency-Key: <uuid>` en escrituras: un reintento con la misma clave no repite la operación (vigencia 24 h) |
| Ficha de iglesia | Identidad, contacto, redes, ubicación, horarios y URLs de logo y portada |

---

## 2. Autenticación

```
1. Login          → envía usuario y contraseña una sola vez
2. Guardar token  → en almacenamiento seguro
3. Usar Bearer    → en cada endpoint protegido
4. Cerrar sesión  → revoca solo el token de ese dispositivo
```

> El **access token** dura **30 minutos** y el **refresh token** **90 días**. Al renovar se rotan ambos: reemplazá los dos valores guardados.

### 2.1 Iniciar sesión

```http
POST /atrio/portal/api/auth/login
Content-Type: application/json
X-Odoo-Database: nombre_base   (solo si aplica)

{
  "login": "juan@gmail.com",
  "password": "••••••••",
  "device_name": "Pixel 8"
}
```

Respuesta `200`:

```json
{
  "token": "3f9a…c21",
  "access_token": "3f9a…c21",
  "token_type": "Bearer",
  "expires_in": 1800,
  "expires_at": "2026-09-19T23:30:00Z",
  "refresh_token": "refresh-secret…",
  "refresh_expires_at": "2026-12-18T23:00:00Z",
  "user": { "id": 42, "name": "Juan Pérez", "role": "member", "permissions": ["..."], "read_only": false },
  "role": "member",
  "permissions": ["view_content", "register_events", "..."],
  "read_only": false,
  "member": { "id": 12, "name": "Juan Pérez" },
  "church": {
    "id": 1,
    "name": "Iglesia Central",
    "public_name": "Comunidad Central",
    "denomination": "Iglesia Evangélica",
    "slogan": "Una iglesia, una familia, una misión",
    "address": "Zona 1", "city": "Ciudad de Guatemala",
    "country": "Guatemala", "state": "Guatemala",
    "latitude": 14.6349, "longitude": -90.5069,
    "logo_url": "/atrio/portal/api/image/atrio.church/1/logo",
    "cover_url": "/atrio/portal/api/image/atrio.church/1/cover_image",
    "meeting_schedule": [{ "day": "Domingo", "start": "09:00", "end": "10:30", "label": "Culto principal" }],
    "approx_member_count": 250, "foundation_year": 2015,
    "focus_areas": "Evangelismo, discipulado, familia",
    "congregation_languages": "Español, Inglés",
    "email": "contacto@iglesia.org", "phone": "+502 2222 0000",
    "whatsapp": "+502 5555 1234", "website": "https://iglesia.org",
    "facebook_url": "https://facebook.com/iglesiacentral",
    "instagram_url": "https://instagram.com/iglesiacentral",
    "youtube_url": "https://youtube.com/@iglesiacentral",
    "has_active_subscription": true
  }
}
```

Con curl:

```bash
curl -X POST "https://atrioapp.odoo19rd.com/atrio/portal/api/auth/login" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"login":"juan@gmail.com","password":"mi-clave","device_name":"Pixel 8"}'
```

### 2.2 Llamadas autenticadas

Copiá exactamente el valor de `token` y ponelo después de `Bearer`, separado por un espacio. Nunca envíes la contraseña ni el token en la URL.

```http
GET /atrio/portal/api/events?upcoming=1&limit=20
Accept: application/json
Authorization: Bearer 3f9a…c21
```

```bash
curl "https://atrioapp.odoo19rd.com/atrio/portal/api/me" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 3f9a…c21"
```

### 2.3 Renovar la sesión

```http
POST /atrio/portal/api/auth/refresh
Content-Type: application/json

{ "refresh_token": "refresh-secret…" }
```

La respuesta trae dos tokens nuevos; descartá los anteriores.

### 2.4 Cerrar sesión

```http
POST /atrio/portal/api/auth/logout
Content-Type: application/json
Authorization: Bearer 3f9a…c21

{}
```

Respuesta: `{"success": true}`. Cada dispositivo tiene su propio token: cerrar uno no desconecta los demás.

---

## 3. Contraseñas

| Caso | Endpoint | Sesión | Detalle |
| --- | --- | --- | --- |
| Olvidé mi contraseña | `POST /auth/password/reset` | No | Envía por correo el enlace de Odoo para crear una nueva. Responde siempre igual, exista o no la cuenta. |
| Cambiar contraseña | `POST /me/password` | Sí | `old_password` y `new_password` (mínimo 8). Si la actual no coincide: `400 wrong_password`. |

```http
POST /atrio/portal/api/auth/password/reset
Content-Type: application/json

{ "login": "juan@gmail.com" }
```

```json
{ "success": true, "message": "Si la cuenta existe, te enviamos un correo con un enlace para crear una contraseña nueva." }
```

---

## 4. Errores

Todos los errores son JSON con `error` (texto para mostrar) y `code` (valor estable para decidir). Nunca se devuelve HTML ni redirecciones.

```http
HTTP/1.1 409 Conflict

{ "error": "El evento no tiene cupos disponibles.", "code": "event_full" }
```

| Estado | Códigos | Qué hacer |
| --- | --- | --- |
| 400 | `missing_fields`, `invalid_params`, `invalid_value`, `invalid_email`, `weak_password`, `invalid_amount`, `invalid_donor`, `invalid_date`, `receipt_required`, `email_taken`, `wrong_password`, `validation_error`, `response_required`, `title_required`, `required_fields`, `group_required`, `invalid_group`, `scheduled_date_required`, `send_date_required` | Datos incorrectos: mostrar el mensaje. `validation_error` incluye las palabras bloqueadas por Atrio. |
| 400 | `church_required` | Super Admin sin iglesia elegida: enviar `X-Atrio-Church`. |
| 401 | `unauthorized`, `invalid_token`, `invalid_refresh_token`, `invalid_credentials` | Renovar el token o volver al login si falló el refresh. |
| 403 | `read_only` | El Super Admin es de solo lectura: ocultar crear, editar y borrar. |
| 403 | `forbidden`, `no_church`, `not_church_admin`, `not_platform_admin`, `subscription_required`, `membership_pending`, `church_deactivated` | Sin permiso, iglesia sin activar o desactivada, o ingreso pendiente. |
| 404 | `not_found`, `no_member`, `church_not_found` | No existe o no pertenece a la iglesia del usuario. |
| 404 | `content_unavailable` | Atrio bloqueó el contenido: mostrar «Este contenido ya no está disponible» y quitarlo de la caché. |
| 409 | `event_full`, `event_past`, `registration_closed`, `already_sent` | La acción no es posible en el estado actual. |
| 500 | `server_error` | Error inesperado: reintentar más tarde. |

---

## 5. Roles y permisos

`GET /me` y el login devuelven `role`, `permissions` y `read_only`. Usá `permissions` para mostrar u ocultar opciones; el servidor vuelve a comprobar cada acción.

| `role` | Quién es | `permissions` |
| --- | --- | --- |
| *(sin sesión)* | Invitado | — |
| `user` | Registrado, aún sin iglesia aprobada | `manage_profile`, `donate` |
| `member` | Miembro de una iglesia | `view_content`, `register_events`, `create_offerings`, `create_requests`, `manage_profile`, `shop`, `donate` |
| `church_admin` | Administrador de su iglesia | lo de `member` + `manage_posts`, `manage_events`, `manage_announcements`, `manage_requests`, `view_stats`, `manage_ads`, `view_admin_notifications` |
| `platform_admin` | Super Admin de Atrio (solo lectura) | `view_all_churches`, `view_content`, `view_admin_content`, `read_only` |

```json
{
  "user": {
    "id": 14,
    "name": "Pastor Carlos",
    "email": "carlos@iglesia.org",
    "role": "church_admin",
    "permissions": ["view_content", "manage_posts", "manage_events", "manage_announcements", "..."],
    "read_only": false
  },
  "role": "church_admin",
  "permissions": ["..."],
  "read_only": false
}
```

### Qué puede hacer un invitado (sin sesión)

- Login, renovar sesión y recuperar contraseña.
- Directorio de iglesias, planes, alta de iglesia y registro de miembro.
- Catálogo de la tienda: productos, categorías e imágenes (comprar pide sesión).
- Donar a Atrio y ver los testimonios.
- Logos y portadas de iglesias activas.

### Administrador de iglesia

| Recurso | Qué hace |
| --- | --- |
| `/admin/posts` | Publicaciones. `action` = `draft`, `publish` o `schedule`. `pinned` las fija arriba. |
| `/admin/events` | Eventos; `/admin/events/{id}/registrations` lista los inscritos. |
| `/admin/announcements` | Avisos push a la congregación. `action` = `draft`, `send` o `schedule`. `pinned` los fija. |
| `/admin/requests` | Solicitudes de los miembros. `action` = `approve`, `reject` (con `reason`) o `answer` (con `response`). |
| `/admin/stats` | Estadísticas de la comunidad: `period` = `week`, `month` o `year`. |
| `/admin/groups` | Grupos para la audiencia `grupo`. |
| `/admin/notifications` | Campanita del administrador (no confundir con los avisos). |

---

## 6. Super Admin (solo lectura)

1. Inicia sesión con su usuario: `role` = `platform_admin`, `read_only` = `true`.
2. Lista las iglesias con `GET /platform/churches` (incluye inactivas).
3. Envía el id elegido en la cabecera `X-Atrio-Church` y usa los mismos endpoints que una iglesia (`/posts`, `/events`, `/admin/posts`…).
4. Cualquier escritura responde `403 read_only`; sin cabecera, `400 church_required`. Solo puede cerrar sesión y registrar su dispositivo.

> La cabecera `X-Atrio-Church` solo tiene efecto para el Super Admin. A cualquier otro usuario se le ignora: su iglesia sale siempre del token.

```http
GET /atrio/portal/api/platform/churches?search=central
Authorization: Bearer <token del Super Admin>

GET /atrio/portal/api/posts
Authorization: Bearer <token del Super Admin>
X-Atrio-Church: 7
```

---

## 7. Moderación de Atrio

| Tema | Comportamiento |
| --- | --- |
| Contenido bloqueado | No aparece en las listas de miembros. Su detalle responde `404 content_unavailable`. |
| Caché del cliente | Al refrescar, reemplazar la lista guardada con la respuesta (no solo agregar lo nuevo). |
| Palabras restringidas | Crear o editar con una palabra bloqueada responde `400 validation_error` con el mensaje. |
| Administrador | `/admin/*` trae `moderation: {hidden, reason, hidden_at}`. Al bloquear o desbloquear llega un aviso a la campanita con `category: "moderation"`. |

---

## 8. Donaciones y publicidad

Los pagos con PayPal se completan en el navegador del sistema con `checkout_url`; las transferencias envían el comprobante en base64.

### Donar a Atrio con PayPal — cualquier persona, sin sesión

1. `GET /donations/options` → montos sugeridos en USD (`paypal.presets`) si `paypal.available` es `true`.
2. `POST /donations/paypal` con `name`, `email`, `amount` (opcionales: `phone`, `notes`, `public_consent`, `donor_location`).
3. Abrir `checkout_url` en el navegador del sistema, no en un WebView.
4. Cuando PayPal confirma, la donación pasa a `processed` y el donante recibe su recibo por correo.

### Donar a Atrio por transferencia — cualquier persona, sin sesión

1. `GET /donations/options` → `transfer` trae banco, titular, número de cuenta, moneda y montos sugeridos.
2. El donante transfiere y toma foto del comprobante.
3. `POST /donations/transfer` con los datos y `receipt_file` en base64 (+ `receipt_filename`).
4. Queda `pending` hasta que el Super Admin lo verifica. `GET /donations/mine` muestra el estado a usuarios con sesión.

### Comprar un anuncio — solo administradores de una iglesia activa

1. `GET /admin/ads/targets?kind=country|state|city|church&q=…` para la segmentación.
2. `POST /admin/ads/quote` en cada cambio para mostrar precio y alcance.
3. `POST /admin/ads` envía el anuncio (`image` en base64). Estado `requested`: Atrio lo revisa.
4. Al aprobarse llega un aviso a `/admin/notifications` (`category: "ad"`) y el anuncio trae `payable: true`.
5. Pago: `POST /admin/ads/{id}/pay/paypal` (abrir `checkout_url`) o `POST /admin/ads/{id}/pay/transfer` con el comprobante.
6. Confirmado el pago se publica solo. `GET /admin/ads/{id}/stats` da impresiones, clics y CTR.

### Mostrar anuncios a los miembros — usuarios con sesión

1. `GET /posts` y `GET /notifications` traen en la primera página una lista `sponsored` (máximo 2).
2. Mostrar cada anuncio con su `label` ("Publicidad").
3. Al tocarlo: `POST /ads/{id}/click` registra el clic y devuelve `redirect_url` para abrir en el navegador.
4. Las imágenes se piden a `image_url` con el mismo token Bearer.

---

## 9. Referencia de endpoints

Rutas relativas a la URL base. **Pública** = no requiere token.

### Autenticación

| Método | Ruta | Descripción | Acceso |
| --- | --- | --- | --- |
| POST | `/auth/login` | Iniciar sesión y obtener token | Pública |
| POST | `/auth/refresh` | Renovar y rotar tokens | Pública |
| POST | `/auth/logout` | Revocar el token actual | Token |
| POST | `/auth/password/reset` | Olvidé mi contraseña | Pública |

### Público

| Método | Ruta | Descripción | Acceso |
| --- | --- | --- | --- |
| GET | `/churches` | Directorio de iglesias | Pública |
| POST | `/churches/register` | Alta de una iglesia | Pública |
| GET | `/plans` | Planes disponibles | Pública |
| POST | `/register` | Registro de un miembro | Pública |
| GET | `/image/{model}/{record_id}/{field}` | Imagen de un registro | Pública* |

\* Logos de iglesias e imágenes de productos son públicos; las demás imágenes piden token.

### Perfil

| Método | Ruta | Descripción | Acceso |
| --- | --- | --- | --- |
| GET | `/me` | Usuario, rol, permisos, miembro e iglesia | Token |
| PUT | `/me` | Actualizar el propio perfil | Token |
| POST | `/me/password` | Cambiar la contraseña | Token |
| POST | `/membership/request` | Solicitar ingreso o cambio de iglesia | Token |
| POST | `/devices` | Registrar dispositivo para push | Token |
| DELETE | `/devices` | Dejar de recibir push en un dispositivo | Token |

### Contenido

| Método | Ruta | Descripción | Acceso |
| --- | --- | --- | --- |
| GET | `/posts` | Publicaciones de la iglesia (fijadas primero) | Token |
| GET | `/posts/{post_id}` | Detalle de una publicación | Token |
| GET | `/notifications` | Notificaciones enviadas (fijadas primero) | Token |

### Eventos

| Método | Ruta | Descripción | Acceso |
| --- | --- | --- | --- |
| GET | `/events` | Eventos de la iglesia | Token |
| GET | `/events/{event_id}` | Detalle de un evento | Token |
| POST | `/events/{event_id}/register` | Inscribirse a un evento | Token |
| DELETE | `/events/{event_id}/register` | Anular la inscripción | Token |

### Ofrendas y solicitudes

| Método | Ruta | Descripción | Acceso |
| --- | --- | --- | --- |
| GET | `/offerings` | Ofrendas propias | Token |
| POST | `/offerings` | Registrar una ofrenda | Token |
| GET | `/requests` | Solicitudes propias (con respuesta o motivo de rechazo) | Token |
| POST | `/requests` | Crear una solicitud | Token |

### Tienda

| Método | Ruta | Descripción | Acceso |
| --- | --- | --- | --- |
| GET | `/store/products` | Catálogo de la tienda Atrio | Pública |
| GET | `/store/products/{product_id}` | Detalle de un producto | Pública |
| GET | `/store/categories` | Categorías de la tienda | Pública |
| GET | `/store/cart` | Mi carrito | Token |
| DELETE | `/store/cart` | Vaciar el carrito | Token |
| POST | `/store/cart/items` | Agregar al carrito | Token |
| PUT | `/store/cart/items/{product_id}` | Cambiar cantidad | Token |
| DELETE | `/store/cart/items/{product_id}` | Quitar del carrito | Token |
| POST | `/store/checkout` | Confirmar pedido | Token |
| GET | `/orders` | Mis pedidos | Token |

### Donaciones

| Método | Ruta | Descripción | Acceso |
| --- | --- | --- | --- |
| GET | `/donations/options` | Métodos de donación disponibles | Pública |
| POST | `/donations/paypal` | Donar con PayPal | Pública |
| POST | `/donations/transfer` | Donar por transferencia (con comprobante) | Pública |
| GET | `/donations/testimonials` | Gracias a nuestros donantes | Pública |
| GET | `/donations/mine` | Mis donaciones | Token |

### Publicidad (miembros)

| Método | Ruta | Descripción | Acceso |
| --- | --- | --- | --- |
| GET | `/ads` | Anuncios vigentes para la iglesia del usuario | Token |
| POST | `/ads/{ad_id}/click` | Registrar un clic en un anuncio | Token |

### Administrador de iglesia

| Método | Ruta | Descripción | Acceso |
| --- | --- | --- | --- |
| GET | `/admin/posts` | Publicaciones de mi iglesia (todas) | Admin |
| POST | `/admin/posts` | Crear una publicación | Admin |
| GET | `/admin/posts/{post_id}` | Detalle de una publicación | Admin |
| PUT | `/admin/posts/{post_id}` | Editar una publicación | Admin |
| DELETE | `/admin/posts/{post_id}` | Eliminar una publicación | Admin |
| GET | `/admin/events` | Eventos de mi iglesia (todos) | Admin |
| POST | `/admin/events` | Crear un evento | Admin |
| GET | `/admin/events/{event_id}` | Detalle de un evento | Admin |
| PUT | `/admin/events/{event_id}` | Editar un evento | Admin |
| DELETE | `/admin/events/{event_id}` | Eliminar un evento | Admin |
| GET | `/admin/events/{event_id}/registrations` | Inscritos a un evento | Admin |
| GET | `/admin/announcements` | Avisos de mi iglesia (todos) | Admin |
| POST | `/admin/announcements` | Crear un aviso | Admin |
| GET | `/admin/announcements/{notification_id}` | Detalle de un aviso | Admin |
| PUT | `/admin/announcements/{notification_id}` | Editar, enviar o fijar un aviso | Admin |
| DELETE | `/admin/announcements/{notification_id}` | Eliminar un aviso | Admin |
| GET | `/admin/requests` | Solicitudes de los miembros | Admin |
| GET | `/admin/requests/{request_id}` | Detalle de una solicitud | Admin |
| PUT | `/admin/requests/{request_id}` | Aprobar, rechazar o responder una solicitud | Admin |
| GET | `/admin/stats` | Estadísticas de la comunidad | Admin |
| GET | `/admin/groups` | Grupos de la iglesia | Admin |
| GET | `/admin/notifications` | Avisos para el administrador (campanita) | Admin |
| POST | `/admin/notifications/read` | Marcar avisos como leídos | Admin |
| POST | `/admin/notifications/dismiss` | Borrar avisos | Admin |

### Publicidad (iglesia)

| Método | Ruta | Descripción | Acceso |
| --- | --- | --- | --- |
| GET | `/admin/ads` | Anuncios de mi iglesia | Admin |
| GET | `/admin/ads/targets` | Opciones de segmentación | Admin |
| POST | `/admin/ads/quote` | Cotizar un anuncio | Admin |
| POST | `/admin/ads` | Enviar un anuncio a revisión | Admin |
| DELETE | `/admin/ads/{ad_id}` | Retirar una solicitud aún no revisada | Admin |
| GET | `/admin/ads/{ad_id}/payment` | Datos de pago de un anuncio aprobado | Admin |
| POST | `/admin/ads/{ad_id}/pay/paypal` | Pagar un anuncio con PayPal | Admin |
| POST | `/admin/ads/{ad_id}/pay/transfer` | Pagar un anuncio por transferencia | Admin |
| GET | `/admin/ads/{ad_id}/stats` | Estadísticas de un anuncio propio | Admin |

### Super Admin

| Método | Ruta | Descripción | Acceso |
| --- | --- | --- | --- |
| GET | `/platform/churches` | Iglesias para el Super Admin (incluye inactivas) | Super Admin |

**Admin** = token de `church_admin` (el Super Admin también puede leer con `X-Atrio-Church`, sin escribir).
