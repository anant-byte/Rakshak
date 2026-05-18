#!/usr/bin/env bash
# RAKSHAK production deployment — run on dedicated Linux DNS host
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

[[ -f .env ]] || { echo "Run: cp .env.example .env && edit"; exit 1; }
source .env

echo "==> Pre-flight"
command -v docker >/dev/null
docker compose version >/dev/null

# Port 53 conflicts (systemd-resolved)
if ss -ulnp 2>/dev/null | grep -q ':53 '; then
  echo "WARN: port 53 in use. Stop systemd-resolved or bind RAKSHAK_LAN_IP only."
  echo "  sudo systemctl disable --now systemd-resolved"
fi

echo "==> Build & start"
docker compose build --pull
docker compose up -d

echo "==> Wait for health"
for i in $(seq 1 30); do
  if docker compose exec -T api wget -qO- http://127.0.0.1:8080/health 2>/dev/null; then
    break
  fi
  sleep 2
done

echo "==> Initial blocklist (may take 2-5 min)"
docker compose exec -T api /rakshak worker &
sleep 3 || true

IP="${RAKSHAK_LAN_IP:-127.0.0.1}"
echo "==> Verify DNS"
sleep 5
if command -v dig >/dev/null; then
  dig @"$IP" doubleclick.net +short +time=2 || true
  dig @"$IP" cloudflare.com +short +time=2 || true
fi

echo ""
echo "Deployed. Dashboard: http://${IP}  |  https://${RAKSHAK_DOMAIN:-rakshak.lan}"
./scripts/configure-router.sh
