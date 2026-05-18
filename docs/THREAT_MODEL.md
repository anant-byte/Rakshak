# RAKSHAK Threat Model

## Assets

- DNS integrity for all household devices
- Admin credentials and query logs
- Blocklist integrity

## Trust boundaries

| Trusted | Untrusted |
|---------|-----------|
| RAKSHAK host, admin LAN | Internet, guest Wi-Fi (if not segmented) |
| Curated OSS feed TLS | Compromised feed CDN (mitigate: checksum audit) |

## Threats & mitigations

| Threat | Impact | Mitigation |
|--------|--------|------------|
| Client uses 8.8.8.8 directly | Bypass filter | nftables force-DNS |
| Client uses DoH/DoT | Bypass | Block 853; future SNI proxy |
| Compromised IoT | Lateral movement | DNS still blocks C2 domains |
| Fake blocklist feed | Wrong blocks | Pin URLs; verify counts; audit log |
| Admin password guess | Policy change | bcrypt, rate limit (v1.1), strong password |
| RAKSHAK host compromise | Full MITM | Harden SSH, auto-updates, minimal attack surface |
| DNS cache poisoning | Redirects | DNSSEC via Unbound |
| Elderly clicks phishing | Account takeover | DNS blocks phishing domains before browser |

## Out of scope (v1)

- TLS interception / HTTPS content inspection
- VPN egress on phones (user must disable or split-tunnel)
- Encrypted DNS inside apps with certificate pinning

## Fail modes

- **Fail-closed**: preferred — no DNS beats silent insecure DNS
- **Fail-open**: only for availability-critical networks; documented in watchdog script
