#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINUX="$ROOT/linux"
cd "$LINUX"

echo "==> RAKSHAK Linux appliance install"

command -v docker >/dev/null || { echo "Docker required"; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "Docker Compose v2 required"; exit 1; }

if [[ ! -f .env ]]; then
  cp "$ROOT/.env.example" .env
  SECRET=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p)
  ISECRET=$(openssl rand -hex 16 2>/dev/null || head -c 16 /dev/urandom | xxd -p)
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/CHANGE_ME_OPENSSL_RAND_HEX_32/$SECRET/" .env
    sed -i '' "s/CHANGE_ME_OPENSSL_RAND_HEX_16/$ISECRET/" .env
  else
    sed -i "s/CHANGE_ME_OPENSSL_RAND_HEX_32/$SECRET/" .env
    sed -i "s/CHANGE_ME_OPENSSL_RAND_HEX_16/$ISECRET/" .env
  fi
  echo "Created linux/.env — set RAKSHAK_LAN_IP and RAKSHAK_ADMIN_PASSWORD"
fi

mkdir -p data/coredns/custom blocklists
touch data/coredns/custom/blocked-extra.hosts

if grep -q "CHANGE_ME_LAN_IP" .env 2>/dev/null && command -v ip >/dev/null; then
  DETECTED=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || true)
  if [[ -n "${DETECTED:-}" ]]; then
    echo "Detected LAN IP: $DETECTED (set RAKSHAK_LAN_IP in linux/.env)"
  fi
fi

echo "==> Building and starting stack"
docker compose up -d --build

echo ""
echo "RAKSHAK is starting."
echo "  Dashboard: https://rakshak.lan"
echo "  Next: $ROOT/scripts/configure-router.sh"
