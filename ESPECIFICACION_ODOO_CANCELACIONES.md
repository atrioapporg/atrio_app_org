# ESPECIFICACIÓN TÉCNICA: Cancelación de Solicitudes y Cambios de Iglesia (Odoo 19 Backend)

> **Destinatario:** Backend Developer / Claude Code (Odoo 19 REST API)  
> **Módulo:** `atrio_portal` / `atrio_membership` / `atrio_requests`  
> **Fecha:** Noviembre 2026  
> **Contexto:** Sincronización bidireccional con la aplicación móvil Flutter de ATRIO.

---

## 1. Contexto y Justificación del Requerimiento

En la aplicación móvil Flutter de ATRIO se implementó una actualización de UX/UI que permite al feligrés:
1. **Cancelar una solicitud de cambio de congregación** (`change_pending`): Si el usuario solicitó trasladarse a otra iglesia pero luego se arrepiente y decide quedarse en su iglesia actual.
2. **Cancelar peticiones pastorales o ministeriales pendientes** (`/requests`): Si el motivo de oración/visita ya fue resuelto antes de que el equipo ministerial lo atienda.

### ¿Por qué Odoo DEBE enterarse de estos cambios?
La app móvil cuenta con **Optimistic UI** (reflejo visual y persistencia local inmediata en SQLite). Sin embargo, si Odoo no actualiza su base de datos:
* En el próximo refresco de sesión (`GET /atrio/portal/api/me`), Odoo devolverá nuevamente `membership_status: "change_pending"` y `requested_church_id: <ID>`, revirtiendo el estado local del feligrés.
* La iglesia de destino seguirá viendo la solicitud en su bandeja pastoral/administrativa y podría **aprobarla por error semanas después**, transfiriendo al feligrés en contra de su voluntad.
* En peticiones pastorales, el pastor perdería tiempo atendiendo una solicitud que el usuario ya no necesita.

---

## 2. Reglas de Negocio Inquebrantables

### Regla A: Cancelación de Cambio de Iglesia (Traslado)
* **Preservación de la Iglesia Actual:** Al cancelar una solicitud de traslado, el campo `church_id` (la congregación actual del usuario) **NUNCA DEBE SER MODIFICADO NI BORRADO**.
* **Limpieza de Destino:** Debe eliminarse la referencia a `requested_church_id` (`False` / `None`).
* **Restauración de Estado:** El estado de membresía (`membership_status`) del usuario debe volver a `'approved'`.
* **Cancelación Lógica del Trámite:** Si existe un registro histórico de la solicitud en un modelo de trámites (ej. `atrio.church.membership.request`), debe transicionar a `'cancelled'` (Soft-Cancel), **no** eliminarse físicamente con `unlink()` para conservar la auditoría.

### Regla B: Cancelación de Peticiones Pastorales (`/requests`)
* **Solo en estado PENDIENTE / INICIAL:** Únicamente se permite cancelar solicitudes en estado `draft`, `pending`, `recibida` o `nueva`.
* **Prohibido cancelar si ya fue atendida:** Si la solicitud ya está en estado `done`, `approved`, `answered`, `atendida` o `completada`, el endpoint **DEBE retornar HTTP 400 Bad Request**. Esto garantiza la inmutabilidad de la bitácora de consejería y protege los KPIs del Dashboard Pastoral.
* **Control de Acceso (RBAC / Ownership):** El feligrés solo puede cancelar peticiones creadas por su propio usuario (`request.env.user.id == solicitud.user_id.id`). De lo contrario, retornar HTTP 403 Forbidden.

---

## 3. Especificación de Endpoints REST para Odoo 19

---

### Endpoint 1: Cancelar Solicitud de Cambio / Membresía

Permite al usuario cancelar su solicitud de traslado a una nueva iglesia (o su solicitud inicial de ingreso si aún no tenía congregación).

* **Ruta Principal:** `POST /atrio/portal/api/membership/cancel`
* **Rutas de Fallback compatibles:**
  * `DELETE /atrio/portal/api/membership/request`
  * `PUT /atrio/portal/api/me` con body `{"requested_church_id": false, "cancel_membership_request": true}`
* **Autenticación:** Requerida (`auth='user'` o Bearer Token JWT en el encabezado `Authorization: Bearer <token>`).
* **Content-Type:** `application/json`

