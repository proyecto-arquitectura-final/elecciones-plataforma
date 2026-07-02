# Archivos incorporados

- `Dockerfile.backend`: compila el POM raíz, `commons` y `back`; la imagen final solo contiene el JRE y el JAR ejecutable.
- `front/Dockerfile`: construye Angular y lo sirve con Caddy.
- `front/Caddyfile`: SPA fallback, reverse proxy `/api`, compresión, caché y HTTPS.
- `docker-compose.yml`: stack local completo.
- `deploy/compose.prod.yml`: stack de producción sin exponer PostgreSQL ni Spring Boot.
- `deploy/.env.example`: variables requeridas en Lightsail.
- `deploy/deploy.sh`: actualización con health check y rollback.
- `deploy/bootstrap-lightsail.sh`: instalación inicial de Docker en Ubuntu.
- `.github/workflows/ci-cd.yml`: pruebas, publicación en GHCR y despliegue.
- `DEPLOY_LIGHTSAIL.md`: guía de configuración paso a paso.
