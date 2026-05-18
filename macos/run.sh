#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SUPPORT="$HOME/Library/Application Support/Rakshak"
BIN="$ROOT/.build/release"
APP="$ROOT/Rakshak.app"
DAEMON_PID="$SUPPORT/daemon.pid"

mkdir -p "$SUPPORT/Blocklists" "$SUPPORT/Logs" "$SUPPORT/pf"
touch "$SUPPORT/Blocklists/allow.hosts"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v coredns >/dev/null 2>&1; then
  echo "Installing CoreDNS (one-time)..."
  brew install coredns
fi

if [[ ! -x "$BIN/Rakshak" ]] || [[ ! -x "$BIN/RakshakDaemon" ]]; then
  echo "Building Rakshak (one-time)..."
  cd "$ROOT" && swift build -c release
fi

cp -f "$ROOT/Sources/RakshakApp/Resources/Blocklists/builtin-ads.txt" "$SUPPORT/Blocklists/builtin-ads.txt" 2>/dev/null || true

# macOS GUI must run inside a .app bundle (raw binary crashes with NSException)
mkdir -p "$APP/Contents/MacOS"
cp -f "$BIN/Rakshak" "$APP/Contents/MacOS/Rakshak"
chmod +x "$APP/Contents/MacOS/Rakshak"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Rakshak</string>
    <key>CFBundleIdentifier</key>
    <string>com.rakshak.mac</string>
    <key>CFBundleName</key>
    <string>Rakshak</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
PLIST

pkill -f RakshakDaemon 2>/dev/null || true
if [[ -f "$DAEMON_PID" ]]; then kill "$(cat "$DAEMON_PID")" 2>/dev/null || true; fi

# Daemon must NOT spawn CoreDNS on :53 (non-root bind fails). run.sh starts CoreDNS with sudo.
export RAKSHAK_EXTERNAL_COREDNS=1
"$BIN/RakshakDaemon" >> "$SUPPORT/Logs/daemon.log" 2>&1 &
echo $! > "$DAEMON_PID"
sleep 2

TOKEN="$(tr -d '[:space:]' < "$SUPPORT/daemon.token" 2>/dev/null || true)"
if [[ -n "$TOKEN" ]]; then
  AUTH=(-H "X-Rakshak-Token: $TOKEN")
  curl -sf "${AUTH[@]}" -X POST http://127.0.0.1:9847/api/v1/blocklist/rebuild >/dev/null || true
  curl -sf "${AUTH[@]}" -X POST http://127.0.0.1:9847/api/v1/protection/enable >/dev/null || true
fi

if [[ -f "$SUPPORT/Corefile" ]]; then
  sudo pkill -x coredns 2>/dev/null || true
  sleep 1
  sudo "$(command -v coredns)" -dns.port=53 -conf "$SUPPORT/Corefile" >> "$SUPPORT/Logs/coredns.log" 2>&1 &
fi

open -a "$APP"

echo "Rakshak is running."
echo "  App:    $APP"
echo "  API:    http://127.0.0.1:9847/api/v1/state"