#### Request Payload
Generalmente vacío, o con un motivo opcional:
```json
{}
```

#### Lógica del Backend (Python / Odoo 19)
```python
# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request

class AtrioMembershipController(http.Controller):

    @http.route([
        '/atrio/portal/api/membership/cancel',
        '/atrio/portal/api/membership/request'
    ], type='http', auth='user', methods=['POST', 'DELETE'], csrf=False)
    def cancel_membership(self, **kwargs):
        user = request.env.user
        partner = user.partner_id

        # 1. Verificar si tiene una solicitud de iglesia pendiente
        requested_church_id = getattr(user, 'requested_church_id', False) or getattr(partner, 'requested_church_id', False)
        
        if not requested_church_id and getattr(user, 'membership_status', '') not in ['change_pending', 'pending']:
            return request.make_json_response({
                'status': 'ignored',
                'message': 'No hay ninguna solicitud de cambio o membresía pendiente.'
            }, status=200)

        # 2. Cancelar registros pendientes en el modelo de solicitudes (si aplica)
        if 'atrio.church.membership.request' in request.env:
            solicitudes = request.env['atrio.church.membership.request'].sudo().search([
                ('partner_id', '=', partner.id),
                ('state', 'in', ['draft', 'pending', 'submitted'])
            ])
            if solicitudes:
                solicitudes.write({'state': 'cancelled'})

        # 3. Determinar el estado al que vuelve el usuario
        # Si ya tenía una iglesia asignada aprobada, vuelve a 'approved' manteniendo su church_id
        # Si era un usuario nuevo sin iglesia, vuelve a 'none'
        current_church = getattr(user, 'church_id', False) or getattr(partner, 'church_id', False)
        nuevo_estado = 'approved' if current_church else 'none'

        # 4. Actualizar usuario / partner
        vals_to_write = {
            'requested_church_id': False,
            'membership_status': nuevo_estado,
        }
        
        user.sudo().write(vals_to_write)
        if hasattr(partner, 'requested_church_id'):
            partner.sudo().write(vals_to_write)

        return request.make_json_response({
            'status': 'success',
            'message': 'Solicitud de cambio de congregación cancelada exitosamente.',
            'membership_status': nuevo_estado,
            'church_id': current_church.id if current_church else False,
            'requested_church_id': False
        }, status=200)
```

#### Respuestas HTTP:
* **200 OK:**
  ```json
  {
    "status": "success",
    "message": "Solicitud de cambio de congregación cancelada exitosamente.",
    "membership_status": "approved",
    "church_id": 10,
    "requested_church_id": false
  }
  ```
* **401 Unauthorized:** Si el token ha expirado o no es válido.

---

### Endpoint 2: Cancelar Petición Pastoral Específica

Permite al usuario retirar una petición ministerial u oración radicada que aún no ha sido atendida.

* **Ruta Principal:** `POST /atrio/portal/api/requests/<int:request_id>/cancel`
* **Rutas de Fallback compatibles:**
  * `PUT /atrio/portal/api/requests/<int:request_id>/cancel`
  * `PUT /atrio/portal/api/requests/<int:request_id>` enviando `{"state": "cancelled"}`
* **Autenticación:** Requerida (`auth='user'`).
* **Content-Type:** `application/json`

#### Request Payload
Opcional (puede enviarse vacío o con el estado solicitado):
```json
{
  "state": "cancelled"
}
```

