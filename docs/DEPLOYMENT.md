# RAKSHAK Deployment Guide

## Prerequisites

- Linux host (Debian/Ubuntu/Arch) or Raspberry Pi 4 (2GB+)
- Docker Engine 24+ and Compose v2
- Static LAN IP for RAKSHAK host
- Router admin access

## Step-by-step

### 1. Prepare host

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y docker.io docker-compose-plugin git openssl

# Static IP (netplan example) — set RAKSHAK_LAN_IP to match
```

### 2. Clone and configure

```bash
git clone <your-repo> /opt/rakshak && cd /opt/rakshak
cp .env.example .env
nano .env   # RAKSHAK_LAN_IP, RAKSHAK_ADMIN_PASSWORD, RAKSHAK_SECRET_KEY
```

Generate secret:

```bash
openssl rand -hex 32
```

### 3. Install

```bash
chmod +x scripts/*.sh scripts/firewall/*.sh scripts/monitor/*.sh
./scripts/install.sh
```

### 4. Router DNS

```bash
./scripts/configure-router.sh
```

### 5. Verify protection

```bash
dig @$(grep RAKSHAK_LAN_IP .env | cut -d= -f2) doubleclick.net +short
# → 0.0.0.0

dig @$(grep RAKSHAK_LAN_IP .env | cut -d= -f2) cloudflare.com +short
# → real IPs
```

### 6. HTTPS trust (local)

Add to `/etc/hosts` on admin machine:

```
192.168.1.10 rakshak.lan
```

Trust Caddy local CA (browser will prompt on first visit).

### 7. Optional force-DNS

```bash
RAKSHAK_FORCE_DNS=true
sudo ./scripts/firewall/apply-nftables.sh
```

### 8. Monitoring profile

```bash
docker compose --profile monitoring up -d
# Grafana: configure reverse proxy or port-forward 3001
```

## Updates

```bash
git pull
docker compose build --pull
docker compose up -d
./scripts/update-blocklists.sh
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Port 53 in use | `sudo systemctl stop systemd-resolved`; bind Docker to LAN IP only |
| No blocks | Check `docker volume inspect` blocklists; run blocklist update from UI |
| Slow DNS | Increase cache TTL; use SSD; reduce feed count |
| iPhone DoH bypass | Enable nftables force-DNS |
