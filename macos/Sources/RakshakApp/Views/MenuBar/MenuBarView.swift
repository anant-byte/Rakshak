import SwiftUI
import RakshakCore

struct MenuBarView: View {
    @Environment(AppViewModel.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                Text("Rakshak")
                    .font(.headline)
            }
            Divider()
            HStack {
                Text("Blocked today")
                Spacer()
                Text("\(app.daemonState.stats.blockedToday)")
                    .fontWeight(.semibold)
            }
            Toggle("Protection", isOn: Binding(
                get: { app.daemonState.stats.protectionEnabled },
                set: { on in Task { if on { await app.enableProtection() } else { await app.disableProtection() } } }
            ))
            Divider()
            Button("Open Rakshak") {
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
        .padding(12)
        .frame(width: 240)
    }
}

import AppKit
