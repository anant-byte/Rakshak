#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="$ROOT/linux/.env"
[[ -f "$ENV_FILE" ]] || ENV_FILE="$ROOT/.env"
source "$ENV_FILE"

if [[ ! "$RAKSHAK_LAN_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid RAKSHAK_LAN_IP: $RAKSHAK_LAN_IP"
  exit 1
fi

NFT="$ROOT/scripts/firewall/nftables-rakshak.nft"
TMP=$(mktemp)
sed "s/192.168.1.10/${RAKSHAK_LAN_IP}/" "$NFT" > "$TMP"

# Detect bridge interface
LAN_IF="${RAKSHAK_LAN_IF:-}"
if [[ -z "$LAN_IF" ]]; then
  LAN_IF=$(ip route | awk '/default/ {print $5; exit}')
fi
sed -i.bak "s/br0/${LAN_IF}/" "$TMP" 2>/dev/null || sed -i '' "s/br0/${LAN_IF}/" "$TMP"

echo "Applying nftables (LAN_IF=$LAN_IF, RAKSHAK=${RAKSHAK_LAN_IP})"
sudo nft -f "$TMP"
rm -f "$TMP" "$TMP.bak"
echo "Done. Verify: dig @8.8.8.8 google.com from a LAN client should fail if force rules active."
