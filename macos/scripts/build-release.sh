#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
swift build -c release
echo "Binaries:"
ls -la .build/release/Rakshak .build/release/RakshakDaemon
