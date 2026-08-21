# 📋 Informe Detallado del Proyecto — Pharmacy

> Fecha de generación: 2026-08-21  
> Generado por análisis estático del código fuente en `/home/omardev/Documentos/pharmacy`

---

## 1. Visión General

**Pharmacy** es un sistema integral de gestión de farmacia compuesto por tres módulos principales:

| Componente | Tecnología | Puerto (host) | Directorio |
|---|---|---|---|
| Backend API | Rust (Axum + SeaORM + SQLx) | `8081` | `pharmacy_backend/` |
| Frontend Web/Móvil | React 19 + Vite + TailwindCSS | `8185 → 8085` (nginx) | `pharmacy-frontend/` |
| Base de Datos | PostgreSQL 15+ | `5432` | `pharmacy_bd/` |
| Caché | Redis (opcional) | `6379` | — |
| Observabilidad | Grafana + Promtail | — | `pharmacy_backend/observability/` |

El frontend también soporta empaquetado nativo Android vía **Capacitor**.

---

## 2. Arquitectura

```
┌─────────────────┐    HTTPS/CORS     ┌─────────────────┐     SQLx      ┌──────────────┐
│  React Frontend  │◄────────────────► │  Rust Backend   │◄────────────►│  PostgreSQL  │
│  (Vite/Nginx)    │   cookies HttpOnly│  (Axum :8081)   │   schema:    │   (:5432)    │
│  (:8185→8085)    │   + Bearer (native)│                 │   pharmacy   │              │
└─────────────────┘                    └────────┬────────┘              └──────────────┘
                                                │ redis
                                       ┌────────▼────────┐
                                       │     Redis       │
                                       │   (:6379)       │
                                       └─────────────────┘
```

### 2.1 Capas del Backend

```
main.rs (entry point)
  └─ controller/api_controller.rs  → get_config_router()
       ├─ routes/ (11 grupos de rutas)
       │    ├─ auth_routes      → /v1/api/auth/*
       │    ├─ user_routes      → /v1/api/user/*
       │    ├─ rbac_routes      → /v1/api/role, /permission, /role_permissions, /user_role
       │    ├─ product_routes   → /v1/api/products, /categories, /suppliers, /units
       │    ├─ inventory_routes → /v1/api/inventory_locations, /inventory_movements
       │    ├─ sales_routes     → /v1/api/sales, /sale_items, /sale_payments
       │    ├─ purchase_routes  → /v1/api/purchases, /purchase_items, /purchase_payments
       │    ├─ finance_routes   → /v1/api/cash_journals, /cash_entries, /customer_credit_accounts
       │    ├─ catalog_routes  → /v1/api/payment_methods, /tax_profiles, /discounts
       │    ├─ audit_routes     → /v1/api/audit_log
       │    └─ dashboard_routes → /v1/api/vw_* (vistas materializadas/reportes)
       │
       └─ Middlewares (orden: interno → externo)
            cache → idempotency → auth_jwt → content_type → rate_limit → cors → security_headers
            + DefaultBodyLimit(2MB) + Timeout(30s)
```

### 2.2 Capas del Frontend

```
App.tsx (routing con react-router)
  ├─ PublicLayout  → LandingPage, LoginPage
  └─ AdminLayout (ProtectedRoute)
       ├─ Dashboard, POS, Products, Customers, Suppliers
       ├─ Categories, Sales, Purchases, Discounts
       ├─ PaymentMethods, CashJournal, Inventory
       └─ Admin only: Users, Roles, Permissions, AuditLog
            Config: Units, TaxProfiles, Locations

Gestión de estado: Zustand (authStore, posStore, uiStore)
Datos: TanStack Query (React Query)
HTTP: Axios (axiosInstance con interceptores de refresh y 429)
Formularios: React Hook Form + Zod
Internacionalización: i18next
Alertas: SweetAlert2 (con sanitización DOMPurify)
```

---

## 3. Base de Datos

### 3.1 Esquema

- **Gestor:** PostgreSQL
- **Schema:** `pharmacy` (configurado vía `search_path`)
- **Usuario:** `postgres` (conexión por `host.docker.internal`)

### 3.2 Archivos

| Archivo | Contenido |
|---|---|
| `pharmacy_bd/DDL.sql` | Definición de secuencias (1774 líneas) |
| `pharmacy_bd/schemas.sql` | Definición de tablas |
| `pharmacy_bd/sample_inserts.sql` | Datos de ejemplo |

### 3.3 Entidades Principales (de DDL + schemas)

