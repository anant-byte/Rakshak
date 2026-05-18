# Database schema

RAKSHAK uses SQLite on macOS and Windows desktop apps, and SQLite or Postgres on the Linux appliance.

## macOS schema

See `macos/Sources/RakshakCore/Database/RakshakDatabase.swift` — tables: `devices`, `threat_events`, `alerts`, `dns_query_logs`.

## Linux schema

See `linux/backend/internal/models/models.go` — GORM models with users, devices, policies, blocklist feeds, query logs.

## Portable path

Desktop apps store the database at:

- **macOS**: `~/Library/Application Support/Rakshak/rakshak.db`
- **Windows**: `%APPDATA%\Rakshak\rakshak.db` (via `rakshak-core::paths::database_path()`)

Never commit `*.db` files to git.
