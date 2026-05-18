import SwiftUI
import RakshakCore

struct LoginView: View {
    @Environment(AppViewModel.self) private var app
    @State private var password = ""
    @State private var confirm = ""
    @State private var isFirstRun = KeychainStore.load() == nil
    @State private var error = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), RakshakTheme.accentFallback.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(RakshakTheme.accentFallback)
                Text("Rakshak")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text(isFirstRun ? "Create a local password" : "Welcome back")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    if isFirstRun {
                        SecureField("Confirm password", text: $confirm)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .frame(maxWidth: 320)

                if !error.isEmpty {
                    Text(error).foregroundStyle(RakshakTheme.danger).font(.caption)
                }

                Button(isFirstRun ? "Continue" : "Unlock") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

                Text("Stored only in your Mac Keychain · never sent online")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(40)
        }
    }

    private func submit() {
        if isFirstRun {
            guard password.count >= 8 else { error = "Use at least 8 characters"; return }
            guard password == confirm else { error = "Passwords don't match"; return }
        }
        guard app.login(password: password) else {
            error = "Incorrect password"
            return
        }
        error = ""
    }
}