| Categoría | Tablas |
|---|---|
| **RBAC** | `users`, `roles`, `permissions`, `role_permissions`, `user_role` |
| **Catálogo** | `products`, `product_barcodes`, `product_lots`, `product_prices`, `categories`, `suppliers`, `units`, `brands` |
| **Inventario** | `inventory_locations`, `inventory_movements`, `product_lots` |
| **Ventas** | `sales`, `sale_items`, `sale_payments`, `sale_payment_allocations`, `customers`, `discounts` |
| **Compras** | `purchases`, `purchase_items`, `purchase_payments` |
| **Finanzas** | `cash_journals`, `cash_entries`, `customer_credit_accounts` |
| **Configuración** | `payment_methods`, `tax_profiles` |
| **Auditoría** | `audit_log`, `config_audit` |
| **Vistas** | `vw_sales_with_payments`, `vw_best_sellers_30d`, `vw_cash_journal_balance`, `vw_daily_cash_cut`, `vw_customer_account_summary`, `vw_sale_items_detail`, `vw_inventory_stock`, `vw_customer_invoice_aging`, `vw_sales_daily_summary` |

### 3.4 Pool de Conexiones (SeaORM)

```rust
max_connections(20)
min_connections(5)
connect_timeout(10s)
acquire_timeout(10s)
idle_timeout(300s)
max_lifetime(1800s)
sqlx_logging: off
schema_search_path: "pharmacy"
```

### 3.5 Connection String

```
postgres://postgres:admin@host.docker.internal:5432/postgres?options=--search_path=pharmacy
```

---

## 4. Backend (Rust)

### 4.1 Stack Tecnológico

| Dependencia | Versión | Propósito |
|---|---|---|
| `axum` | 0.8.8 | Framework web async |
| `sea-orm` | 1.1.19 | ORM + SQLx PostgreSQL |
| `tokio` | 1.49.0 | Runtime async |
| `jsonwebtoken` | 10.3.0 | JWT (RS256/HMAC) |
| `argon2` | 0.5.3 | Hashing de contraseñas |
| `validator` | 0.20.0 | Validación de DTOs |
| `redis` | 0.23.3 | Caché de permisos y datos |
| `tower-http` | 0.6 | CORS, timeout, body limit |
| `flexi_logger` | 0.31.8 | Logging a archivo |
| `chrono` / `chrono-tz` | 0.4 / 0.6 | Manejo de fechas y zonas horarias |

### 4.2 Estructura de Código

```
pharmacy_backend/
├── src/
│   ├── main.rs                 → Entry point (init DB, Redis, JWT, server)
│   ├── lib.rs                  → Exporta módulos para tests
│   ├── config/
│   │   ├── config_database/    → Pool de conexiones + AppContext
│   │   ├── config_jwt/         → JWT gen/validate + revocación + DTO
│   │   ├── config_middleware/  → 8 middlewares (auth, cors, cache, etc.)
│   │   ├── config_pass/        → Argon2 password hashing
│   │   └── config_redis/       → Cliente Redis + helpers get/set JSON
│   ├── controller/
│   │   ├── api_controller.rs   → Router central + capas de middleware
│   │   └── routes/             → 11 archivos de rutas por dominio
│   ├── api_module/             → 40+ módulos de dominio (login, user, sales, etc.)
│   │   └── cada módulo tiene: dto/, service/, mod.rs
│   └── api_utils/              → ApiResponse, ApiError, extractors, consts
├── schemas/                    → Workspace crate: entidades SeaORM (Model, ActiveModel)
├── tests/                      → Tests de integración (jwt_test, pagination_test)
├── migration/                  → Migraciones SeaORM
├── collections/root.http       → Colección de endpoints de prueba
├── pem/                        → Claves RSA para JWT (montadas como volumen)
├── observability/              → Grafana + Promtail
├── Cargo.toml                  → Dependencias y workspace
└── Dockerfile                  → Imagen runtime (debian-slim)
```

### 4.3 Autenticación y Seguridad

#### JWT
- **Algoritmos:** RS256 (preferido, con claves PEM) o HMAC (fallback)
- **Access token:** 1 día de expiración, cookie HttpOnly `SameSite=Strict` en path `/v1/api`
- **Refresh token:** 7 días, cookie HttpOnly en path `/v1/api/auth`
- **Revocación:** soporte de JTI (UUID) + lista de revocación en memoria
- **Validación de tipo:** access ≠ refresh (cross-type rejection)

#### Contraseñas
- Argon2 con verificación en `spawn_blocking` (no bloquea el runtime async)

#### Cookies
- `HttpOnly; SameSite=Strict; Secure` (configurable vía `COOKIE_SECURE`)
- Clientes nativos (Capacitor) reciben tokens en el body + Bearer header

