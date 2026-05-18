# Rakshak Privileged Helper

Port **53** and **pfctl** require root on macOS. Production flow:

## SMJobBless helper (`com.rakshak.helper`)

| Capability | Why |
|------------|-----|
| Bind UDP/TCP :53 | LAN DNS sinkhole |
| `pfctl -ef` | Force-DNS (block 8.8.8.8 bypass) |
| Start/stop CoreDNS | Child process as root |

## XPC protocol (stub)

```swift
@objc protocol RakshakHelperProtocol {
    func startDNS(reply: @escaping (Error?) -> Void)
    func stopDNS(reply: @escaping (Error?) -> Void)
    func applyFirewall(rulesPath: String, reply: @escaping (Error?) -> Void)
}
```

## Security

- Code-signed app + helper with same Team ID
- `SMPrivilegedExecutables` in app Info.plist
- Helper validates caller bundle ID
- No network access in helper

## Development workaround

```bash
sudo /opt/homebrew/bin/coredns -dns.port=53 -conf ~/Library/Application\ Support/Rakshak/Corefile
```

Or run Docker-based RAKSHAK Linux stack on a dedicated appliance.
