#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/linux/.env"
[[ -f "$ENV_FILE" ]] || ENV_FILE="$ROOT/.env"
source "$ENV_FILE" 2>/dev/null || true

IP="${RAKSHAK_LAN_IP:-192.168.1.10}"

cat <<EOF

╔══════════════════════════════════════════════════════════════╗
║           RAKSHAK — Router / DHCP Configuration              ║
╚══════════════════════════════════════════════════════════════╝

Set your router's DHCP DNS server to:

    PRIMARY DNS:   ${IP}
    SECONDARY DNS: (leave empty or same IP)

Steps (generic):
  1. Open router admin (usually http://192.168.1.1 or .0.1)
  2. LAN / DHCP settings
  3. DNS Server → Manual → ${IP}
  4. Disable "DNS over DHCP from ISP" if present
  5. Save and reboot router OR renew DHCP on clients

Renew DHCP on clients:
  Windows:  ipconfig /release && ipconfig /renew
  macOS:    sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
  Linux:    sudo dhclient -r && sudo dhclient
  iOS:      toggle Wi-Fi off/on
  Android:  forget network / reconnect

Optional — force DNS (blocks bypass via 8.8.8.8):
  sudo ./scripts/firewall/apply-nftables.sh

Verify:
  dig @${IP} doubleclick.net +short    # should return 0.0.0.0
  dig @${IP} cloudflare.com +short     # should resolve normally

EOF
