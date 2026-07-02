#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -lt 2 ]]; then
  echo "Uso: $0 <backend-image> <frontend-image> [health-url]" >&2
  exit 2
fi

BACKEND_IMAGE="$1"
FRONTEND_IMAGE="$2"
HEALTH_URL="${3:-}"
DEPLOY_DIR="${DEPLOY_DIR:-/opt/elecciones}"
COMPOSE_FILE="$DEPLOY_DIR/compose.prod.yml"
ENV_FILE="$DEPLOY_DIR/.env"

cd "$DEPLOY_DIR"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Falta $ENV_FILE. Copia .env.example, completa los secretos y vuelve a desplegar." >&2
  exit 3
fi

compose() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

old_backend="$(compose ps -q backend 2>/dev/null | xargs -r docker inspect --format '{{.Config.Image}}' 2>/dev/null || true)"
old_frontend="$(compose ps -q frontend 2>/dev/null | xargs -r docker inspect --format '{{.Config.Image}}' 2>/dev/null || true)"

export BACKEND_IMAGE FRONTEND_IMAGE

echo "Descargando imágenes..."
compose pull

echo "Aplicando despliegue..."
compose up -d --remove-orphans

backend_is_up() {
  compose exec -T backend sh -c \
    "curl -fsS http://localhost:8080/actuator/health | grep -q '\"status\":\"UP\"'"
}

public_is_up() {
  [[ -z "$HEALTH_URL" ]] || curl -fsS --max-time 15 "$HEALTH_URL" | grep -q '"status":"UP"'
}

healthy=false
for attempt in $(seq 1 60); do
  if backend_is_up && public_is_up; then
    healthy=true
    break
  fi
  echo "Esperando salud de la aplicación ($attempt/60)..."
  sleep 5
done

if [[ "$healthy" != "true" ]]; then
  echo "El despliegue no quedó saludable. Mostrando logs:" >&2
  compose logs --tail=150 backend frontend >&2 || true

  if [[ -n "$old_backend" && -n "$old_frontend" ]]; then
    echo "Ejecutando rollback a las imágenes anteriores..." >&2
    export BACKEND_IMAGE="$old_backend"
    export FRONTEND_IMAGE="$old_frontend"
    compose up -d --remove-orphans
  else
    echo "No existen imágenes anteriores para rollback." >&2
  fi
  exit 1
fi

echo "Despliegue saludable."
docker image prune -f --filter "until=168h" >/dev/null || true
compose ps
