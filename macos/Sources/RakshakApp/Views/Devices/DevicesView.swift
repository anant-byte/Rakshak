import SwiftUI
import RakshakCore

struct DevicesView: View {
    @Environment(AppViewModel.self) private var app

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if app.devices.isEmpty {
                    ContentUnavailableView(
                        "No devices yet",
                        systemImage: "desktopcomputer",
                        description: Text("Devices appear when they use your network DNS.")
                    )
                    .padding(.top, 60)
                } else {
                    ForEach(app.devices) { device in
                        DeviceCard(device: device)
                    }
                }
            }
            .padding(RakshakTheme.padding)
        }
        .navigationTitle("Devices")
        .toolbar {
            Button {
                Task { await DaemonAPIClient().post("/api/v1/devices/scan") }
            } label: {
                Label("Scan", systemImage: "arrow.clockwise")
            }
        }
    }
}

struct DeviceCard: View {
    let device: NetworkDevice

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: device.deviceType.icon)
                .font(.system(size: 28))
                .foregroundStyle(RakshakTheme.accentFallback)
                .frame(width: 48, height: 48)
                .background(Circle().fill(RakshakTheme.accentFallback.opacity(0.12)))
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(RakshakTheme.headline)
                Text(device.ipAddress)
                    .font(RakshakTheme.caption)
                    .foregroundStyle(.secondary)
                Text(device.macAddress)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge
                Text(device.lastSeen, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .rakshakCard()
    }

    @ViewBuilder
    private var statusBadge: some View {
        if device.isBlocked {
            Label("Blocked", systemImage: "nosign")
                .font(.caption.weight(.medium))
                .foregroundStyle(RakshakTheme.danger)
        } else if device.isTrusted {
            Label("Trusted", systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(RakshakTheme.success)
        } else {
            Label("Protected", systemImage: "shield.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(RakshakTheme.accentFallback)
        }
    }
}
