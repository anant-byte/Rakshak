# RAKSHAK

[![CI](https://github.com/anant-byte/rakshak/actions/workflows/ci.yml/badge.svg)](https://github.com/anant-byte/rakshak/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
![macOS](https://img.shields.io/badge/macOS-14%2B-black)
![Windows](https://img.shields.io/badge/Windows-10%2B-blue)
![Linux](https://img.shields.io/badge/Linux-Docker-orange)

**RAKSHAK** is self-hosted, network-wide DNS protection for your home LAN. Point your router’s DNS to a RAKSHAK host and every device—phones, TVs, IoT, guests—is filtered without per-device software.

_Screenshot: add `docs/images/dashboard.png` before your first release._

## Features

- **Network-wide sinkhole** — ads, trackers, malware, phishing, scams, miners, telemetry
- **OSS blocklists** — OISD, StevenBlack, URLhaus, HaGeZi, Phishing Army, and more
- **Device discovery** — ARP-based inventory + new device alerts (desktop apps)
- **Local-first** — no cloud account; macOS/Windows run entirely on your machine
- **Linux appliance** — Docker stack with Next.js admin UI (Pi / NUC / VM)
- **Fail-closed options** — optional nftables / pf force-DNS on supported platforms

## Quick install

### macOS (one command)

```bash
git clone https://github.com/anant-byte/rakshak.git
cd rakshak/macos && ./run.sh
```

Set router DHCP DNS to your Mac’s LAN IP (shown in the app). See [docs/macos-setup.md](docs/macos-setup.md).

### Windows

```powershell
git clone https://github.com/anant-byte/rakshak.git
cd rakshak
.\scripts\install-windows.ps1
cd windows
npm install
npm run tauri build
```

Install the generated `.msi` / `.exe` from `windows/src-tauri/target/release/bundle/`. See [docs/windows-setup.md](docs/windows-setup.md).

### Linux (Docker appliance)

```bash
git clone https://github.com/anant-byte/rakshak.git
cd rakshak
./scripts/install.sh
./scripts/configure-router.sh
```

Edit `linux/.env` first: `RAKSHAK_LAN_IP`, `RAKSHAK_ADMIN_PASSWORD`, secrets. Dashboard: `https://rakshak.lan`.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  All LAN devices (DHCP DNS → RAKSHAK host)                  │
└────────────────────────────┬────────────────────────────────┘
                             │ UDP/TCP :53
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  CoreDNS — hosts sinkhole + cache + forward                 │
└────────────────────────────┬────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
   blocked.hosts      allow.hosts         upstream
   (OSS feeds)        (overrides)      1.1.1.1 / Unbound

Desktop: SwiftUI (macOS) / Tauri (Windows) + background daemon
Linux:   Go API + Next.js + Caddy + worker cron
```

| Component | macOS | Windows | Linux |
|-----------|-------|---------|-------|
| UI | SwiftUI | Tauri + React | Next.js |
| Daemon | RakshakDaemon | Tauri + `rakshak-core` | Docker services |
| DNS | CoreDNS :53 | CoreDNS :53 | CoreDNS container |
| DB | SQLite | SQLite | SQLite / Postgres |
| Discovery | `arp -an` | `arp -a` / NetNeighbor | `/proc/net/arp` |

Shared Rust crate: [`core/`](core/) — blocklist merge, paths, `PlatformService` trait.

## Comparison

| | **RAKSHAK** | **Pi-hole** | **AdGuard Home** | **NextDNS** |
|---|-------------|-------------|------------------|-------------|
| Hosting | Self-hosted | Self-hosted | Self-hosted | Cloud |
| Per-device agent | No | No | No | Optional |
| macOS native app | Yes | No | Limited | App links only |
| Windows native app | Yes (Tauri) | No | Yes | App links only |
| Malware-focused feeds | Yes | Yes | Yes | Yes |
| Force-DNS / bypass block | Optional | Optional | Yes | N/A |
| Cost | Free (OSS) | Free | Free tier | Subscription |

## Repository layout

```
rakshak/
├── core/           Shared Rust (blocklist, platform abstraction)
├── macos/          SwiftUI app + daemon
├── windows/        Tauri desktop app
├── linux/          Docker appliance (backend, frontend, dns)
├── docs/
├── scripts/
└── .github/        CI + release workflows
```

## FAQ

**Does RAKSHAK inspect HTTPS traffic?**  
No. Protection is DNS-only. Malicious HTTPS still requires a browser or endpoint tool.

**Will this break my smart TV / IoT?**  
Usually no—DNS filtering is transparent. Use allowlists for devices that break.

**Can I run macOS and Linux together?**  
Use one DNS server per LAN. Pick either a Mac, a Windows PC, or a Linux appliance as the DHCP DNS target.

**Where are secrets stored?**  
Linux: `.env` (never commit). Desktop: Keychain (macOS), `%APPDATA%` + `daemon.token` (Windows).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Security reports: [SECURITY.md](SECURITY.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE). Copyright Rakshak Contributors.
