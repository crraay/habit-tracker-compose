# Architecture (one-page)

Distilled from the Habit Tracker codebase scan. This repo is **packaging and deploy only** — no application or domain code. Domain law: [../habit-tracker-springboot/docs/domain.md](../habit-tracker-springboot/docs/domain.md).

## Role in the system

| Repo | Responsibility |
|------|----------------|
| [habit-tracker-springboot](../habit-tracker-springboot) | Builds **backend** image → Docker Hub |
| [habit-tracker-angular](../habit-tracker-angular) | Builds **frontend** (nginx) image → Docker Hub |
| **This repo (U3)** | Compose stack on droplet, `.env`, SSH deploy workflow |

## Production topology

Single host, Compose project **`habit-tracker-springboot`**, default bridge network.

```
Browser :80 → frontend (Hub) ──/api──► backend:8080 (Hub) ──JDBC──► postgres:16
                                              ↑
                         volume habit-tracker-springboot_postgres_data
```

| Service | Image / source | Host ports |
|---------|----------------|------------|
| `postgres` | `postgres:16-alpine` | none (internal) |
| `backend` | `docker.io/crraay/habit-tracker-springboot:latest` | none |
| `frontend` | `docker.io/crraay/habit-tracker-angular:latest` | **80:80** |

Committed **`docker-compose.yml`** pulls Hub images only (no in-repo app build for prod).

## Deploy path

1. U1/U2: merge to **`main`** → **`build-image`** publishes `:latest`.
2. U3: **Actions → deploy-docker-image-ssh** (`all` | `backend` | `frontend`).
3. SSH: `git pull --ff-only` in `DEPLOY_COMPOSE_DIR` → **`./scripts/deploy-service.sh`** (pull, recreate; **Postgres untouched**).

Details: [DOCKER.md](../DOCKER.md).

## Configuration

- **`/.env`** on droplet (from `.env.example`): `POSTGRES_*`, `JWT_SECRET`, `CORS_ALLOWED_ORIGINS` — never commit real values.
- GitHub Secrets: `SERVER_HOST`, `SERVER_USER`, `SERVER_PASSWORD` (prefer SSH keys as improvement).
- Flyway runs **inside backend container** on start — no migration job in this repo.

## Local dev

- Hub mode: `docker compose pull && up -d` (see DOCKER.md).
- Build siblings: `docker-compose.override.example.yml` → requires `../habit-tracker-springboot` and `../habit-tracker-angular`.

## Design choices (as-built)

| Choice | Why |
|--------|-----|
| Preserve compose **project + volume names** | Postgres data survived migration from backend-only deploy layout |
| **`:latest`** tags | Simple coordination; operator aligns U1/U2 releases manually |
| **Manual** `workflow_dispatch` | Explicit production gate |
| No staging stack in repo | Operator/local override only |

## Out of scope here

- REST/UI implementation, Flyway SQL, habit rules.
- Building app images (app repos only).

## Where to go deeper

- [AGENTS.md](../AGENTS.md), [README.md](../README.md).
- Operation runbooks from full-repo scan: AI-DLC intent `260914-full-repo-scan` under workspace `habit-tracker-ai-dlc/aidlc/.../operation/`.
