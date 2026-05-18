# RAKSHAK — Self-Hosted Network-Wide Protection

Production-grade DNS sinkhole + policy engine that protects **every device** on your LAN (phones, TVs, IoT, guests) without per-device software.

## What it blocks

| Category | Source feeds (OSS) |
|----------|-------------------|
| Ads / trackers | OISD, StevenBlack, EasyList domains |
| Malware / C2 | URLhaus, ThreatFox, HaGeZi malware |
| Phishing / scams | Phishing Army, OpenPhish, ScamSniffer |
| Telemetry | HaGeZi telemetry, WindowsSpyBlocker |
| Crypto-miners | NoCoin, miner domains |
| Exploit kits | Emerging Threats domains |

## Architecture (30-second view)

```
[All LAN devices] → DHCP DNS = RAKSHAK host
                         ↓
              CoreDNS :53 (sinkhole + policy)
                         ↓
              Unbound :5353 (recursive, DNSSEC)
                         ↓
              Internet resolvers (optional DoT upstream)

Admin: Caddy → Next.js UI + Go API (:8080)
Data:  SQLite/Postgres + blocklist volumes
```

## macOS native app

Fully local SwiftUI app + daemon — protects your **entire home network** from your Mac:

```bash
cd macos
swift build
# Terminal 1:
.build/debug/RakshakDaemon
# Terminal 2:
.build/debug/Rakshak
```

See [macos/README.md](macos/README.md) for install, router setup, and privileged helper notes.

## Quick start (Docker / Linux appliance)

```bash
cp .env.example .env
# Edit RAKSHAK_LAN_IP, RAKSHAK_ADMIN_PASSWORD, RAKSHAK_SECRET_KEY

./scripts/install.sh          # deps check, dirs, permissions
docker compose up -d --build
./scripts/configure-router.sh # prints DHCP/DNS instructions

open https://rakshak.lan       # or http://<host-ip>:3000
```

Default admin: set via `RAKSHAK_ADMIN_PASSWORD` in `.env`.

## Hardware requirements

| Profile | RAM | CPU | Disk | Clients |
|---------|-----|-----|------|---------|
| Minimal (Pi 4) | 1 GB | 4× ARM | 8 GB SD | ≤30 |
| Recommended | 2 GB | 2× x86 | 32 GB SSD | ≤150 |
| Heavy | 4 GB | 4× x86 | 64 GB SSD | 500+ |

## Repository layout

```
rakshak/
├── backend/          Go control plane API
├── frontend/         Next.js admin dashboard
├── dns/              CoreDNS + Unbound configs
├── deploy/           Caddy, Prometheus, Grafana
├── scripts/          install, update, firewall, monitor
├── config/           safe defaults
└── docs/             architecture, threat model, deployment
```

## Router integration

Point **DHCP DNS server** to the RAKSHAK host IP. Optional: force DNS via `nftables` (see `scripts/firewall/nftables-rakshak.nft`).

## Fail-safe

If CoreDNS stops, `scripts/failopen-watchdog.sh` can restore ISP DNS via dnsmasq fallback (disabled by default — **fail-closed** is safer).

## License

Apache-2.0
