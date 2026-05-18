import Foundation
import RakshakCore
import os

/// Manages local DNS sinkhole — writes blocklists + Corefile, controls DNS process on :53.
public final class DNSEngine: @unchecked Sendable {
    private let log = Logger(subsystem: "com.rakshak.dns", category: "engine")
    private var process: Process?
    private let parser = BlocklistParser()
    private let queue = DispatchQueue(label: "com.rakshak.dns", qos: .userInitiated)

    public private(set) var isRunning = false
    public private(set) var domainCount = 0

    public init() {}

    /// Bundled + user blocklists under Application Support
    public func rebuildBlocklist(settings: AppSettings) throws -> Int {
        try queue.sync {
            try rebuildBlocklistLocked(settings: settings)
        }
    }

    private func rebuildBlocklistLocked(settings: AppSettings) throws -> Int {
            try RakshakPaths.ensureDirectories()
            var files: [URL] = []
            let bundled = RakshakPaths.bundledBlocklists
            if let items = try? FileManager.default.contentsOfDirectory(at: bundled, includingPropertiesForKeys: nil) {
                files.append(contentsOf: items.filter { $0.pathExtension == "txt" || $0.lastPathComponent.contains("hosts") })
            }
            let userDir = RakshakPaths.blocklists
            if let items = try? FileManager.default.contentsOfDirectory(at: userDir, includingPropertiesForKeys: nil) {
                files.append(contentsOf: items.filter { $0.lastPathComponent.hasSuffix(".txt") })
            }
            var allow = Set<String>()
            if FileManager.default.fileExists(atPath: RakshakPaths.allowHosts.path),
               let a = try? parser.parseFile(at: RakshakPaths.allowHosts) {
                allow = a
            }
            let domains = parser.merge(files: files, allowlist: allow)
            let tmp = RakshakPaths.blockedHosts.appendingPathExtension("tmp")
            try parser.writeHostsFile(domains: domains, to: tmp)
            _ = try FileManager.default.replaceItemAt(RakshakPaths.blockedHosts, withItemAt: tmp)
            try writeCorefile()
            domainCount = domains.count
            log.info("Blocklist rebuilt: \(domains.count) domains")
            return domains.count
    }

    /// When `RAKSHAK_EXTERNAL_COREDNS=1`, the daemon only writes Corefile + blocklists; CoreDNS must be started separately (e.g. `sudo coredns`) because binding :53 requires root on macOS.
    private var usesExternalCoreDNS: Bool {
        ProcessInfo.processInfo.environment["RAKSHAK_EXTERNAL_COREDNS"] == "1"
    }

    public func start() throws {
        try queue.sync {
            try stopLocked()
            _ = try rebuildBlocklistLocked(settings: AppSettings())
            if usesExternalCoreDNS {
                isRunning = FileManager.default.fileExists(atPath: RakshakPaths.corefile.path)
                log.info("External CoreDNS mode — run: sudo coredns -dns.port=53 -conf \(RakshakPaths.corefile.path)")
                return
            }
            try launchCoreDNSLocked()
        }
    }

    public func stop() throws {
        try queue.sync {
            try stopLocked()
        }
    }

    /// Restart CoreDNS if the child process exited unexpectedly.
    public func ensureRunning(settings: AppSettings) {
        queue.async { [weak self] in
            guard let self else { return }
            if self.usesExternalCoreDNS {
                self.isRunning = FileManager.default.fileExists(atPath: RakshakPaths.corefile.path)
                return
            }
            if let proc = self.process, proc.isRunning {
                self.isRunning = true
                return
            }
            if self.process != nil {
                self.log.warning("CoreDNS exited — restarting")
                self.process = nil
            }
            do {
                try self.launchCoreDNSLocked()
            } catch {
                self.log.error("CoreDNS restart failed: \(error.localizedDescription)")
                self.isRunning = false
            }
        }
    }

    private func launchCoreDNSLocked() throws {
        let coreDNS = resolveCoreDNSBinary()
        guard FileManager.default.fileExists(atPath: coreDNS) else {
            throw DNSError.binaryNotFound(coreDNS)
        }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: coreDNS)
        proc.arguments = ["-dns.port", "53", "-conf", RakshakPaths.corefile.path]
        proc.currentDirectoryURL = RakshakPaths.appSupport
        let out = RakshakPaths.logs.appendingPathComponent("coredns.log")
        FileManager.default.createFile(atPath: out.path, contents: nil)
        proc.standardOutput = try? FileHandle(forWritingTo: out)
        proc.standardError = proc.standardOutput
        try proc.run()
        process = proc
        isRunning = true
        log.info("CoreDNS started on :53")
    }

    private func stopLocked() throws {
        if let proc = process, proc.isRunning {
            proc.terminate()
            proc.waitUntilExit()
        }
        process = nil
        isRunning = false
    }

    private func resolveCoreDNSBinary() -> String {
        let candidates = [
            "/opt/rakshak/bin/coredns",
            "/usr/local/bin/coredns",
            "/opt/homebrew/bin/coredns",
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) } ?? candidates[0]
    }

    private func writeCorefile() throws {
        let corefile = """
        . {
            bind 0.0.0.0
            bufsize 1232
            hosts \(RakshakPaths.blockedHosts.path) {
                fallthrough
                reload 5m
            }
            hosts \(RakshakPaths.allowHosts.path) {
                fallthrough
            }
            cache 300
            forward . 1.1.1.1 1.0.0.1 8.8.8.8
            log
            errors
        }
        """
        try corefile.write(to: RakshakPaths.corefile, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: RakshakPaths.corefile.path)
    }

    public enum DNSError: LocalizedError {
        case binaryNotFound(String)
        public var errorDescription: String? {
            switch self {
            case .binaryNotFound(let p): return "CoreDNS not found at \(p). Run: brew install coredns"
            }
        }
    }
}
