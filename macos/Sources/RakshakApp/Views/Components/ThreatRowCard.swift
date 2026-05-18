import SwiftUI
import RakshakCore

struct ThreatRowCard: View {
    let threat: ThreatEvent

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: threat.category.icon)
                .font(.title3)
                .foregroundStyle(threat.wasBlocked ? RakshakTheme.danger : RakshakTheme.warning)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(threat.domain)
                    .font(RakshakTheme.headline)
                    .lineLimit(1)
                Text("\(threat.category.displayName) · \(threat.clientName.isEmpty ? threat.clientIP : threat.clientName)")
                    .font(RakshakTheme.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(threat.wasBlocked ? "Blocked" : "Allowed")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(threat.wasBlocked ? RakshakTheme.danger.opacity(0.15) : Color.secondary.opacity(0.12)))
                .foregroundStyle(threat.wasBlocked ? RakshakTheme.danger : .secondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(RakshakTheme.cardFallback))
    }
}
