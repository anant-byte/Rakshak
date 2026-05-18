# Windows setup

## Quick start

```powershell
# Administrator PowerShell
.\scripts\install-windows.ps1

cd windows
npm install
npm run tauri dev
```

Build installer:

```powershell
npm run tauri build
```

Artifacts: `windows/src-tauri/target/release/bundle/nsis/` or `msi/`.

## Requirements

- Windows 10/11 x64
- [WebView2](https://developer.microsoft.com/microsoft-edge/webview2/)
- [Rust](https://rustup.rs/)
- [Node.js](https://nodejs.org/) 20+
- [CoreDNS for Windows](https://github.com/coredns/coredns/releases) on `PATH` or `COREDNS_PATH`

## Port 53 and DNS Client service

Windows **DNS Client** binds UDP/TCP 53. Before Rakshak can sinkhole LAN DNS:

1. Open `services.msc`
2. Stop **DNS Client** (Dnscache)
3. Set startup type to **Disabled** (or Manual for testing)

Run the app **as Administrator** when enabling protection.

## Router

Set DHCP DNS to this PC's LAN IPv4 (shown in the app).

## Firewall

`install-windows.ps1` adds inbound rules for UDP/TCP 53. For force-DNS (block other resolvers), see advanced WFP docs — not enabled by default.

## Windows Defender

Add exclusion for `%ProgramFiles%\Rakshak` and `%APPDATA%\Rakshak` if real-time scan interferes with CoreDNS reload.

## Data directory

`%APPDATA%\Rakshak\` — blocklists, Corefile, database, `daemon.token`.
