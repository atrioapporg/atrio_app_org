# Reporte Técnico: Corrección de Payload en Códigos QR y Enlaces de Congregaciones

**Para:** Equipo de Desarrollo Backend (Odoo 19 - ATRIO)  
**De:** Equipo de Desarrollo Móvil Flutter (ATRIO)  
**Fecha:** 12 de noviembre de 2026  
**Prioridad:** Alta (Afecta escaneo con cámara nativa del SO y material impreso)  
**Módulo / Modelo:** `atrio.church` / API Portal REST

---

## 1. Resumen Ejecutivo
Durante las pruebas de integración móvil (iOS y Android) para el flujo de vinculación eclesial mediante códigos QR, se detectó que el endpoint encargado de suministrar el código QR oficial de las congregaciones está serializando y codificando URLs que terminan en `/c/False`.

Esto ocasiona que:
1. Al escanear el QR desde la **cámara nativa del iPhone o Android** (con la app cerrada o no instalada), el navegador web abra `http://atrioapp.odoo19rd.com/c/False`, respondiendo un error **`404 Página no encontrada`**.
2. Al descargar o imprimir afiches desde el portal web, el material físico contenga un código QR no operativo.

---

## 2. Evidencia Técnica del Endpoint

### Petición HTTP:
```http
GET /atrio/portal/api/church/qr.png?download=1 HTTP/1.1
Host: atrioapp.odoo19rd.com
Authorization: Bearer <token_pastor_o_admin>
Accept: image/png, application/json
```

### Respuesta actual de Odoo:
- **Header HTTP devuelto:**
  ```http
  X-Atrio-Join-Url: http://atrioapp.odoo19rd.com/c/False
  ```
- **Cuerpo binario (PNG):**
  La imagen generada codifica internamente la cadena de texto:
  `http://atrioapp.odoo19rd.com/c/False`

---

## 3. Causa Raíz en Backend (Python / Odoo)

En el modelo `atrio.church` (comprobado específicamente en la congregación **ID 22**: *"Parroquia Nuestra Señora del Amparo"*, cuyo código público es **`PARROQ-1`**):

1. El campo `join_token` no está inicializado o contiene `False` (el valor booleano por defecto en Odoo/Python para campos relacionales o `char` vacíos).
2. En el controlador que genera el encabezado y renderiza el código QR, se realiza una interpolación de cadenas directa:
   ```python
   # Lógica actual aproximada:
   join_url = f"{base_url}/c/{church.join_token}"
   # Al ser church.join_token == False, resulta en:
   # "http://atrioapp.odoo19rd.com/c/False"
   ```

---

## 4. Soluciones Recomendadas en Odoo

### A. Fallback en el Controlador del QR (`/church/qr.png`)
Garantizar que si `join_token` es `False`, `None` o una cadena vacía, se utilice el campo `code` público de la congregación (o su ID):

```python
# Corrección sugerida en el controlador:
token_identificador = church.join_token or church.code or f"church-{church.id}"
join_url = f"{base_url}/c/{token_identificador}"

# Asignar cabecera y generar QR con join_url validado:
headers = [('X-Atrio-Join-Url', join_url)]
```

### B. Inicialización y Migración del campo `join_token` en `atrio.church`
Si la arquitectura requiere que toda congregación posea un UUID v4 único e inmutable en `join_token`:
1. Configurar un valor por defecto en la definición del campo:
   ```python
   import uuid

   class AtrioChurch(models.Model):
       _name = 'atrio.church'

       join_token = fields.Char(
           string='Token de Vinculación QR',
           default=lambda self: str(uuid.uuid4()),
           copy=False,
           index=True
       )
   ```
2. Ejecutar un script de migración / actualización (`post-init` o vía shell) para poblar los registros existentes donde `join_token IS NULL OR join_token = 'False'`.

### C. Resolución Flexible en el Endpoint de Consulta `/churches/join/{token}`
Actualmente, el endpoint público:
`GET /atrio/portal/api/churches/join/{token}`

Responde `404 church_not_found` cuando se le envía el `code` de la iglesia (ej: `PARROQ-1`). Sería ideal que este endpoint resuelva tanto por `join_token` (UUID) como por `code` (ej: `PARROQ-1`, `ATRIO-DEMO`):

```python
@http.route('/atrio/portal/api/churches/join/<string:token>', type='http', auth='public', methods=['GET'], csrf=False)
def get_church_by_join_token(self, token, **kwargs):
    church = request.env['atrio.church'].sudo().search([
        '|',
        ('join_token', '=', token),
        ('code', '=ilike', token)
    ], limit=1)

    if not church:
        return self._json_response({'error': 'La iglesia no está disponible.', 'code': 'church_not_found'}, status=404)

    return self._json_response({
        'church': {
            'id': church.id,
            'name': church.public_name or church.name,
            'logo_url': f'/atrio/portal/api/image/atrio.church/{church.id}/logo',
        },
        'can_join': True,
        'join_url': f"{base_url}/c/{church.join_token or church.code}"
    })
```

---

## 5. Medidas de Contingencia Aplicadas en la App Móvil (Flutter)
Para no bloquear las pruebas ni el uso en producción, en la aplicación móvil se implementó:
- Detección en cliente de URLs con terminación `/False` para evitar renderizarlas.
- Consulta dinámica al directorio público de Odoo (`GET /atrio/portal/api/churches`) para mapear el ID de iglesia a su código oficial (`PARROQ-1`).
- Generación vectorial en el dispositivo (`qr_flutter`) para mostrar siempre un QR limpio y escaneable.

Quedamos a su disposición para validar las pruebas una vez desplegado el ajuste en el backend.

