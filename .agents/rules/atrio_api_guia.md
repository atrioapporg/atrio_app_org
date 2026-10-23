# Memoria de Integración de API Odoo 19 (Atrio)

Este proyecto está integrado oficialmente con la **API de Odoo 19 (Módulo v19.0.4)**.
La especificación canónica y completa de endpoints, modelos, autenticación, roles y reglas de negocio se encuentra en el archivo de memoria del proyecto:
- [ATRIO_API_GUIA.md](file:///c:/APPS/ATRIO/ATRIO_API_GUIA.md)

## Principios y Reglas Críticas del Sistema

1. **URL Base y Autenticación**:
   - URL Base: `https://atrioapp.odoo19rd.com/atrio/portal/api`
   - Encabezado: `Authorization: Bearer <token>` obtenido en `POST /auth/login`.
   - Duración: Access token de 30 min y Refresh token de 90 días (rotación dual obligatoria en `/auth/refresh`).
   - Cierre de sesión (`POST /auth/logout`): revoca únicamente el token de ese dispositivo.

2. **Roles y Permisos Granulares**:
   - **Sin sesión (Invitado)**: Solo lectura de iglesias, planes, catálogo de tienda, donaciones a Atrio y registro.
   - **`user`**: Registrado, aún sin congregación aprobada (`manage_profile`, `donate`).
   - **`member`**: Miembro de una iglesia con congregación asignada (`hasChurchAssigned == true`).
   - **`church_admin`**: Administrador congregacional local. Gestiona publicaciones, eventos, anuncios, solicitudes ministeriales, grupos y avisos de campanita.
   - **`platform_admin`**: Super Admin de Atrio en **modo estricto de solo lectura** (`read_only == true`). Lee iglesias con `GET /platform/churches` y envía `X-Atrio-Church: <id>`. Bloqueado para cualquier mutación (`403 read_only`).

3. **Manejo de Errores Tipados**:
   - Toda respuesta de error es JSON con texto `error` y código estable `code`.
   - `401 unauthorized` / `invalid_token` / `invalid_refresh_token`: Renovación transparente o regreso a login.
   - `403 read_only`: Super Admin en modo solo lectura.
   - `403 membership_pending`: Membresía en proceso de validación.
   - `404 content_unavailable`: Contenido moderado por Atrio (quitar de caché y mostrar mensaje oficial).

4. **Persistencia y Navegación**:
   - Un usuario con iglesia vinculada en Odoo (`hasChurchAssigned`, `role == member` o `role == churchAdmin`) **nunca** debe ser enviado a la pantalla de selección de iglesias de forma redundante tras iniciar sesión; debe ingresar directamente a `InicioAtrioScreen`.
   - La selección de iglesias ("Queremos conocerte") es exclusiva para usuarios que aún no tienen iglesia vinculada.
