import Foundation
import Network
import RakshakCore
import os

/// LAN device discovery via ARP + optional Bonjour browse.
public final class DeviceDiscovery: @unchecked Sendable {
    private let log = Logger(subsystem: "com.rakshak.network", category: "discovery")

    public init() {}

    /// Parse `arp -an` output (macOS)
    public func scanARP() -> [NetworkDevice] {
        let pipe = Pipe()
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/arp")
        proc.arguments = ["-an"]
        proc.standardOutput = pipe
        do {
            try proc.run()
            proc.waitUntilExit()
        } catch {
            log.error("arp failed: \(error.localizedDescription)")
            return []
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }
        return parseARPOutput(output)
    }

    public func parseARPOutput(_ output: String) -> [NetworkDevice] {
        // ? (192.168.1.42) at aa:bb:cc:dd:ee:ff on en0 ifscope [ethernet]
        var devices: [NetworkDevice] = []
        let pattern = #"\((\d+\.\d+\.\d+\.\d+)\) at ([0-9a-f:]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        for line in output.split(separator: "\n") {
            let s = String(line)
            let range = NSRange(s.startIndex..., in: s)
            guard let m = regex.firstMatch(in: s, range: range),
                  let ipRange = Range(m.range(at: 1), in: s),
                  let macRange = Range(m.range(at: 2), in: s) else { continue }
            let ip = String(s[ipRange])
            let mac = String(s[macRange])
            if mac == "(incomplete)" || mac == "ff:ff:ff:ff:ff:ff" { continue }
            let hostname = reverseDNS(ip) ?? "Device"
            devices.append(NetworkDevice(
                name: hostname,
                ipAddress: ip,
                macAddress: mac,
                deviceType: guessType(hostname: hostname)
            ))
        }
        return devices
    }

    /// Primary active interface (Wi‑Fi/Ethernet) for pf rules.
    public func primaryLANInterface() -> String? {
        let route = Process()
        route.executableURL = URL(fileURLWithPath: "/sbin/route")
        route.arguments = ["-n", "get", "default"]
        let pipe = Pipe()
        route.standardOutput = pipe
        guard (try? route.run()) != nil else { return nil }
        route.waitUntilExit()
        guard let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) else { return nil }
        for line in out.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2, parts[0].trimmingCharacters(in: .whitespaces) == "interface" {
                let name = parts[1].trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { return name }
            }
        }
        return nil
    }

    public func localLANAddress() -> String? {
        if let iface = primaryLANInterface(), let ip = address(forInterface: iface) {
            return ip
        }
        for iface in ["en0", "en1", "bridge0"] {
            if let ip = address(forInterface: iface), !ip.isEmpty, ip != "0.0.0.0" { return ip }
        }
        return nil
    }

    private func address(forInterface iface: String) -> String? {
        let pipe = Pipe()
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/ipconfig")
        proc.arguments = ["getifaddr", iface]
        proc.standardOutput = pipe
        guard (try? proc.run()) != nil else { return nil }
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let ip = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return ip.isEmpty || ip == "0.0.0.0" ? nil : ip
    }

    private func reverseDNS(_ ip: String) -> String? {
        var res = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        var addr = in_addr()
        guard ip.withCString({ inet_pton(AF_INET, $0, &addr) }) == 1 else { return nil }
        var sa = sockaddr_in()
        sa.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        sa.sin_family = sa_family_t(AF_INET)
        sa.sin_addr = addr
        let result = withUnsafePointer(to: &sa) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getnameinfo($0, socklen_t(MemoryLayout<sockaddr_in>.size), &res, socklen_t(res.count), nil, 0, 0)
            }
        }
        guard result == 0 else { return nil }
        let host = String(cString: res)
        return host.hasSuffix(".") ? String(host.dropLast()) : host
    }

    private func guessType(hostname: String) -> DeviceType {
        let h = hostname.lowercased()
        if h.contains("iphone") || h.contains("android") { return .phone }
        if h.contains("ipad") { return .tablet }
        if h.contains("macbook") || h.contains("imac") || h.contains("pc") { return .computer }
        if h.contains("tv") || h.contains("roku") { return .tv }
        return .unknown
    }
}