#### Middlewares de Seguridad
1. **security_headers** — Headers HTTP de seguridad
2. **cors** — Validación por `CORS_ALLOWED_ORIGINS` con credenciales
3. **rate_limit** — Limitación de tasa (`api-rate-limiter`)
4. **auth_jwt** — Validación de token (header + cookie)
5. **content_type** — Validación de Content-Type
6. **idempotency** — Soporte de idempotencia
7. **cache** — Caché de respuestas
8. **body_limit + timeout** — 2MB max body, 30s timeout

### 4.4 Formato de Respuesta API

```json
{
  "data": <T>,
  "total": 1,
  "message": "Login successful",
  "status": "success",
  "codeError": 200,
  "timestamp": "2026-08-21T12:00:00Z"
}
```

Errores de validación:
```json
{
  "data": [{ "field": "username", "reason": "...", "code": "..." }],
  "total": 1,
  "message": "Validation failed",
  "status": "error",
  "codeError": 400,
  "timestamp": "..."
}
```

### 4.5 Endpoints (Resumen)

| Grupo | Base path | Métodos |
|---|---|---|
| Auth | `/v1/api/auth/` | login, profile, refresh, logout |
| Users | `/v1/api/user` | PUT, GET (id, all, username), PATCH, DELETE, status |
| Roles | `/v1/api/role` | PUT, GET (id, name, all), PATCH, DELETE |
| Permissions | `/v1/api/permission` | PUT, GET (id, name, all), PATCH, DELETE |
| Role-Permissions | `/v1/api/role_permissions` | PUT, GET, PATCH, DELETE |
| User-Role | `/v1/api/user_role` | PUT, GET, PATCH, DELETE |
| Products | `/v1/api/products` | CRUD + barcodes, lots, prices |
| Sales | `/v1/api/sales` | CRUD + items, payments, allocations |
| Purchases | `/v1/api/purchases` | CRUD + items, payments |
| Inventory | `/v1/api/inventory_*` | locations, movements |
| Finance | `/v1/api/cash_*` | journals, entries, credit accounts |
| Catalog | `/v1/api/payment_methods`, `/tax_profiles`, `/discounts`, `/units` | CRUD |
| Audit | `/v1/api/audit_log` | GET |
| Dashboard | `/v1/api/vw_*` | 9 vistas de reportes |

---

## 5. Frontend (React)

### 5.1 Stack Tecnológico

| Dependencia | Versión | Propósito |
|---|---|---|
| `react` / `react-dom` | 19.0.0 | UI |
| `vite` | 6.1.0 | Bundler + dev server |
| `tailwindcss` | 4.0.6 | CSS utility framework |
| `react-router` | 7.1.5 | Routing |
| `@tanstack/react-query` | 5.96.2 | Server state / data fetching |
| `@tanstack/react-table` | 8.21.3 | Tablas de datos |
| `zustand` | 5.0.12 | Estado global |
| `react-hook-form` | 7.72.1 | Formularios |
| `zod` | 4.3.6 | Validación de esquemas |
| `axios` | 1.13.6 | Cliente HTTP |
| `i18next` | 26.0.3 | Internacionalización |
| `recharts` | 3.8.1 | Gráficos del dashboard |
| `sweetalert2` | 11.26.21 | Alertas y confirmaciones |
| `@sentry/react` | 10.48.0 | Monitoreo de errores |
| `@capacitor/core` | 8.3.1 | App móvil Android |

### 5.2 Estructura

```
pharmacy-frontend/src/
├── api/axiosInstance.ts       → Cliente HTTP con interceptores (refresh, 429, Sentry)
├── services/                  → 15 archivos de API por dominio (productApi, saleApi, etc.)
├── store/                     → Zustand: authStore, posStore, uiStore
├── hooks/                     → Custom hooks (useInactivityLogout, etc.)
├── components/                → Componentes reutilizables + shared
├── layouts/                   → PublicLayout, AdminLayout
├── pages/                     → 20+ páginas (lazy-loaded)
├── models/                    → Tipos TypeScript
├── config/sentry.ts           → Configuración Sentry
├── utils/                     → constants, alerts, apiErrorMapper, dateUtils, cn
└── i18n/                      → Traducciones
```

### 5.3 Manejo de Errores (Frontend)

- **apiErrorMapper.ts:** Mapea códigos HTTP → claves i18n (`apiErrors.badRequest`, etc.)
- **alerts.ts:** SweetAlert2 con sanitización DOMPurify, soporte dark/light theme
- **axiosInstance.ts:** Interceptores para 401 (refresh + retry), 429 (notificación UI), 5xx (Sentry)
- **react-error-boundary:** Captura de errores de render
- **Sentry:** Reporte automático de errores 5xx

### 5.4 Seguridad Frontend

