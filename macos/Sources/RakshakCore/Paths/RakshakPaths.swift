import Foundation

public enum RakshakPaths {
    public static var appSupport: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Rakshak", isDirectory: true)
    }

    public static var blocklists: URL { appSupport.appendingPathComponent("Blocklists", isDirectory: true) }
    public static var blockedHosts: URL { blocklists.appendingPathComponent("blocked.hosts") }
    public static var allowHosts: URL { blocklists.appendingPathComponent("allow.hosts") }
    public static var corefile: URL { appSupport.appendingPathComponent("Corefile") }
    public static var settings: URL { appSupport.appendingPathComponent("settings.json") }
    public static var logs: URL { appSupport.appendingPathComponent("Logs", isDirectory: true) }
    public static var bundledBlocklists: URL {
        Bundle.main.resourceURL?.appendingPathComponent("Blocklists") ?? blocklists
    }

    public static func ensureDirectories() throws {
        let fm = FileManager.default
        for url in [appSupport, blocklists, logs] {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
            try fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
        }
    }
}
