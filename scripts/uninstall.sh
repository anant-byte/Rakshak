#!/usr/bin/env bash
# Uninstall Rakshak (macOS / Linux hints)
set -euo pipefail

echo "==> Rakshak uninstall"

if [[ "$(uname)" == "Darwin" ]]; then
  pkill -f RakshakDaemon 2>/dev/null || true
  pkill -f Rakshak 2>/dev/null || true
  sudo pkill -x coredns 2>/dev/null || true
  sudo launchctl bootout system /Library/LaunchDaemons/com.rakshak.daemon.plist 2>/dev/null || true
  sudo rm -f /Library/LaunchDaemons/com.rakshak.daemon.plist
  echo "User data: ~/Library/Application Support/Rakshak (remove manually if desired)"
fi

if [[ "$(uname)" == "Linux" ]]; then
  echo "Run from linux/: docker compose down -v"
fi

echo "Windows: run uninstall-windows.ps1 as Administrator"
