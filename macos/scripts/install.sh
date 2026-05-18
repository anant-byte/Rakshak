#!/usr/bin/env bash
# Install Rakshak macOS — local binaries, launchd, CoreDNS dependency
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PREFIX="${RAKSHAK_PREFIX:-/opt/rakshak}"
LOG_DIR="/Library/Logs/Rakshak"

echo "==> Rakshak macOS install"
echo "    Prefix: $PREFIX"

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only"; exit 1; }

if ! command -v brew >/dev/null; then
  echo "Install Homebrew first: https://brew.sh"
  exit 1
fi

if ! command -v coredns >/dev/null; then
  echo "==> Installing CoreDNS (DNS engine)"
  brew install coredns
fi

echo "==> Building release"
cd "$ROOT"
swift build -c release

echo "==> Installing binaries"
sudo mkdir -p "$PREFIX/bin" "$PREFIX/Blocklists" "$LOG_DIR"
sudo cp ".build/release/Rakshak" "$PREFIX/bin/"
sudo cp ".build/release/RakshakDaemon" "$PREFIX/bin/"
sudo cp -R Sources/RakshakApp/Resources/Blocklists/* "$PREFIX/Blocklists/" 2>/dev/null || true

echo "==> Installing launchd agent"
sudo cp launchd/com.rakshak.daemon.plist /Library/LaunchDaemons/
sudo launchctl bootstrap system /Library/LaunchDaemons/com.rakshak.daemon.plist 2>/dev/null || \
  sudo launchctl load /Library/LaunchDaemons/com.rakshak.daemon.plist

echo ""
echo "Installed."
echo "  App:     open $PREFIX/bin/Rakshak  (or copy to /Applications)"
echo "  Daemon:  com.rakshak.daemon (port 53 requires root — see Helper README)"
echo ""
echo "NEXT: Set router DHCP DNS to this Mac's IP (shown in app onboarding)"
