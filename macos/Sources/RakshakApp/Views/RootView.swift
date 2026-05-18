import SwiftUI
import RakshakCore

struct RootView: View {
    @Environment(AppViewModel.self) private var app

    var body: some View {
        Group {
            if !app.isAuthenticated {
                LoginView()
            } else if app.showOnboarding {
                OnboardingFlowView()
            } else {
                MainShellView()
            }
        }
        .preferredColorScheme(nil)
        .onAppear { app.onAppear() }
    }
}

struct MainShellView: View {
    @Environment(AppViewModel.self) private var app

    var body: some View {
        NavigationSplitView {
            List(AppTab.allCases, id: \.self, selection: Binding(
                get: { app.selectedTab },
                set: { app.selectedTab = $0 }
            )) { tab in
                Label(tab.title, systemImage: tab.icon)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            switch app.selectedTab {
            case .home: DashboardView()
            case .devices: DevicesView()
            case .threats: ThreatsView()
            case .alerts: AlertsView()
            case .settings: SettingsView()
            }
        }
    }
}
