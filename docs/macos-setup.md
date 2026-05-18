# macOS setup

## Quick start

```bash
cd macos
chmod +x run.sh
./run.sh
```

Or install system-wide:

```bash
./scripts/install-mac.sh
```

## Requirements

- macOS 14+
- Homebrew
- CoreDNS: `brew install coredns`
- Router access (DHCP DNS → this Mac's LAN IP)

## Port 53

Binding DNS port 53 requires root. `run.sh` starts CoreDNS with `sudo`. Production installs should use the SMJobBless privileged helper (see `macos/Helper/README.md`).

## Data directory

`~/Library/Application Support/Rakshak/` — database, blocklists, `daemon.token`, logs.

Never commit this folder to git.
