import Foundation
import Observation
import RakshakCore
import UserNotifications

@MainActor
@Observable
final class AppViewModel {
    var daemonState = DaemonState(status: .stopped, message: "Connecting…", stats: .empty, updatedAt: .now)
    var devices: [NetworkDevice] = []
    var threats: [ThreatEvent] = []
    var alerts: [SecurityAlert] = []
    var settings = AppSettings()
    var isAuthenticated = false
    var showOnboarding = true
    var selectedTab: AppTab = .home

    private let client = DaemonAPIClient()
    private var pollTask: Task<Void, Never>?

    var menuBarIcon: String {
        daemonState.stats.protectionEnabled && daemonState.stats.dnsRunning
            ? "shield.checkered"
            : "shield.slash"
    }

    func onAppear() {
        showOnboarding = !settings.onboardingComplete
        isAuthenticated = KeychainStore.load() != nil
        if isAuthenticated {
            startPolling()
        }
    }

    func login(password: String) -> Bool {
        if KeychainStore.load() == nil {
            guard password.count >= 8 else { return false }
            try? KeychainStore.save(password: password)
        }
        guard KeychainStore.verify(password: password) else { return false }
        isAuthenticated = true
        startPolling()
        return true
    }

    func startPolling() {
        pollTask?.cancel()
        pollTask = Task { @MainActor in
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func refresh() async {
        if let state = await client.fetchState() {
            daemonState = state
        }
        devices = (try? RakshakDatabase.shared.fetchDevices()) ?? []
        threats = (try? RakshakDatabase.shared.fetchRecentThreats(limit: 30)) ?? []
        alerts = (try? RakshakDatabase.shared.fetchAlerts()) ?? []
    }

    func enableProtection() async {
        await client.post("/api/v1/protection/enable")
        await refresh()
    }

    func disableProtection() async {
        await client.post("/api/v1/protection/disable")
        await refresh()
    }

    func completeOnboarding(dnsConfigured: Bool) {
        settings.onboardingComplete = true
        settings.routerDNSConfigured = dnsConfigured
        saveSettings()
        showOnboarding = false
    }

    func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: RakshakPaths.settings)
    }

    func notifyThreat(_ threat: ThreatEvent) {
        guard settings.notifyOnThreat else { return }
        let content = UNMutableNotificationContent()
        content.title = "Threat blocked"
        content.body = "\(threat.domain) on \(threat.clientName.isEmpty ? threat.clientIP : threat.clientName)"
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: threat.id.uuidString, content: content, trigger: nil)
        )
    }
}

enum AppTab: String, CaseIterable {
    case home, devices, threats, alerts, settings

    var title: String {
        switch self {
        case .home: return "Home"
        case .devices: return "Devices"
        case .threats: return "Threats"
        case .alerts: return "Alerts"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .devices: return "desktopcomputer"
        case .threats: return "shield.lefthalf.filled"
        case .alerts: return "bell.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
