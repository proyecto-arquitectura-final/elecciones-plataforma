# Despliegue automático en Amazon Lightsail

## Flujo implementado

- Cada `push` y `pull_request` compila y prueba Maven y Angular.
- Un `push` a `main` publica dos imágenes en GHCR:
  - `ghcr.io/<owner>/<repo>-backend`
  - `ghcr.io/<owner>/<repo>-frontend`
- Después se conecta por SSH al Lightsail, ejecuta `docker compose pull/up`, valida salud y hace rollback si la nueva versión falla.
- El frontend usa Caddy para servir Angular, enrutar `/api/*` al backend y emitir/renovar HTTPS automáticamente cuando se configura un dominio real.

## 1. Preparar Lightsail una sola vez

1. Asigna una IP estática a la instancia.
2. En el firewall de Lightsail abre:
   - TCP 80 desde Internet.
   - TCP 443 desde Internet.
   - TCP 22 solamente desde tu IP administrativa cuando sea posible.
3. Crea un registro DNS `A` del dominio hacia la IP estática.
4. Copia `deploy/bootstrap-lightsail.sh` al servidor y ejecuta:

```bash
sudo bash bootstrap-lightsail.sh "$USER"
```

Cierra y abre la sesión SSH para aplicar el grupo `docker`.

## 2. Configurar producción en el servidor

```bash
mkdir -p /opt/elecciones
cd /opt/elecciones
cp /ruta/al/deploy/.env.example .env
nano .env
chmod 600 .env
```

No publiques PostgreSQL ni el puerto 8080 en el firewall. En producción solamente Caddy publica 80/443.

Genera secretos fuertes, por ejemplo:

```bash
openssl rand -base64 48
```

## 3. Secrets de GitHub

En `Settings → Secrets and variables → Actions` crea:

| Secret | Contenido |
|---|---|
| `LIGHTSAIL_HOST` | IP estática o hostname del Lightsail |
| `LIGHTSAIL_USER` | Normalmente `ubuntu` |
| `LIGHTSAIL_SSH_KEY` | Clave privada PEM completa |
| `LIGHTSAIL_KNOWN_HOSTS` | Salida de `ssh-keyscan -H <IP_O_HOST>` |
| `PRODUCTION_URL` | `https://elecciones.tudominio.com` |
| `GHCR_USERNAME` | Usuario propietario del paquete, solo si GHCR es privado |
| `GHCR_READ_TOKEN` | PAT con `read:packages`, solo si GHCR es privado |

Crea además el Environment de GitHub llamado `production`. Allí puedes exigir aprobación manual antes del despliegue.

## 4. Primera publicación

Sube el contenido del repositorio y realiza un `push` a `main`:

```bash
git add .
git commit -m "Configura CI/CD y despliegue Lightsail"
git push origin main
```

El primer certificado HTTPS solo se podrá emitir cuando el DNS ya apunte a la instancia y los puertos 80/443 estén abiertos.

## 5. Desarrollo local con todo en Docker

```bash
docker compose up -d --build
```

Servicios locales:

- Frontend: `http://localhost:4200`
- Backend: `http://localhost:8080`
- PostgreSQL: `localhost:5433`

Para ver logs:

```bash
docker compose logs -f backend frontend postgres
```

## 6. Comandos operativos en Lightsail

```bash
cd /opt/elecciones
docker compose --env-file .env -f compose.prod.yml ps
docker compose --env-file .env -f compose.prod.yml logs -f --tail=200
docker compose --env-file .env -f compose.prod.yml restart backend
```

Respaldo manual de PostgreSQL:

```bash
cd /opt/elecciones
docker compose --env-file .env -f compose.prod.yml exec -T postgres \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" | gzip > elecciones-$(date +%F-%H%M).sql.gz
```
