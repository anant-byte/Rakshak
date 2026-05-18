# DNS engine

RAKSHAK uses [CoreDNS](https://coredns.io/) as the LAN DNS sinkhole on all platforms.

## Corefile template

```
. {
    bind 0.0.0.0
    hosts BLOCKED_HOSTS_PATH {
        fallthrough
        reload 5m
    }
    hosts ALLOW_HOSTS_PATH {
        fallthrough
    }
    cache 300
    forward . UPSTREAM_RESOLVERS
    log
    errors
}
```

## Linux appliance

CoreDNS runs in Docker — see `linux/dns/coredns/Corefile` and `linux/docker-compose.yml`.

## macOS

Built by `macos/Sources/RakshakDNS/DNSEngine.swift`. Port 53 requires root (`sudo coredns` or SMJobBless helper).

## Windows

Install CoreDNS to `C:\Program Files\Rakshak\coredns.exe`. Disable the **DNS Client** service before binding :53 — see [docs/windows-setup.md](../docs/windows-setup.md).

Set `COREDNS_PATH` if CoreDNS is not on `PATH`.
