# RAKSHAK Linux appliance

Docker Compose stack: CoreDNS + Unbound + Go API + Next.js + Caddy.

```bash
cp ../.env.example .env
# Edit RAKSHAK_LAN_IP, passwords, secrets
docker compose up -d --build
```

Or from repo root: `./scripts/install.sh`

See [docs/DEPLOYMENT.md](../docs/DEPLOYMENT.md) and [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md).
