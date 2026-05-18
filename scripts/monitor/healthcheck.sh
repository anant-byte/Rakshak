#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/.env" 2>/dev/null || RAKSHAK_LAN_IP=127.0.0.1

FAIL=0

check() {
  local name=$1 cmd=$2
  if eval "$cmd" >/dev/null 2>&1; then
    echo "OK   $name"
  else
    echo "FAIL $name"
    FAIL=1
  fi
}

check "API" "curl -sf http://localhost/health || docker compose -f $ROOT/docker-compose.yml exec -T api wget -qO- http://127.0.0.1:8080/health"
check "CoreDNS" "dig @${RAKSHAK_LAN_IP} -p 53 cloudflare.com +time=2 +tries=1 +short"
check "Sinkhole" "test \"\$(dig @${RAKSHAK_LAN_IP} doubleclick.net +short | head -1)\" = '0.0.0.0'"

docker compose -f "$ROOT/docker-compose.yml" ps --format 'table {{.Name}}\t{{.Status}}' 2>/dev/null || true

exit $FAIL
