# RAKSHAK — Exact Implementation Plan

## Phase 1: Host preparation (30 min)

| Step | Action |
|------|--------|
| 1.1 | Provision Linux host (NUC, VM, Pi 4 2GB+) with static LAN IP |
| 1.2 | Install Docker 24+ and Compose v2 |
| 1.3 | Free port 53: `systemctl disable systemd-resolved` if needed |
| 1.4 | Clone repo to `/opt/rakshak` |

## Phase 2: Configuration (10 min)

```bash
cp .env.example .env
openssl rand -hex 32  # → RAKSHAK_SECRET_KEY
openssl rand -hex 16  # → RAKSHAK_INTERNAL_SECRET
# Set RAKSHAK_LAN_IP, RAKSHAK_ADMIN_PASSWORD
```

## Phase 3: Build & deploy (15 min)

```bash
./scripts/deploy.sh
# or: ./scripts/install.sh
```

## Phase 4: Router integration (5 min)

```bash
./scripts/configure-router.sh
```

Set DHCP DNS = `RAKSHAK_LAN_IP`. No client software required.

## Phase 5: Verification

```bash
dig @$RAKSHAK_LAN_IP doubleclick.net +short   # → 0.0.0.0
dig @$RAKSHAK_LAN_IP cloudflare.com +short    # → real IP
./scripts/monitor/healthcheck.sh
```

## Phase 6: Hardening (optional)

```bash
RAKSHAK_FORCE_DNS=true ./scripts/firewall/apply-nftables.sh
docker compose --profile monitoring up -d
```

## Phase 7: systemd auto-start

```bash
sudo cp deploy/systemd/rakshak.service /etc/systemd/system/
sudo systemctl enable --now rakshak
```

## Component build order (developers)

1. `backend/` — `go build ./cmd/rakshak`
2. `dns/coredns` — Corefile + blocklists volume
3. `dns/log-collector` — query log pipeline
4. `frontend/` — `npm run build`
5. `docker compose build` — integration

## Data flow checklist

- [ ] Worker fetches OSS feeds → `blocked.hosts`
- [ ] CoreDNS reloads hosts file every 5m
- [ ] Unbound resolves non-blocked queries with DNSSEC
- [ ] logd tails CoreDNS → API `query-log` table
- [ ] Dashboard reads stats via JWT API
