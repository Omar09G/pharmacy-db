# 🏗️ Diagrama de Arquitectura — Pharmacy

> DOC-4 del [PLAN_MEJORAS.md](./PLAN_MEJORAS.md) · Diagramas en Mermaid (renderizan en GitHub/GitLab).

---

## 1. Diagrama de componentes

```mermaid
flowchart LR
    subgraph Clientes
        B[Browser SPA]
        A[App Android<br/>Capacitor]
    end

    subgraph Edge
        N[nginx :8085<br/>CSP + HSTS-ready]
    end

    subgraph Backend["Backend API (Axum :8081)"]
        direction TB
        MW["Middlewares:<br/>security_headers → cors → rate_limit<br/>→ content_type → auth_jwt → idempotency → cache"]
        RT["Routes (12 grupos)<br/>auth · user · rbac · product · inventory<br/>sales · purchase · finance · catalog<br/>audit · dashboard · health"]
        CB["Circuit breaker Redis"]
        JWT["JWT RS256/HMAC<br/>+ revocación JTI"]
    end

    subgraph Datos
        PG[(PostgreSQL 15<br/>schema: pharmacy)]
        RD[(Redis 7)]
    end

    B -- HTTPS/cookies HttpOnly --> N
    A -- Bearer + X-Client-Platform --> N
    N -- proxy /v1/api --> MW --> RT
    RT --> PG
    RT -.-> CB -.-> RD
    JWT --- RT
```

## 2. Diagrama de despliegue (Docker)

```mermaid
flowchart TB
    subgraph Host["Docker host"]
        subgraph Compose["docker-compose"]
            FE["frontend<br/>nginx:alpine :8185→8085"]
            BE["backend<br/>multi-stage build<br/>usuario no-root :8081<br/>HEALTHCHECK /health"]
            subgraph Opcional["profile: db"]
                PGS[(postgres:15-alpine<br/>volume pgdata)]
                RDS[(redis:7-alpine<br/>volume redisdata)]
            end
        end
        HD[("host.docker.internal<br/>PG/Redis del host")]
        PEM[/pem/ RSA keys ro/]
        LOGS[/logs/ app.log/]
    end
    LB["Load Balancer / K8s probes<br/>GET /health · GET /health/ready"]

    FE --> BE
    BE -->|default| HD
    BE -.->|--profile db| PGS
    BE -.->|--profile db| RDS
    PEM --> BE
    BE --> LOGS
    LB -.probes.-> BE
```

## 3. Flujo de autenticación

```mermaid
sequenceDiagram
    participant C as Cliente
    participant API as Backend (Axum)
    participant DB as PostgreSQL
    participant R as Redis

    C->>API: POST /auth/login (user, password)
    API->>DB: SELECT user + roles + permisos
    API->>API: Argon2 verify (spawn_blocking)
    API->>API: Genera access (1d) + refresh (7d) con JTI
    API-->>C: Cookie HttpOnly + body (nativos)
    Note over C,API: Requests posteriores: cookie o Bearer

    C->>API: POST /sale (cookie/Bearer)
    API->>API: validate_token (RS256/HMAC)
    API->>R: ¿revoked_jti:{jti}? (circuit breaker)
    alt JTI revocado
        API-->>C: 401 Token has been revoked
    else Válido
        API->>DB: INSERT venta (tx)
        API-->>C: 200 ApiResponse success
    end

    C->>API: POST /auth/logout
    API->>R: SET revoked_jti:{jti} TTL=exp
    API-->>C: 200 OK
```

## 4. Estrategia de resiliencia

```mermaid
flowchart TD
    REQ[Request] --> RL{Rate limit<br/>¿bajo el umbral?}
    RL -- no --> T429[429 TOO_MANY_REQUESTS]
    RL -- sí --> AUTH{JWT válido?}
    AUTH -- no --> T401[401]
    AUTH -- sí --> H{Handler}
    H --> DBC{DB ¿OK?}
    DBC -- no --> RETRY[Retry backoff exponencial<br/>al arranque / readiness 503]
    H --> RC{Redis circuit<br/>¿cerrado?}
    RC -- abierto --> FB[Fallback memoria<br/>degradación explícita]
    RC -- cerrado/half-open --> RD[Operación Redis]
```

---

*Ver también: [INFORME_PROYECTO.md](./INFORME_PROYECTO.md), [PLAN_MEJORAS.md](./PLAN_MEJORAS.md), [CAMBIOLOG_MEJORAS.md](./CAMBIOLOG_MEJORAS.md).*
