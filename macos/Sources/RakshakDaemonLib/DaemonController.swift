import Foundation
import RakshakCore
import RakshakDNS
import RakshakNetwork
import RakshakFirewall
import RakshakIPC
import os

/// Central daemon orchestrator — DNS, discovery, firewall, local API.
public final class DaemonController: @unchecked Sendable {
    private let log = Logger(subsystem: "com.rakshak.daemon", category: "controller")
    private let dns = DNSEngine()
    private let discovery = DeviceDiscovery()
    private let firewall = PFManager()
    private let api = LocalAPIServer()
    private let db = RakshakDatabase.shared

    private var settings = AppSettings()
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.rakshak.daemon.main")

    public private(set) var state = DaemonState(
        status: .stopped, message: "Initializing",
        stats: .empty, updatedAt: .now
    )

    public init() {
        loadSettings()
    }

    public func start() {
        queue.async { [weak self] in
            self?.run()
        }
    }

    private func run() {
        do {
            try RakshakPaths.ensureDirectories()
            copyBundledBlocklistsIfNeeded()
            api.stateProvider = { [weak self] in self?.state ?? DaemonState(status: .stopped, message: "", stats: .empty, updatedAt: .now) }
            api.onCommand = { [weak self] cmd in self?.handle(cmd) }
            try api.start()
            if settings.protectionEnabled {
                try enableProtection()
            }
            startPeriodicTasks()
            updateState(status: .running, message: "Protecting your network")
            log.info("Rakshak daemon running")
        } catch {
            updateState(status: .error, message: error.localizedDescription)
            log.error("Daemon failed: \(error.localizedDescription)")
        }
    }

    private func enableProtection() throws {
        updateState(status: .starting, message: "Starting DNS filter…")
        _ = try dns.rebuildBlocklist(settings: settings)
        try dns.start()
        if settings.forceDNS, let ip = discovery.localLANAddress() {
            let iface = discovery.primaryLANInterface() ?? "en0"
            try firewall.writeRules(lanInterface: iface, rakshakIP: ip, forceDNS: true)
            // pf apply requires root — privileged helper in production
            try? firewall.apply()
        }
        refreshStats()
    }

    private func disableProtection() throws {
        try dns.stop()
        try? firewall.disable()
        settings.protectionEnabled = false
        saveSettings()
        refreshStats()
    }

    private func handle(_ cmd: LocalAPIServer.APICommand) {
        queue.async { [weak self] in
            guard let self else { return }
            do {
                switch cmd {
                case .enableProtection:
                    self.settings.protectionEnabled = true
                    try self.enableProtection()
                case .disableProtection:
                    try self.disableProtection()
                case .rebuildBlocklist:
                    _ = try self.dns.rebuildBlocklist(settings: self.settings)
                    self.refreshStats()
                case .scanDevices:
                    self.scanDevices()
                }
                self.api.broadcast(event: "state", payload: ["status": self.state.status.rawValue])
            } catch {
                self.updateState(status: .error, message: error.localizedDescription)
            }
        }
    }

    private func startPeriodicTasks() {
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now() + 5, repeating: 60)
        timer?.setEventHandler { [weak self] in
            guard let self else { return }
            if self.settings.protectionEnabled {
                self.dns.ensureRunning(settings: self.settings)
            }
            self.scanDevices()
            self.refreshStats()
        }
        timer?.resume()
    }

    private func scanDevices() {
        let found = discovery.scanARP()
        let existingDevices = (try? db.fetchDevices()) ?? []
        let known = Set(existingDevices.map(\.macAddress))
        let byMAC = Dictionary(uniqueKeysWithValues: existingDevices.map { ($0.macAddress, $0) })
        for var d in found {
            let isNew = !known.contains(d.macAddress)
            if let existing = byMAC[d.macAddress] {
                d.id = existing.id
                d.isTrusted = existing.isTrusted
                d.isBlocked = existing.isBlocked
            }
            try? db.upsertDevice(d)
            if isNew { alertNewDevice(d) }
        }
    }

    private func alertNewDevice(_ d: NetworkDevice) {
        let alert = SecurityAlert(
            title: "New device on network",
            message: "\(d.name) (\(d.ipAddress)) joined your Wi‑Fi.",
            severity: .warning,
            actionLabel: "Review"
        )
        try? db.insertAlert(alert)
        api.broadcast(event: "alert", payload: ["title": alert.title])
    }

    private func refreshStats() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let blocked = (try? db.blockedCount(since: startOfDay)) ?? 0
        let devices = (try? db.fetchDevices()) ?? []
        state.stats = ProtectionStats(
            blockedToday: blocked,
            allowedToday: 0,
            activeDevices: devices.count,
            blocklistDomains: dns.domainCount,
            protectionEnabled: settings.protectionEnabled,
            dnsRunning: dns.isRunning || ProcessInfo.processInfo.environment["RAKSHAK_EXTERNAL_COREDNS"] == "1",
            firewallEnabled: firewall.isEnabled,
            lanIPAddress: discovery.localLANAddress() ?? ""
        )
        state.updatedAt = Date()
    }

    private func updateState(status: DaemonStatus, message: String) {
        state.status = status
        state.message = message
        state.updatedAt = Date()
        refreshStats()
    }

    private func loadSettings() {
        guard let data = try? Data(contentsOf: RakshakPaths.settings),
              let s = try? JSONDecoder().decode(AppSettings.self, from: data) else { return }
        settings = s
    }

    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: RakshakPaths.settings)
    }

    private func copyBundledBlocklistsIfNeeded() {
        let dest = RakshakPaths.blocklists
        let candidates = [
            "/opt/rakshak/Blocklists",
            Bundle.main.resourcePath.map { "\($0)/Blocklists" },
        ].compactMap { $0 }
        guard let bundlePath = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) else { return }
        let bundle = URL(fileURLWithPath: bundlePath)
        guard let files = try? FileManager.default.contentsOfDirectory(at: bundle, includingPropertiesForKeys: nil) else { return }
        for f in files {
            let target = dest.appendingPathComponent(f.lastPathComponent)
            if !FileManager.default.fileExists(atPath: target.path) {
                try? FileManager.default.copyItem(at: f, to: target)
            }
        }
    }
}