#### Lógica del Backend (Python / Odoo 19)
```python
# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request

class AtrioRequestsController(http.Controller):

    @http.route([
        '/atrio/portal/api/requests/<int:request_id>/cancel',
        '/atrio/portal/api/requests/<int:request_id>'
    ], type='http', auth='user', methods=['POST', 'PUT'], csrf=False)
    def cancel_request(self, request_id, **kwargs):
        # 1. Modelo de peticiones (ajustar al nombre técnico real en el módulo, ej. atrio.request)
        model_name = 'atrio.request'
        if model_name not in request.env:
            model_name = 'atrio.pastoral.request'
            
        solicitud = request.env[model_name].sudo().browse(request_id)

        # 2. Validación de existencia
        if not solicitud.exists():
            return request.make_json_response({
                'error': 'not_found',
                'message': 'La solicitud no existe.'
            }, status=404)

        # 3. Validación de propiedad (RBAC)
        user = request.env.user
        es_propietario = False
        if hasattr(solicitud, 'user_id') and solicitud.user_id == user:
            es_propietario = True
        elif hasattr(solicitud, 'partner_id') and solicitud.partner_id == user.partner_id:
            es_propietario = True

        if not es_propietario and not user.has_group('base.group_system'):
            return request.make_json_response({
                'error': 'forbidden',
                'message': 'No tienes permisos para modificar esta solicitud.'
            }, status=403)

        # 4. Validación de Estado (Regla de Oro: solo cancelar si está pendiente)
        current_state = (solicitud.state or '').lower()
        estados_cancelables = ['draft', 'pending', 'received', 'recibida', 'nueva', 'new']
        estados_bloqueados = ['done', 'completed', 'approved', 'answered', 'atendida', 'respondida', 'rejected']

        if current_state in estados_bloqueados:
            return request.make_json_response({
                'error': 'invalid_state',
                'message': 'No se puede cancelar una petición que ya ha sido atendida o resuelta por el equipo pastoral.'
            }, status=400)

        # 5. Ejecutar Soft-Cancel
        solicitud.write({
            'state': 'cancelled',
            'status_label': 'Cancelada' if hasattr(solicitud, 'status_label') else None
        })

        return request.make_json_response({
            'status': 'success',
            'message': 'Petición cancelada exitosamente.',
            'id': solicitud.id,
            'state': 'cancelled'
        }, status=200)
```

#### Respuestas HTTP:
* **200 OK:**
  ```json
  {
    "status": "success",
    "message": "Petición cancelada exitosamente.",
    "id": 142,
    "state": "cancelled"
  }
  ```
* **400 Bad Request (Si ya fue atendida):**
  ```json
  {
    "error": "invalid_state",
    "message": "No se puede cancelar una petición que ya ha sido atendida o resuelta por el equipo pastoral."
  }
  ```
* **403 Forbidden (Si pertenece a otro usuario):**
  ```json
  {
    "error": "forbidden",
    "message": "No tienes permisos para modificar esta solicitud."
  }
  ```
* **404 Not Found (Si el ID no existe):**
  ```json
  {
    "error": "not_found",
    "message": "La solicitud no existe."
  }
  ```

---

## 4. Efecto Esperado en `GET /atrio/portal/api/me`

Una vez cancelada la solicitud de cambio de iglesia en Odoo, la siguiente llamada del móvil a `GET /atrio/portal/api/me` **debe devolver**:

```json
{
  "id": 42,
  "name": "Juan Pérez",
  "email": "juan@correo.com",
  "role": "member",
  "membership_status": "approved",
  "church": {
    "id": 10,
    "name": "Parroquia Nuestra Señora del Amparo",
    "has_active_subscription": true
  },
  "requested_church_id": false,
  "requested_church": false
}
```
* `membership_status` vuelve a `"approved"`.
* `church` permanece inalterado con los datos de la iglesia actual.
* `requested_church_id` y `requested_church` son `false` o `null`.

---

## 5. Checklist de Verificación para Claude Code en Odoo

- [ ] Verificar el nombre real del modelo de usuarios/membresía (usualmente `res.users` o `res.partner`).
- [ ] Verificar el nombre del modelo de peticiones pastorales (ej. `atrio.request`, `atrio.pastoral.request`, o `helpdesk.ticket`).
- [ ] Probar cancelación de cambio con `curl`:
  ```bash
  curl -X POST https://<tu-odoo-url>/atrio/portal/api/membership/cancel \
       -H "Authorization: Bearer <TOKEN_DE_PRUEBA>" \
       -H "Content-Type: application/json"
  ```
- [ ] Comprobar que en la base de datos de Odoo el registro del usuario quedó con `requested_church_id = NULL` y `membership_status = 'approved'`.
- [ ] Probar cancelación de una petición en estado borrador/pendiente:
  ```bash
  curl -X POST https://<tu-odoo-url>/atrio/portal/api/requests/<ID>/cancel \
       -H "Authorization: Bearer <TOKEN_DE_PRUEBA>" \
       -H "Content-Type: application/json"
  ```
- [ ] Verificar que si se intenta cancelar una petición ya atendida (`state == 'done'`), Odoo rechace con HTTP 400.

