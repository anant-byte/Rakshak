import Foundation
import RakshakCore
import os

/// pf firewall integration — force LAN DNS to this Mac, block DoT bypass.
public final class PFManager: @unchecked Sendable {
    private let log = Logger(subsystem: "com.rakshak.firewall", category: "pf")
    public private(set) var isEnabled = false

    private static let ipv4Pattern = #"^(?:25[0-5]|2[0-4]\d|[01]?\d\d?)(?:\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?)){3}$"#
    private static let ifacePattern = #"^[a-zA-Z][a-zA-Z0-9]{0,15}$"#

    public init() {}

    public var rulesFile: URL {
        RakshakPaths.appSupport.appendingPathComponent("pf/rakshak.conf")
    }

    public func writeRules(lanInterface: String, rakshakIP: String, forceDNS: Bool) throws {
        guard Self.isValidIPv4(rakshakIP) else {
            throw PFError.invalidInput("rakshak IP")
        }
        guard Self.isValidInterface(lanInterface) else {
            throw PFError.invalidInput("LAN interface")
        }
        try FileManager.default.createDirectory(
            at: rulesFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        var rules = """
        # Rakshak pf anchor — force DNS to local sinkhole
        rakshak_ip = "\(rakshakIP)"
        lan_if = "\(lanInterface)"

        """
        if forceDNS {
            rules += """
            block drop quick proto udp from any to !$rakshak_ip port 53
            block drop quick proto tcp from any to !$rakshak_ip port 53
            block drop quick proto tcp from any to any port 853

            """
        }
        rules += "pass\n"
        try rules.write(to: rulesFile, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: rulesFile.path)
    }

    /// Requires root — call from privileged helper (SMJobBless), not from sandboxed app.
    public func apply() throws {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/sbin/pfctl")
        proc.arguments = ["-ef", rulesFile.path]
        try proc.run()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { throw PFError.applyFailed(proc.terminationStatus) }
        isEnabled = true
        log.info("pf rules applied")
    }

    public func disable() throws {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/sbin/pfctl")
        proc.arguments = ["-d"]
        try proc.run()
        proc.waitUntilExit()
        isEnabled = false
    }

    private static func isValidIPv4(_ ip: String) -> Bool {
        ip.range(of: ipv4Pattern, options: .regularExpression) != nil
    }

    private static func isValidInterface(_ name: String) -> Bool {
        name.range(of: ifacePattern, options: .regularExpression) != nil
    }

    public enum PFError: LocalizedError {
        case invalidInput(String)
        case applyFailed(Int32)
        public var errorDescription: String? {
            switch self {
            case .invalidInput(let field): return "Invalid \(field) for pf rules"
            case .applyFailed(let code): return "pfctl failed with status \(code). Root privileges required."
            }
        }
    }
}
