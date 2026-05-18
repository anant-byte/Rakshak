import SwiftUI
import Charts
import RakshakCore

struct ThreatsView: View {
    @Environment(AppViewModel.self) private var app

    var categoryCounts: [(ThreatCategory, Int)] {
        Dictionary(grouping: app.threats, by: \.category)
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RakshakTheme.padding) {
                if !categoryCounts.isEmpty {
                    chartSection
                }
                LazyVStack(spacing: 8) {
                    ForEach(app.threats) { threat in
                        ThreatRowCard(threat: threat)
                    }
                }
            }
            .padding(RakshakTheme.padding)
        }
        .navigationTitle("Threats")
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today by category")
                .font(RakshakTheme.headline)
            Chart(categoryCounts, id: \.0) { item in
                BarMark(
                    x: .value("Count", item.1),
                    y: .value("Category", item.0.displayName)
                )
                .foregroundStyle(RakshakTheme.accentFallback.gradient)
                .cornerRadius(4)
            }
            .frame(height: min(220, CGFloat(categoryCounts.count) * 36 + 40))
        }
        .rakshakCard()
    }
}
