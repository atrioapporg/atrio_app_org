# Memoria Mem0 en ATRIO

El proyecto ATRIO usa la memoria global Mem0 (servidor MCP `mem0`) con **`project="atrio"`** en TODAS las llamadas (`memory_search`, `memory_add`, `memory_list`).

## Antes de tocar código
- `memory_search(query=<tarea>, project="atrio")` para recuperar arquitectura, convenciones, contratos de la API Odoo 19 y decisiones previas.

## Qué guardar en `atrio` (al cerrar la tarea)
- Cambios de contrato con Odoo 19 (endpoints, campos, estados de donaciones/pedidos/solicitudes) → categoría `backend`.
- Decisiones de UI/UX, navegación y manejo offline → `decision`.
- Soluciones a errores (p. ej. contexto desactivado en modales, permisos de Maps/Android) → `bug_fix`.
- Cambios de versión (`pubspec.yaml`, SDK, paquetes clave) → `config`.

## Límites
- Las reglas de este directorio (i18n obligatorio en `app_es.arb`/`app_en.arb`) siguen siendo la fuente de verdad; la memoria las refuerza, no las sustituye.
- Nunca guardar valores de `.env`, tokens, contraseñas ni claves (solo nombres de variables). `INVENTARIO_APIS_CREDENCIALES_ATRIO.txt` NO debe volcarse a la memoria.
- Memorias de ATRIO no deben contener datos de otros proyectos, ni viceversa.
