# 🚀 Plan de Mejoras — Pharmacy

> Fecha: 2026-08-21  
> Estado: Activo  
> Alcance: Seguridad, Performance, Diseño, Arquitectura, Documentación, Modelo, Robustez, Escalabilidad

---

## Resumen Ejecutivo

Este documento detalla un plan de mejoras priorizado, robusto y replicable para el proyecto Pharmacy. Cada mejora se clasifica por categoría, prioridad (🔴 Crítica, 🟠 Alta, 🟡 Media, 🟢 Baja), esfuerzo y estado.

---

## 1. Seguridad (SEC)

### SEC-1 🔴 .env con secretos commiteado
- **Problema:** El archivo `.env` existe en el repositorio raíz con `API_JWT_SECRET`, `API_JWT_SECRET_REFRESH`, `PASSWORD_SALT`. Aunque el contenido está `[redacted]` en el ejemplo, el `.env` real puede contener secretos en claro.
- **Solución:** Agregar `.env` al `.gitignore` global, verificar que no esté trackeado en git, y usar `git rm --cached .env` si lo está.
- **Estado:** ⏳ Pendiente

### SEC-2 🔴 .gitignore incompleto
- **Problema:** El `.gitignore` raíz solo ignora archivos de IDE. No ignora `.env`, `node_modules`, `target/`, `dist/`, etc.
- **Solución:** Crear `.gitignore` raíz completo con patrones para todos los subproyectos.
- **Estado:** ⏳ Pendiente

### SEC-3 🟠 Contraseña hardcodeada en colección HTTP
- **Problema:** `collections/root.http` contiene credenciales en claro (`admin/admin12344`, `noemi0907/noemi0907`) y un JWT token de larga duración commiteado.
- **Solución:** Reemplazar credenciales por variables de entorno del cliente HTTP o placeholders `{{username}}`/`{{password}}`.
- **Estado:** ⏳ Pendiente

### SEC-4 🟠 Rate limiter sin configuración visible de Redis
- **Problema:** El `api-rate-limiter` crate está incluido pero no se observa configuración de almacenamiento distribuido. Si se usa en memoria, no funciona tras múltiples instancias.
- **Solución:** Verificar implementación del middleware `rate_limit.rs` y documentar la estrategia.
- **Estado:** ⏳ Pendiente

### SEC-5 🟠 Token revocation en memoria (no persistente)
- **Problema:** `token_revocation.rs` usa memoria (`parking_lot` o similar). Al reiniciar el backend, los tokens revocados vuelven a ser válidos.
- **Solución:** Migrar la lista de revocación a Redis con TTL = expiración del token.
- **Estado:** ⏳ Pendiente

### SEC-6 🟡 Password en body de ejemplo de colección HTTP
- **Problema:** El `root.http` envía `passwordHash` en el body de creación/actualización de usuario, lo que sugiere que el cliente podría enviar el hash en vez de la contraseña plana.
- **Solución:** Renombrar el campo del DTO a `password` y hacer el hash en el backend.
- **Estado:** ⏳ Pendiente

### SEC-7 🟡 HSTS descomentado en nginx
- **Problema:** La línea `Strict-Transport-Security` está comentada en `nginx.conf`.
- **Solución:** Activar HSTS cuando se tenga TLS configurado en producción.
- **Estado:** ⏳ Pendiente

### SEC-8 🟢 Docker backend sin usuario no-root
- **Problema:** El contenedor del backend corre como root.
- **Solución:** Crear usuario `appuser` en el Dockerfile y usar `USER appuser`.
- **Estado:** ⏳ Pendiente

---

## 2. Performance (PERF)

### PERF-1 🟠 Pool de DB con max_connections fijo (20)
- **Problema:** El pool está hardcodeado a 20 conexiones. No escala según la carga.
- **Solución:** Hacer configurable via `DATABASE_MAX_CONNECTIONS` env var.
- **Estado:** ⏳ Pendiente

### PERF-2 🟠 sqlx_logging desactivado
- **Problema:** Los logs de SQL están en `Off`. Útil para producción, pero dificulta debugging de queries lentas.
- **Solución:** Activar en nivel `Debug` cuando `LOG_LEVEL=debug`, mantener off en `info`.
- **Estado:** ⏳ Pendiente

### PERF-3 🟡 Falta índices documentados
- **Problema:** No se verifica si las columnas usadas en `WHERE`/`JOIN` frecuentes tienen índices (username, email, status, foreign keys).
- **Solución:** Auditar el DDL y agregar `CREATE INDEX` donde falten.
- **Estado:** ⏳ Pendiente

