import Foundation
import RakshakCore

/// Parses hosts-format and plain-domain blocklists — fully offline.
public struct BlocklistParser: Sendable {
    public init() {}

    public func parseFile(at url: URL) throws -> Set<String> {
        let text = try String(contentsOf: url, encoding: .utf8)
        return parse(text: text)
    }

    public func parse(text: String) -> Set<String> {
        var domains = Set<String>()
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            if let d = extractDomain(from: trimmed) {
                domains.insert(d)
            }
        }
        return domains
    }

    public func merge(files: [URL], allowlist: Set<String> = []) -> [String] {
        var all = Set<String>()
        for file in files where FileManager.default.fileExists(atPath: file.path) {
            if let parsed = try? parseFile(at: file) {
                all.formUnion(parsed)
            }
        }
        for a in allowlist { all.remove(a) }
        return all.sorted()
    }

    public func writeHostsFile(domains: [String], to url: URL, sinkhole: String = "0.0.0.0") throws {
        var lines = ["# Rakshak generated \(ISO8601DateFormatter().string(from: Date()))", "# domains: \(domains.count)"]
        lines.reserveCapacity(domains.count + 2)
        for d in domains {
            lines.append("\(sinkhole) \(d)")
        }
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    private func extractDomain(from line: String) -> String? {
        let parts = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard !parts.isEmpty else { return nil }
        let candidate: String
        if parts.count >= 2, parts[0].first?.isNumber == true {
            candidate = parts[1]
        } else {
            candidate = parts[0]
        }
        var d = candidate.lowercased()
        if d.hasPrefix("*.") { d = String(d.dropFirst(2)) }
        if d.contains("://") || d.contains(" ") || d.contains("\n") || d.contains("\t") { return nil }
        guard d.contains("."), d.count <= 253, !d.hasPrefix("#"), !d.hasPrefix(".") else { return nil }
        let labelRe = #"^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+$"#
        guard d.range(of: labelRe, options: .regularExpression) != nil else { return nil }
        return d
    }
}
