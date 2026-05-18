import SwiftUI
import RakshakCore

struct SettingsView: View {
    @Environment(AppViewModel.self) private var app

    var body: some View {
        Form {
            Section("Protection") {
                Toggle("Block ads & trackers", isOn: bind(\.blockAds))
                Toggle("Block malware", isOn: bind(\.blockMalware))
                Toggle("Block phishing & scams", isOn: bind(\.blockPhishing))
                Toggle("Block crypto miners", isOn: bind(\.blockMiners))
                Toggle("Force DNS (pf firewall)", isOn: bind(\.forceDNS))
            }
            Section("Notifications") {
                Toggle("Alert on blocked threats", isOn: bind(\.notifyOnThreat))
                Toggle("Menu bar icon", isOn: bind(\.showMenuBarExtra))
            }
            Section("Network") {
                LabeledContent("This Mac's LAN IP", value: app.daemonState.stats.lanIPAddress.isEmpty ? "—" : app.daemonState.stats.lanIPAddress)
                LabeledContent("DNS service", value: app.daemonState.stats.dnsRunning ? "Running" : "Stopped")
                LabeledContent("Blocklist size", value: "\(app.daemonState.stats.blocklistDomains) domains")
            }
            Section("Router setup") {
                Text(routerHelp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Copy DNS IP") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(app.daemonState.stats.lanIPAddress, forType: .string)
                }
            }
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Data", value: "100% on this Mac")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .onChange(of: app.settings.blockAds) { _, _ in
            Task { @MainActor in app.saveSettings() }
        }
    }

    private var routerHelp: String {
        "Set your router's DHCP DNS to this Mac's IP so all devices are protected."
    }

    @MainActor
    private func bind(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { @MainActor in app.settings[keyPath: keyPath] },
            set: { @MainActor newValue in
                app.settings[keyPath: keyPath] = newValue
                app.saveSettings()
            }
        )
    }
}

import AppKit
