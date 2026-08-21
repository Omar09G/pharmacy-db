# 🤝 Guía de Contribución — Pharmacy

> Gracias por contribuir. Esta guía define las convenciones para que el proyecto
> se mantenga robusto, escalable y fácil de mantener.

---

## 1. Requisitos previos

| Herramienta | Versión mínima |
|---|---|
| Rust (stable) | 1.85+ (edition 2024) |
| Node.js | 20 LTS |
| Docker + Compose v2 | latest stable |
| PostgreSQL | 15+ (o usar `docker compose --profile db`) |

## 2. Setup inicial

```bash
# 1) Clonar y configurar variables
cp .env.example .env          # completar valores locales

# 2) Base de datos (opción A: servicios locales en Docker)
docker compose --profile db up postgres redis

# 3) Backend
cd pharmacy_backend
cargo run                     # arranca en :8081

# 4) Frontend
cd pharmacy-frontend
npm ci
npm run dev                   # Vite dev server
```

## 3. Ramas y commits

- **Ramas**: `main` (protegida), ramas de trabajo:
  - `feature/<descripcion>` — nuevas funcionalidades
  - `fix/<descripcion>` — corrección de bugs
  - `chore/<descripcion>` — mantenimiento/CI/docs
- **Commits**: [Conventional Commits](https://www.conventionalcommits.org/es/)
  - `feat: agregar filtro por lote en POS`
  - `fix: manejar DB caída con retry exponencial`
  - `docs: actualizar SECURITY.md`
  - `refactor:`, `test:`, `perf:`, `chore:`

## 4. Estilo de código

### Backend (Rust)
- `cargo fmt` obligatorio antes del commit.
- `cargo clippy -- -D warnings` sin advertencias.
- **Prohibido** `unwrap()`/`expect()` en código de producción (rutas de request);
  usa `?`, `map_err`, o recuperación explícita. En código de arranque, loguea y falla rápido.
- DTOs validados con `validator`; errores clasificados con `ApiError` + `ErrorType`.

### Frontend (TypeScript)
- Linter/formatter del repo (`npm run lint`).
- Componentes funcionales; estado de servidor con TanStack Query; estado global mínimo en Zustand.
- Validación de formularios con Zod; textos siempre vía i18next.

## 5. Tests

Toda PR que toque lógica debe incluir pruebas:

```bash
# Backend
cargo test                    # unitarios + integración (no requiere DB)

# Frontend
npm test                      # Vitest
```

- Endpoints nuevos → agrega casos en `pharmacy_backend/tests/api_test.rs`.
- Reglas de negocio críticas (ventas, inventario, crédito) requieren cobertura.

## 6. Pull Requests

Checklist antes de abrir la PR:

- [ ] `cargo fmt` / `clippy` / `cargo test` en verde.
- [ ] `npm run lint` / `npm test` en verde (si tocaste frontend).
- [ ] Sin secretos ni `.env` en el diff (`git status` limpio de ignorados).
- [ ] Variables de entorno nuevas documentadas en `.env.example` y `docker-compose.yml`.
- [ ] Cambios de esquema BD son **aditivos** y tienen migración en `migration/`.
- [ ] Descripción: qué cambia, por qué, y cómo probarlo.

Revisión: al menos 1 aprobación. No hacer merge con CI en rojo.

## 7. Seguridad

Vulnerabilidades **no** van por issues públicos: ver [SECURITY.md](./SECURITY.md).

---
*¿Dudas? Abre un discussion/issue normal (no-security) y etiqueta a los maintainers.*