### PERF-4 🟡 Frontend sin code-splitting por rutas admin
- **Problema:** Las páginas admin se cargan lazy, pero todas comparten el mismo chunk boundary. Los usuarios no-admin descargan código admin innecesariamente.
- **Solución:** Ya está con `lazy()` — verificar que los chunks se separen correctamente.
- **Estado:** ✅ Parcialmente cubierto

### PERF-5 🟢 Falta compresión gzip/brotli en backend
- **Problema:** El backend Axum no tiene middleware de compresión de respuestas.
- **Solución:** Agregar `tower_http::compression::CompressionLayer`.
- **Estado:** ⏳ Pendiente

---

## 3. Diseño y UX (DESIGN)

### DESIGN-1 🟡 Mensajes de error genéricos en el backend
- **Problema:** `ApiError::Unauthorized` y `ApiError::NotFound` devuelven mensajes genéricos ("Unauthorized", "Not found") sin distinguir causa de negocio vs sistema.
- **Solución:** Clasificar errores en `BUSINESS`, `SYSTEM`, `VALIDATION`, `AUTH` y devolver mensaje descriptivo.
- **Estado:** ⏳ Pendiente

### DESIGN-2 🟡 Sin categorización de errores para el usuario
- **Problema:** El frontend recibe errores pero no puede distinguir si son de negocio (ej: "stock insuficiente"), validación o sistema.
- **Solución:** Agregar campo `errorType` en el `ApiResponse` de error.
- **Estado:** ⏳ Pendiente

### DESIGN-3 🟢 Mejorar páginas de error 404/500
- **Problema:** Existe `NotFoundPage` pero no se observa página de error 500 o de mantenimiento.
- **Solución:** Crear `ServerErrorPage` y `MaintenancePage`.
- **Estado:** ⏳ Pendiente

---

## 4. Arquitectura (ARCH)

### ARCH-1 🟠 Sin healthcheck endpoint
- **Problema:** No hay endpoint `/health` o `/ready` para Docker, load balancers o Kubernetes.
- **Solución:** Agregar `GET /v1/api/health` que verifique DB + Redis.
- **Estado:** ⏳ Pendiente

### ARCH-2 🟠 Docker backend sin multi-stage build
- **Problema:** El Dockerfile del backend copia un binario precompilado. No es reproducible ni CI-friendly.
- **Solución:** Agregar stage de compilación con `rust:latest` → stage runtime con `debian-slim`.
- **Estado:** ⏳ Pendiente

### ARCH-3 🟠 docker-compose sin servicio de PostgreSQL
- **Problema:** El `docker-compose.yml` no incluye PostgreSQL ni Redis como servicios. Depende de que estén corriendo en el host.
- **Solución:** Agregar servicios `postgres` y `redis` al compose con volúmenes.
- **Estado:** ⏳ Pendiente

### ARCH-4 🟡 Sin manejo de migraciones automatizado
- **Problema:** Existe `migration/` pero no se integra en el arranque del backend ni en el CI.
- **Solución:** Ejecutar migraciones en el entrypoint del contenedor o en CI.
- **Estado:** ⏳ Pendiente

### ARCH-5 🟡 Configuración hardcodeada (zona horaria, empresa)
- **Problema:** `company: "Pharmacy"` está hardcodeado en `validate_jwt.rs`. La zona horaria `America/Mexico_City` está en多处.
- **Solución:** Centralizar configuración en un struct `AppConfig` cargado desde env.
- **Estado:** ⏳ Pendiente

---

## 5. Documentación (DOC)

### DOC-1 🟠 README del frontend vacío
- **Problema:** `pharmacy-frontend/README.md` no se ha revisado; puede estar incompleto.
- **Solución:** Documentar setup, scripts, arquitectura y convenciones.
- **Estado:** ⏳ Pendiente

### DOC-2 🟡 Sin SECURITY.md
- **Problema:** El README del backend lo recomienda pero no existe.
- **Solución:** Crear `SECURITY.md` con política de reporte de vulnerabilidades, rotación de claves.
- **Estado:** ⏳ Pendiente

### DOC-3 🟡 Sin CONTRIBUTING.md
- **Problema:** No hay guía de contribución.
- **Solución:** Crear `CONTRIBUTING.md` con convenciones de código, branching, PRs.
- **Estado:** ⏳ Pendiente

### DOC-4 🟢 Sin diagrama de arquitectura visual
- **Problema:** No hay diagrama de componentes/deployment.
- **Solución:** Crear diagrama en Mermaid o similar.
- **Estado:** ⏳ Pendiente

---

## 6. Modelo de Datos (MODEL)

