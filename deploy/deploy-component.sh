#!/usr/bin/env bash
set -Eeuo pipefail

SERVICE="${1:-}"
NEW_IMAGE="${2:-}"
PUBLIC_URL="${3:-}"
DEPLOY_DIR="${DEPLOY_DIR:-/opt/elecciones}"
COMPOSE_FILE="$DEPLOY_DIR/compose.prod.yml"
ENV_FILE="$DEPLOY_DIR/.env"

case "$SERVICE" in
  backend) IMAGE_KEY="BACKEND_IMAGE" ;;
  frontend) IMAGE_KEY="FRONTEND_IMAGE" ;;
  *) echo "Uso: $0 <backend|frontend> <imagen> [url-publica]" >&2; exit 2 ;;
esac

[[ -n "$NEW_IMAGE" ]] || { echo "La imagen es obligatoria." >&2; exit 2; }
[[ -f "$COMPOSE_FILE" ]] || { echo "Falta $COMPOSE_FILE" >&2; exit 3; }
[[ -f "$ENV_FILE" ]] || { echo "Falta $ENV_FILE. Copia .env.example y configura producción." >&2; exit 3; }

cd "$DEPLOY_DIR"

compose() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

read_env() {
  local key="$1"
  sed -n "s/^${key}=//p" "$ENV_FILE" | tail -n 1
}

write_env() {
  local key="$1" value="$2" tmp
  tmp="$(mktemp)"
  awk -v key="$key" -v value="$value" '
    BEGIN { found = 0 }
    index($0, key "=") == 1 { print key "=" value; found = 1; next }
    { print }
    END { if (!found) print key "=" value }
  ' "$ENV_FILE" > "$tmp"
  chmod --reference="$ENV_FILE" "$tmp" 2>/dev/null || chmod 600 "$tmp"
  mv "$tmp" "$ENV_FILE"
}

container_image() {
  local id
  id="$(compose ps -q "$SERVICE" 2>/dev/null || true)"
  [[ -n "$id" ]] && docker inspect --format '{{.Config.Image}}' "$id" 2>/dev/null || true
}

wait_postgres() {
  for attempt in $(seq 1 40); do
    if compose exec -T postgres pg_isready -U "$(read_env POSTGRES_USER)" -d "$(read_env POSTGRES_DB)" >/dev/null 2>&1; then
      return 0
    fi
    echo "Esperando PostgreSQL ($attempt/40)..."
    sleep 3
  done
  return 1
}

backend_healthy() {
  compose exec -T backend sh -c \
    "curl -fsS http://localhost:8080/actuator/health | grep -q '\"status\":\"UP\"'"
}

frontend_healthy() {
  local id
  id="$(compose ps -q frontend 2>/dev/null || true)"
  [[ -n "$id" ]] && [[ "$(docker inspect --format '{{.State.Running}}' "$id" 2>/dev/null)" == "true" ]]
}

public_healthy() {
  # El backend se valida dentro del contenedor. Esto permite el primer despliegue
  # antes de que Caddy/frontend exista. El despliegue del frontend valida la URL pública.
  [[ "$SERVICE" == "backend" ]] && return 0
  [[ -z "$PUBLIC_URL" ]] && return 0
  local base="${PUBLIC_URL%/}"
  curl -fsS --max-time 20 "$base/" >/dev/null &&
    curl -fsS --max-time 20 "$base/actuator/health" | grep -q '"status":"UP"'
}

OLD_ENV_IMAGE="$(read_env "$IMAGE_KEY")"
OLD_RUNNING_IMAGE="$(container_image)"
OLD_IMAGE="${OLD_RUNNING_IMAGE:-$OLD_ENV_IMAGE}"

rollback() {
  if [[ -z "$OLD_IMAGE" ]]; then
    echo "No existe una imagen anterior para rollback." >&2
    return 0
  fi
  echo "Ejecutando rollback de $SERVICE hacia $OLD_IMAGE..." >&2
  write_env "$IMAGE_KEY" "$OLD_IMAGE"
  compose pull "$SERVICE" || true
  compose up -d --no-deps "$SERVICE" || true
}

trap 'echo "Falló el despliegue de $SERVICE." >&2; rollback' ERR

write_env "$IMAGE_KEY" "$NEW_IMAGE"

if [[ "$SERVICE" == "backend" ]]; then
  compose up -d postgres
  wait_postgres
fi

compose pull "$SERVICE"
compose up -d --no-deps "$SERVICE"

healthy=false
for attempt in $(seq 1 60); do
  if [[ "$SERVICE" == "backend" ]]; then
    service_ok=false
    backend_healthy && service_ok=true
  else
    service_ok=false
    frontend_healthy && service_ok=true
  fi

  if [[ "$service_ok" == "true" ]] && public_healthy; then
    healthy=true
    break
  fi

  echo "Esperando salud de $SERVICE ($attempt/60)..."
  sleep 5
done

if [[ "$healthy" != "true" ]]; then
  compose logs --tail=200 "$SERVICE" >&2 || true
  false
fi

trap - ERR
echo "$SERVICE desplegado correctamente con $NEW_IMAGE"
docker image prune -f --filter "until=168h" >/dev/null || true
compose ps
