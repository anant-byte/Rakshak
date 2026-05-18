import Foundation
import CryptoKit

/// Shared secret for localhost daemon API — file mode 0600, not in UserDefaults.
public enum DaemonAuthToken {
    public static let headerName = "X-Rakshak-Token"
    private static let fileName = "daemon.token"

    public static var path: URL {
        RakshakPaths.appSupport.appendingPathComponent(fileName)
    }

    /// Load existing token or create a new 32-byte hex secret.
    public static func loadOrCreate() throws -> String {
        if let existing = try? String(contentsOf: path, encoding: .utf8) {
            let trimmed = existing.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count >= 32 { return trimmed }
        }
        let token = randomToken()
        try persist(token)
        return token
    }

    public static func load() -> String? {
        guard let raw = try? String(contentsOf: path, encoding: .utf8) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 32 ? trimmed : nil
    }

    public static func matches(provided: String, expected: String) -> Bool {
        let a = Data(provided.utf8)
        let b = Data(expected.utf8)
        guard a.count == b.count, !a.isEmpty else { return false }
        return a.withUnsafeBytes { ap in
            b.withUnsafeBytes { bp in
                zip(ap, bp).reduce(0) { $0 | UInt8($1.0 ^ $1.1) } == 0
            }
        }
    }

    private static func randomToken() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func persist(_ token: String) throws {
        try RakshakPaths.ensureDirectories()
        try token.write(to: path, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path.path)
    }
}
