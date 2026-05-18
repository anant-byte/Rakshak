# Security Policy

## Supported versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a vulnerability

**Please do not open public GitHub issues for security vulnerabilities.**

1. Email the maintainers via GitHub private vulnerability reporting on [github.com/anant-byte/rakshak](https://github.com/anant-byte/rakshak) (Security → Report a vulnerability), **or**
2. Open a minimal advisory request if private reporting is unavailable.

Include:

- Affected component (macOS app, Windows app, Linux/Docker stack)
- Steps to reproduce
- Impact assessment
- Suggested fix (optional)

We aim to acknowledge reports within **72 hours** and provide a fix or mitigation plan within **14 days** for confirmed issues.

## Scope

In scope:

- Remote code execution via admin API, local daemon API, or DNS path
- Authentication bypass on control plane or local daemon
- Privilege escalation in privileged helpers / Windows service

Out of scope:

- Social engineering, physical access
- Attacks requiring the administrator to disable TLS or expose the API to the public internet
- Third-party blocklist feed content (report to feed maintainers)

## Safe defaults

- Linux: set strong `RAKSHAK_SECRET_KEY` and `RAKSHAK_INTERNAL_SECRET` before production use.
- macOS/Windows: local daemon API binds to loopback and requires `daemon.token`.
- Never commit `.env`, `daemon.token`, or database files.
