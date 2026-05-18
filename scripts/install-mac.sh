#!/usr/bin/env bash
# Install Rakshak on macOS — wrapper for macos/scripts/install.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/macos/scripts/install.sh"