- Inactividad: logout a los 15 min (advertencia a los 13 min)
- Sanitización HTML con DOMPurify en alertas
- Detección de HTTP en producción (warning en consola)
- CSP estricto en nginx.conf

---

## 6. Docker y Despliegue

### 6.1 docker-compose.yml (raíz)

```yaml
services:
  backend:   # Puerto 8081:8081, depende de host.docker.internal:5432
  frontend:  # Puerto 8185:8085, depende de backend, build args VITE_*
```

### 6.2 Backend Dockerfile

- Base: `debian:stable-slim`
- Copia binario precompilado (`target/release/pharmacy_backend`)
- Instala `ca-certificates`
- Expone puerto 8081
- Volúmenes: `pem/` (solo lectura) y `logs/`

> ⚠️ **Nota:** No usa multi-stage build. El binario debe compilarse fuera del Docker.

### 6.3 Frontend Dockerfile

- **Stage 1 (builder):** `node:20-alpine`, `npm install --frozen-lockfile`, `npm run build`
- **Stage 2 (runtime):** `nginx:alpine`, copia `dist/` y `nginx.conf`
- Expone puerto 8085
- Build args: `VITE_API_BASE_URL`, `VITE_APP_TIMEZONE`

### 6.4 Variables de Entorno

#### Raíz (.env)
```
API_JWT_SECRET=[redacted]
API_JWT_SECRET_REFRESH=[redacted]
PASSWORD_SALT=[redacted]
```

#### Backend (docker-compose env)
```
DATABASE_URL, CORS_ALLOWED_ORIGINS, PORT, SERVER_ADDR
JWT_EXPIRATION, LOG_LEVEL, RUST_LOG, PASSWORD_SALT
API_JWT_PRIVATE_PEM_PATH, API_JWT_PUBLIC_PEM_PATH
API_JWT_SECRET, API_JWT_SECRET_REFRESH, APP_TIMEZONE
```

#### Frontend (.env)
```
VITE_APP_API_URL, VITE_APP_API_URL_ANDROID
VITE_APP_TIMEZONE, VITE_APP_ENV, VITE_APP_NAME, VITE_APP_VERSION
```

---

## 7. Observabilidad

| Componente | Archivo | Propósito |
|---|---|---|
| Logs | `pharmacy_backend/logs/app.log` | flexi_logger, formato custom |
| Grafana | `pharmacy_backend/observability/grafana/` | Dashboards |
| Promtail | `pharmacy_backend/observability/promtail-config.yml` | Shipper de logs |
| Sentry | Frontend (`@sentry/react`) | Captura de errores en producción |

---

## 8. CI/CD

- **Jenkinsfile** en ambos backend y frontend
- Configuración en `.github/` (workflows)
- Scripts de soporte: `check_port.sh`, `validate_env.sh`

---

## 9. Puertos y Conexiones — Resumen

| Servicio | Puerto interno | Puerto host (docker) | Protocolo |
|---|---|---|---|
| Backend API | 8081 | 8081 | HTTP |
| Frontend (nginx) | 8085 | 8185 | HTTP |
| PostgreSQL | 5432 | 5432 (host) | TCP |
| Redis | 6379 | 6379 (host) | TCP |
| Vite dev server | 5173 | 5173 | HTTP (dev) |

### Flujos de conexión:
1. **Browser → Frontend (nginx:8185)** → sirve SPA React
2. **Frontend → Backend (8081)** → `/v1/api/*` con cookies HttpOnly
3. **Backend → PostgreSQL (5432)** → vía `host.docker.internal` (schema `pharmacy`)
4. **Backend → Redis (6379)** → caché de permisos y respuestas
5. **Android nativo → Backend (8081)** → Bearer token + `X-Client-Platform: native`

---

## 10. Tests Existentes

### Backend (Rust)
- `tests/jwt_test.rs` — 8 tests de integración: generación, validación, cross-type, revocación, claims
- `tests/pagination_test.rs` — 10 tests de deserialización de `PaginationParams`

### Frontend (Vitest)
- Configurado en `vite.config.ts` con `jsdom`
- Setup: `src/test/setup.ts`
- Pattern: `src/test/**/*.{test,spec}.{ts,tsx}`
- Coverage: `@vitest/coverage-v8`

---

## 11. Graphify

El proyecto ya tiene un grafo de conocimiento generado en `pharmacy_backend/graphify-out/`:
- **655 nodos, 434 aristas, 233 comunidades**
- Extracción 100% EXTRACTED
- Reporte: `GRAPH_REPORT.md`
- Outputs: `graph.html` (interactivo), `graph.json` (GraphRAG)

---

*Fin del informe.*
