import SwiftUI
import RakshakCore

struct OnboardingFlowView: View {
    @Environment(AppViewModel.self) private var app
    @State private var step = 0

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(step + 1), total: 4)
                .padding()
            TabView(selection: $step) {
                welcomeStep.tag(0)
                howItWorksStep.tag(1)
                routerStep.tag(2)
                doneStep.tag(3)
            }
            .tabViewStyle(.automatic)
            .animation(RakshakTheme.spring, value: step)
        }
        .frame(maxWidth: 560, maxHeight: 520)
    }

    private var welcomeStep: some View {
        OnboardingPage(
            icon: "shield.checkered",
            title: "Protect your whole home",
            message: "Rakshak runs on this Mac and filters bad domains for every phone, TV, and guest on your Wi‑Fi.",
            primary: "Continue",
            action: { step = 1 }
        )
    }

    private var howItWorksStep: some View {
        OnboardingPage(
            icon: "network",
            title: "Network-level blocking",
            message: "No apps to install on other devices. Your router sends DNS through this Mac — ads and malware never load.",
            primary: "Next",
            action: { step = 2 }
        )
    }

    private var routerStep: some View {
        VStack(spacing: 20) {
            OnboardingPage(
                icon: "wifi.router",
                title: "One router setting",
                message: routerInstructions,
                primary: "I've set DNS",
                action: { step = 3 }
            )
            if let ip = app.daemonState.stats.lanIPAddress.nilIfEmpty {
                Text("DNS address: \(ip)")
                    .font(.system(.title3, design: .monospaced))
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary))
            }
        }
    }

    private var routerInstructions: String {
        let ip = app.daemonState.stats.lanIPAddress.isEmpty ? "your Mac's IP" : app.daemonState.stats.lanIPAddress
        return """
        1. Open your router admin page
        2. Find DHCP or DNS settings
        3. Set DNS server to \(ip)
        4. Save and reconnect Wi‑Fi on phones
        """
    }

    private var doneStep: some View {
        OnboardingPage(
            icon: "checkmark.circle.fill",
            title: "You're set",
            message: "Protection starts automatically. Check Home anytime for blocked threats.",
            primary: "Open Rakshak",
            action: {
                Task { await app.enableProtection() }
                app.completeOnboarding(dnsConfigured: true)
            }
        )
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let message: String
    let primary: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(RakshakTheme.accentFallback)
            Text(title)
                .font(RakshakTheme.largeTitle)
                .multilineTextAlignment(.center)
            Text(message)
                .font(RakshakTheme.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button(primary, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(32)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
