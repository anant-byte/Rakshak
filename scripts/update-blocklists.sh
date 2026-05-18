#!/usr/bin/env bash
set -euo pipefail
# Manual blocklist refresh + CoreDNS reload signal

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

docker compose exec api /rakshak worker &
sleep 2

# Trigger via API (requires token) — simpler path:
docker compose exec -T api wget -qO- --post-data='' http://127.0.0.1:8080/api/v1/blocklists/update 2>/dev/null || true

echo "Use dashboard: Blocklists → Update Now, or login API POST /api/v1/blocklists/update"
docker compose restart coredns
echo "CoreDNS restarted to pick up blocklists."
