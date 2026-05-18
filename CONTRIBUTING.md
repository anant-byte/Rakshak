# Contributing to RAKSHAK

Thank you for helping improve network-wide DNS protection for home LANs.

## Development setup

### Linux appliance (Docker)

```bash
cd linux
cp ../.env.example .env
# Edit .env — set RAKSHAK_LAN_IP, passwords, secrets
docker compose up -d --build
```

### macOS (Swift)

Requirements: macOS 14+, Xcode 15+ or Swift 5.9+, Homebrew, CoreDNS.

```bash
cd macos
swift build
./run.sh
```

### Windows (Tauri)

Requirements: Node 20+, Rust stable, Visual Studio Build Tools, WebView2.

```bash
cd windows
npm install
npm run tauri dev
```

### Core (Rust)

```bash
cd core
cargo test
```

## Pull requests

1. Fork and create a feature branch from `main`.
2. Keep changes focused; one concern per PR.
3. Run CI checks locally when possible:
   - `cd macos && swift build`
   - `cd linux/backend && go test ./...`
   - `cd linux/frontend && npm ci && npm run build`
   - `cd core && cargo test`
   - `cd windows && npm run build`
4. Update docs if behavior or config changes.
5. Do not commit secrets, `.env`, build artifacts, or personal paths.

## Code style

- **Go**: `gofmt`, idiomatic Gin/GORM patterns in `linux/backend`
- **Swift**: match existing module layout under `macos/Sources`
- **TypeScript/React**: Next.js app in `linux/frontend`, Tauri UI in `windows/src`
- **Rust**: `rustfmt` for `core/` and `windows/src-tauri`

## Security

See [SECURITY.md](SECURITY.md). Report vulnerabilities privately.

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
