import SwiftUI
import Charts
import RakshakCore

struct DashboardView: View {
    @Environment(AppViewModel.self) private var app
    @State private var animateShield = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RakshakTheme.padding) {
                header
                protectionToggle
                statsGrid
                if !app.threats.isEmpty {
                    recentThreatsSection
                }
                routerHint
            }
            .padding(RakshakTheme.padding)
        }
        .navigationTitle("Home")
        .onAppear {
            withAnimation(RakshakTheme.spring) { animateShield = true }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                RakshakTheme.accentFallback.opacity(0.25),
                                RakshakTheme.accentFallback.opacity(0.05),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                Image(systemName: app.daemonState.stats.protectionEnabled ? "shield.checkered" : "shield.slash")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(app.daemonState.stats.protectionEnabled ? RakshakTheme.accentFallback : .secondary)
                    .scaleEffect(animateShield ? 1 : 0.85)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(app.daemonState.stats.protectionEnabled ? "Network protected" : "Protection paused")
                    .font(RakshakTheme.title)
                Text(app.daemonState.message)
                    .font(RakshakTheme.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var protectionToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Whole-home DNS protection")
                    .font(RakshakTheme.headline)
                Text("Blocks ads, malware, and scams for every device on Wi‑Fi")
                    .font(RakshakTheme.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { app.daemonState.stats.protectionEnabled },
                set: { enabled in
                    Task {
                        if enabled { await app.enableProtection() }
                        else { await app.disableProtection() }
                    }
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .rakshakCard()
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: RakshakTheme.spacing) {
            StatCard(title: "Blocked today", value: "\(app.daemonState.stats.blockedToday)", icon: "hand.raised.fill", tint: .orange)
            StatCard(title: "Devices", value: "\(app.daemonState.stats.activeDevices)", icon: "wifi", tint: RakshakTheme.accentFallback)
            StatCard(title: "Blocklist", value: formattedDomains, icon: "list.bullet.rectangle", tint: .purple)
        }
    }

    private var formattedDomains: String {
        let n = app.daemonState.stats.blocklistDomains
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1000 { return String(format: "%.0fK", Double(n) / 1000) }
        return "\(n)"
    }

    private var recentThreatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent threats")
                .font(RakshakTheme.headline)
            ForEach(app.threats.prefix(5)) { threat in
                ThreatRowCard(threat: threat)
            }
        }
    }

    private var routerHint: some View {
        Group {
            if !app.settings.routerDNSConfigured, let ip = Optional(app.daemonState.stats.lanIPAddress), !ip.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.router")
                        .font(.title2)
                        .foregroundStyle(RakshakTheme.accentFallback)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set router DNS to \(ip)")
                            .font(RakshakTheme.headline)
                        Text("This protects phones, TVs, and guests — not just this Mac.")
                            .font(RakshakTheme.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Guide") { app.selectedTab = .settings }
                        .buttonStyle(.borderedProminent)
                }
                .rakshakCard()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(RakshakTheme.stat)
                .contentTransition(.numericText())
            Text(title)
                .font(RakshakTheme.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rakshakCard()
    }
}
