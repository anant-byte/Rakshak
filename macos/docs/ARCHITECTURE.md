# Rakshak macOS — Native Architecture

## Product vision

**Rakshak for Mac** is a fully local home network security appliance controlled from a premium SwiftUI app. Your Mac becomes the DNS brain of the house — phones, TVs, IoT, and guests are protected without installing anything on them.

## UX philosophy

| Principle | Implementation |
|-----------|----------------|
| Calm, not alarming | Soft cards, plain language, no terminal aesthetic |
| One-glance status | Shield + blocked count on Home |
| Elder-friendly | Large type, obvious toggles, guided onboarding |
| Premium feel | Rounded cards, spring animations, native sidebar |
| Zero cloud | Keychain auth, localhost API only |

## System architecture

```
┌─────────────────────────────────────────────────────────────┐
│  SwiftUI App (Rakshak)                                       │
│  MenuBarExtra · Charts · Keychain login                      │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTP/WebSocket 127.0.0.1:9847
┌───────────────────────────▼─────────────────────────────────┐
│  RakshakDaemon                                                 │
│  LocalAPIServer · DeviceDiscovery · DNSEngine · PFManager      │
└───────┬─────────────────┬─────────────────┬─────────────────┘
        │                 │                 │
   CoreDNS :53      SQLite WAL       pf anchor
   blocked.hosts    ~/Library/...     (optional)
        │
   All LAN devices (router DNS → Mac IP)
```

## Component map

| Layer | Module | Responsibility |
|-------|--------|----------------|
| UI | `RakshakApp` | SwiftUI, onboarding, menu bar |
| Core | `RakshakCore` | Models, SQLite, Keychain, theme |
| DNS | `RakshakDNS` | Blocklist parse, CoreDNS lifecycle |
| Network | `RakshakNetwork` | ARP scan, LAN IP |
| Firewall | `RakshakFirewall` | pf rules file + apply |
| IPC | `RakshakIPC` | Local HTTP + WebSocket |
| Daemon | `RakshakDaemonLib` | Orchestration |

## DNS filtering

1. Merge bundled + user `.txt` / hosts lists → `blocked.hosts`
2. CoreDNS `hosts` plugin returns `0.0.0.0`
3. Forward clean queries to `127.0.0.1:5353` (optional Unbound) or upstream

## Packet filtering

DNS sinkhole is primary. **pf** optional for force-DNS and blocking DoT `:853`.

## Device discovery

`arp -an` every 60s → SQLite → new device alerts.

## Local database

`~/Library/Application Support/Rakshak/rakshak.db` — devices, threats, alerts, query logs.

## Background service

`launchd` `com.rakshak.daemon` — KeepAlive, low priority Nice=5.

## Sandboxing

App: sandboxed with network client to localhost only (entitlements in Xcode).
Daemon: not sandboxed; minimal root helper for :53.

## Performance

| Metric | Target |
|--------|--------|
| Daemon RAM | < 80 MB |
| CPU idle | < 2% |
| UI poll | 2s interval |
| Blocklist rebuild | < 30s |

## Threat model

- **In scope:** malicious domains, trackers, LAN unknown devices
- **Out of scope:** HTTPS content inspection, VPN DoH inside apps (mitigate with pf)

## Deployment

```bash
cd macos && ./scripts/install.sh
```

See `Helper/README.md` for privileged DNS on port 53.
