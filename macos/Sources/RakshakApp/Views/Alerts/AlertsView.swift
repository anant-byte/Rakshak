import SwiftUI
import RakshakCore

struct AlertsView: View {
    @Environment(AppViewModel.self) private var app

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if app.alerts.isEmpty {
                    ContentUnavailableView(
                        "All clear",
                        systemImage: "bell.slash",
                        description: Text("We'll notify you about new devices and risks.")
                    )
                    .padding(.top, 60)
                } else {
                    ForEach(app.alerts) { alert in
                        AlertCard(alert: alert)
                    }
                }
            }
            .padding(RakshakTheme.padding)
        }
        .navigationTitle("Alerts")
    }
}

struct AlertCard: View {
    let alert: SecurityAlert

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(severityColor.opacity(0.2))
                .frame(width: 10, height: 10)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 6) {
                Text(alert.title)
                    .font(RakshakTheme.headline)
                Text(alert.message)
                    .font(RakshakTheme.body)
                    .foregroundStyle(.secondary)
                Text(alert.timestamp, style: .relative)
                    .font(RakshakTheme.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            if !alert.isRead {
                Circle().fill(RakshakTheme.accentFallback).frame(width: 8, height: 8)
            }
        }
        .rakshakCard()
        .opacity(alert.isRead ? 0.75 : 1)
    }

    private var severityColor: Color {
        switch alert.severity {
        case .info: return RakshakTheme.accentFallback
        case .warning: return RakshakTheme.warning
        case .critical: return RakshakTheme.danger
        }
    }
}
