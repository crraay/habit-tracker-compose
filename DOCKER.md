# Docker Compose (production + DigitalOcean)

This repo is the **only** clone required on the production droplet: `docker-compose.yml`, `.env`, and deploy scripts. Application images come from Docker Hub.

## Stack

| Service | Image |
|---------|--------|
| postgres | `postgres:16-alpine` (named volume, pinned — see `docker-compose.yml`) |
| backend | `docker.io/crraay/habit-tracker-springboot:latest` — built by **`build-image`** in [habit-tracker-springboot](https://github.com/crraay/habit-tracker-springboot) |
| frontend | `docker.io/crraay/habit-tracker-angular:latest` — built by **`build-image`** in [habit-tracker-angular](https://github.com/crraay/habit-tracker-angular) |

Compose project name **`habit-tracker-springboot`** and volume **`habit-tracker-springboot_postgres_data`** match the previous backend-repo deploy layout so existing Postgres data is preserved after migration.

## Local quick start (Hub images)

```bash
cp .env.example .env   # edit secrets
docker compose pull
docker compose up -d
```

App: **http://localhost** (port 80). API: **http://localhost/api/...**

## Local quick start (build from sibling repos)

```bash
cp docker-compose.override.example.yml docker-compose.override.yml
echo "docker-compose.override.yml" >> .gitignore   # if not already ignored locally
docker compose up --build -d
```

Requires `../habit-tracker-springboot` and `../habit-tracker-angular` next to this directory.

## CI/CD

### 1. Build images (app repos)

Push to **`main`** or run **`build-image`** manually in each app repo. That pushes **`latest`** to Docker Hub.

| Repo | Workflow | Gate |
|------|----------|------|
| habit-tracker-springboot | `build-image` | Maven package |
| habit-tracker-angular | `build-image` | `npm ci` + `test:ci` |

You manage backend/frontend version matching manually (both use **`latest`**).

### 2. Deploy (this repo only)

**Actions → deploy-image-digital-ocean → Run workflow**

| Input | Effect |
|-------|--------|
| `backend` | Pull/up backend only |
| `frontend` | Pull/up frontend only |
| `all` | Pull/up backend and frontend (default) |

Deploy is **manual** — run after app images are on Hub. Compose-only changes: push this repo, then run deploy (no app rebuild needed).

### Secrets (this repo → Settings → Secrets)

| Secret | Purpose |
|--------|---------|
| `SERVER_HOST` | Droplet IP or hostname |
| `SERVER_USER` | SSH user in `docker` group |
| `SERVER_PASSWORD` | SSH password |

### Variables (optional)

| Variable | Default | Purpose |
|----------|---------|--------|
| `DEPLOY_COMPOSE_DIR` | `/app/habit-tracker-compose` | Clone path on droplet |
| `SERVER_SSH_PORT` | `22` | SSH port |
| `DEPLOY_SSH_COMMAND_TIMEOUT` | `15m` | Remote script timeout |

Hub images are **public** — no `docker login` on the droplet for pull.

## Initial server setup

1. **Docker Engine + Compose v2** (Ubuntu — plugin is not in default repos):

   ```bash
   sudo apt-get install -y ca-certificates curl
   sudo install -m 0755 -d /etc/apt/keyrings
   sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
   docker compose version
   sudo usermod -aG docker YOUR_USER
   ```

   Log out and back in so `docker ps` works without sudo.

2. **Disable host nginx** if it binds port 80 (`sudo systemctl stop nginx && sudo systemctl disable nginx`).

3. **Clone this repo:**

   ```bash
   sudo mkdir -p /app && sudo chown YOUR_USER:YOUR_USER /app
   git clone https://github.com/crraay/habit-tracker-compose.git /app/habit-tracker-compose
   cd /app/habit-tracker-compose
   cp .env.example .env
   # edit .env: POSTGRES_*, JWT_SECRET, CORS_ALLOWED_ORIGINS (include http://YOUR_DROPLET_IP)
   ```

4. **First start:**

   ```bash
   docker compose pull
   docker compose up -d postgres
   docker compose ps   # wait until postgres is healthy
   docker compose up -d backend frontend
   ```

## Migrate from `/app/habit-tracker-springboot`

If you previously deployed from the backend repo clone:

1. On the droplet, note existing volume name: `docker volume ls | grep postgres`
2. Clone this repo to `/app/habit-tracker-compose` (see above).
3. **Move secrets (do not commit):**

   ```bash
   mv /app/habit-tracker-springboot/.env /app/habit-tracker-compose/.env
   ```

4. Confirm `docker-compose.yml` uses `name: habit-tracker-springboot` and volume `habit-tracker-springboot_postgres_data` (matches typical prior layout). If your volume name differs, adjust the `volumes.postgres_data.name` key to match `docker volume ls`.
5. From the new directory:

   ```bash
   cd /app/habit-tracker-compose
   docker compose pull
   docker compose up -d
   ```

6. Verify **http://YOUR_DROPLET_IP/** and `docker compose ps`.
7. Optional cleanup:

   ```bash
   rm -rf /app/habit-tracker-springboot /app/habit-tracker-angular
   ```

8. Remove **`SERVER_*`** secrets from app repos in GitHub (deploy lives here only).

## Data safety

- **Never** on production: `docker compose down -v`, `docker volume rm habit-tracker-springboot_postgres_data`, `docker system prune --volumes`.
- Deploy scripts only restart **backend** / **frontend** — Postgres is not rebuilt.

## Troubleshooting

- **`password authentication failed for user`:** Postgres credentials are fixed at first volume init; changing `.env` later does not change DB password — align or recreate volume (data loss) after backup.
- **Frontend: port 80 in use:** stop host nginx or other process on port 80.
- **502 on `/api/`:** backend must be healthy; check `docker compose ps` and `.env`.
- **Pull fails:** run **`build-image`** in the app repo at least once; confirm Hub repos are public.
- **Cannot connect to Docker daemon:** user in `docker` group; `systemctl status docker` active.
