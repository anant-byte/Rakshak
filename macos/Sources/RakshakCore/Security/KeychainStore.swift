import Foundation
import Security

/// Local-only secrets in Keychain — no cloud, no iCloud sync.
public enum KeychainStore {
    private static let service = "com.rakshak.mac"

    public static func save(password: String, account: String = "admin") throws {
        let data = Data(password.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
    }

    public static func load(account: String = "admin") -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    public static func verify(password: String, account: String = "admin") -> Bool {
        guard let stored = load(account: account) else { return false }
        let a = Data(password.utf8)
        let b = Data(stored.utf8)
        guard a.count == b.count, !a.isEmpty else { return false }
        return a.withUnsafeBytes { ap in
            b.withUnsafeBytes { bp in
                zip(ap, bp).reduce(0) { $0 | UInt8($1.0 ^ $1.1) } == 0
            }
        }
    }

    public enum KeychainError: Error {
        case saveFailed(OSStatus)
    }
}
