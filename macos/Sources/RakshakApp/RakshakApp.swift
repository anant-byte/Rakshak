import SwiftUI
import AppKit
import RakshakCore
import UserNotifications

@main
@MainActor
struct RakshakApp: App {
    @State private var appState = AppViewModel()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .frame(minWidth: 960, minHeight: 640)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra("Rakshak", systemImage: "shield.checkered") {
            MenuBarView()
                .environment(appState)
        }
        .menuBarExtraStyle(.menu)
    }
}
