#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_USER="${1:-${SUDO_USER:-$USER}}"

if [[ $EUID -ne 0 ]]; then
  echo "Ejecuta este script con sudo." >&2
  exit 1
fi

apt-get update
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

. /etc/os-release
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

usermod -aG docker "$TARGET_USER"
mkdir -p /opt/elecciones
chown -R "$TARGET_USER":"$TARGET_USER" /opt/elecciones

cat <<MSG
Docker quedó instalado.
1. Cierra y abre la sesión SSH para aplicar el grupo docker.
2. Copia deploy/compose.prod.yml, deploy/deploy.sh y deploy/.env.example a /opt/elecciones.
3. Renombra .env.example a .env y completa los valores.
MSG
