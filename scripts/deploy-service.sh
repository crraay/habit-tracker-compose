#!/usr/bin/env bash
# Deploy one or all app services (pull Hub image, recreate container). Postgres is untouched.
set -euo pipefail

SERVICE="${1:?Usage: deploy-service.sh backend|frontend|all}"

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: 'docker compose' (Compose v2) is required."
  exit 1
fi

deploy_one() {
  local name="$1"
  docker compose pull "$name"
  docker compose stop "$name" 2>/dev/null || true
  docker compose rm -f "$name" 2>/dev/null || true
  docker compose up -d "$name"
}

case "$SERVICE" in
  backend)
    deploy_one backend
    ;;
  frontend)
    deploy_one frontend
    ;;
  all)
    docker compose pull backend frontend
    deploy_one backend
    deploy_one frontend
    ;;
  *)
    echo "ERROR: unknown service '$SERVICE' (use backend, frontend, or all)"
    exit 1
    ;;
esac

docker compose ps
