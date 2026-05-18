#!/usr/bin/env bash
# OPTIONAL fail-open watchdog — restores ISP DNS if CoreDNS is down > 60s
# NOT recommended for security-conscious deployments. Enable explicitly.

set -euo pipefail

RAKSHAK_IP="${RAKSHAK_LAN_IP:-192.168.1.10}"
ISP_DNS="${ISP_DNS:-8.8.8.8}"
CHECK_INTERVAL=30
FAIL_THRESHOLD=2
fails=0

while true; do
  if dig @"$RAKSHAK_IP" -p 53 cloudflare.com +time=2 +tries=1 +short >/dev/null 2>&1; then
    fails=0
  else
    ((fails++)) || true
    if (( fails >= FAIL_THRESHOLD )); then
      echo "$(date) CoreDNS down — FAIL OPEN: setting router DNS hint to $ISP_DNS"
      # Implementation depends on router API — placeholder
      # uci set dhcp.@dnsmasq[0].server="$ISP_DNS"
      # uci commit dhcp && /etc/init.d/dnsmasq restart
    fi
  fi
  sleep "$CHECK_INTERVAL"
done
