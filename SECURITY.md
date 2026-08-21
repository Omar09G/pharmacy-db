# 🔐 Política de Seguridad — Pharmacy

> Última actualización: 2026-08-21
> Aplica a: `pharmacy_backend` (API Rust), `pharmacy-frontend` (React), `pharmacy_bd` (PostgreSQL)

---

## 1. Versiones soportadas

| Componente | Rama | Soporte |
|---|---|---|
| `pharmacy_backend` | `main` | ✅ Parches de seguridad |
| `pharmacy-frontend` | `main` | ✅ Parches de seguridad |
| Esquema de BD (`pharmacy_bd`) | `main` | ✅ Migraciones aditivas |

Solo la última versión publicada recibe parches. Mantén tus despliegues al día.

## 2. Cómo reportar una vulnerabilidad

1. **NO abras un issue público** para vulnerabilidades.
2. Escribe a **security@pharmacy.local** (reemplazar por el contacto real del equipo).
3. Incluye: descripción, pasos para reproducir, impacto estimado, y evidencia (logs, PoC).
4. Compromisos del equipo:
   - Acuse de recibo en **≤ 48 h**.
   - Evaluación y plan de remediación en **≤ 7 días**.
   - Crédito al reportador en el changelog (si lo desea).

## 3. Gestión de secretos

### Reglas
- Los secretos **nunca** se commitean: `.env`, `*.pem`, `*.key` están en `.gitignore`.
- Usa `.env.example` como plantilla documental (sin valores reales).
- En producción, los secretos se inyectan vía variables de entorno del orquestador
  (Docker secrets, Kubernetes Secrets, o gestor de secretos).

### Secretos del sistema

| Secreto | Uso | Rotación recomendada |
|---|---|---|
| `API_JWT_SECRET` / `API_JWT_SECRET_REFRESH` | Firma HMAC (fallback) | Cada 90 días o ante sospecha |
| Claves PEM RSA (`jwt_private.pem` / `jwt_public.pem`) | Firma RS256 preferida | Cada 12 meses |
| `PASSWORD_SALT` | Derivación de contraseñas | No rotar sin plan de re-hash |
| Credenciales PostgreSQL | Acceso a datos | Cada 90 días |

### Procedimiento de rotación JWT
1. Publicar nueva clave pública junto a la vigente (ventana de doble lectura).
2. Cambiar la clave de firma; los tokens nuevos se emiten con la nueva clave.
3. Esperar a que expiren los tokens antiguos (access ≤ 24 h, refresh ≤ 7 días).
4. Revocar la clave antigua.

### Nota sobre historial de Git
El archivo `.env` estuvo trackeado históricamente (`git rm --cached .env` aplicado en
2026-08-21). **Rota todos los secretos que hayan existido en ese archivo**, ya que
permanecen en el historial de Git. Para purgarlos del historial usa
`git filter-repo` o BFG Repo-Cleaner en coordinación con todo el equipo.

## 4. Controles implementados

### Backend (Rust/Axum)
- Autenticación JWT RS256/HMAC con cookies HttpOnly `SameSite=Strict` + Bearer para clientes nativos.
- Revocación de tokens por JTI persistida en Redis con TTL.
- Argon2id para hashing de contraseñas (verificación fuera del runtime async).
- Middlewares: security headers, CORS con allow-list, rate limiting distribuido
  (Redis) con fallback en memoria, límite de body (2 MB), timeout (30 s),
  validación de Content-Type e idempotencia.
- Healthchecks `/v1/api/health` (liveness) y `/v1/api/health/ready` (readiness, 503 si DB caída).
- Contenedor corre como usuario no-root (`appuser`, UID 10001).

### Frontend (React)
- CSP estricta en nginx, DOMPurify en alertas, logout por inactividad (15 min).
- Manejo centralizado de errores con clasificación (`errorType`: business/validation/auth/system).

### Base de datos
- Esquema dedicado `pharmacy`; mínimo privilegio recomendado para el usuario de la app.

## 5. Reporte de estado

Los operadores deben monitorear:
- `GET /v1/api/health/ready` → `503` indica dependencia crítica caída (no rutear tráfico).
- Logs de `redis circuit breaker OPEN` → Redis degradado (el sistema continúa sin caché).

---
*Reporta vulnerabilidades responsablemente. Gracias por ayudar a mantener Pharmacy seguro.*