### MODEL-1 🟡 Sequences con INCREMENT BY 50
- **Problema:** `sale_seq` y `saledetal_seq` usan `INCREMENT BY 50`, lo que genera huecos grandes. Puede ser intencional para performance, pero no está documentado.
- **Solución:** Documentar la decisión o cambiar a `INCREMENT BY 1`.
- **Estado:** ⏳ Pendiente

### MODEL-2 🟡 89 nodos aislados en graphify
- **Problema:** El reporte de graphify identifica 89 nodos aislados con ≤1 conexión, sugiriendo relaciones faltantes entre entidades.
- **Solución:** Revisar relaciones no documentadas y agregar edges en el grafo.
- **Estado:** ⏳ Pendiente

### MODEL-3 🟢 Soft delete inconsistente
- **Problema:** Algunas tablas tienen `deleted_at` (users), pero no se verifica que todas las tablas críticas lo tengan.
- **Solución:** Auditar tablas de transacciones (sales, purchases) para soft delete consistente.
- **Estado:** ⏳ Pendiente

---

## 7. Robustez y Escalabilidad (ROBUST)

### ROBUST-1 🔴 `unwrap()`/`expect()` en código de producción
- **Problema:** El README del backend identifica usos de `unwrap()`/`expect()` que pueden causar panics.
- **Solución:** Reemplazar por manejo de errores con `?` y `map_err`.
- **Estado:** ⏳ Pendiente

### ROBUST-2 🟠 Sin manejo de fallos de Redis
- **Problema:** Si Redis cae, el backend continúa pero los logs de permisos pueden quedar inconsistentes. El login hace fallback a DB pero no hay circuit breaker.
- **Solución:** Implementar circuit breaker o degradación explícita.
- **Estado:** ⏳ Pendiente

### ROBUST-3 🟠 Falta tests de endpoints críticos
- **Problema:** Solo existen tests de JWT y paginación. No hay tests de login, CRUD de productos, ventas, etc.
- **Solución:** Agregar tests de integración para endpoints críticos.
- **Estado:** ⏳ Pendiente

### ROBUST-4 🟡 Sin retry/backoff en conexión DB
- **Problema:** Si la DB no está disponible al arrancar, el backend hace `exit(1)` inmediatamente.
- **Solución:** Implementar retry con backoff exponencial en `get_db_context()`.
- **Estado:** ⏳ Pendiente

### ROBUST-5 🟢 Sin graceful shutdown de Redis
- **Problema:** No se cierra la conexión Redis al apagar el servidor.
- **Solución:** Cerrar pool de Redis en el shutdown signal.
- **Estado:** ⏳ Pendiente

---

## 8. Tests (TEST)

### TEST-1 🟠 Sin tests de frontend
- **Problema:** Vitest está configurado pero no se observa directorio `src/test/` con tests.
- **Solución:** Crear tests unitarios para stores, utils y componentes clave.
- **Estado:** ⏳ Pendiente

### TEST-2 🟠 Sin tests de API del backend
- **Problema:** No hay tests que validen respuestas HTTP de endpoints (status codes, body).
- **Solución:** Agregar tests con `axum::test` o `tower::ServiceExt`.
- **Estado:** ⏳ Pendiente

### TEST-3 🟡 Sin tests E2E
- **Problema:** No hay tests end-to-end (Playwright, Cypress).
- **Solución:** Agregar tests E2E para flujos críticos (login → POS → venta).
- **Estado:** ⏳ Pendiente

---

## Priorización de Ejecución

### Fase 1 — Crítico (inmediato)
1. SEC-1: `.env` en `.gitignore` + remover de tracking
2. SEC-2: `.gitignore` completo
3. ROBUST-1: Eliminar `unwrap()`/`expect()` críticos
4. ARCH-1: Healthcheck endpoint

### Fase 2 — Alta prioridad
5. SEC-3: Limpiar credenciales de `root.http`
6. ARCH-2: Multi-stage build backend
7. ARCH-3: PostgreSQL + Redis en docker-compose
8. PERF-1: Pool de DB configurable
9. ROBUST-3: Tests de endpoints críticos
10. TEST-1: Tests de frontend

### Fase 3 — Media prioridad
11. SEC-5: Revocación de tokens en Redis
12. DESIGN-1/2: Clasificación de errores
13. DOC-1/2/3: Documentación
14. ROBUST-4: Retry/backoff DB
15. PERF-3: Auditoría de índices

### Fase 4 — Baja prioridad
16. SEC-7/8, PERF-5, DESIGN-3, DOC-4, MODEL-1/2/3, ROBUST-5, TEST-3

---

*Fin del plan de mejoras.*
