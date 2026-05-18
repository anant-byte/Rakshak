import SwiftUI

/// Design tokens — calm, premium, Apple-adjacent (not “hacker terminal”).
public enum RakshakTheme {
    // MARK: - Colors (adaptive light/dark via system)

    public static let accent = Color(red: 0.22, green: 0.48, blue: 0.98)
    public static let success = Color.green.opacity(0.85)
    public static let warning = Color.orange.opacity(0.9)
    public static let danger = Color.red.opacity(0.85)
    public static let muted = Color.secondary

    public static var surfaceFallback: Color { Color(nsColor: .windowBackgroundColor) }
    public static var cardFallback: Color { Color(nsColor: .controlBackgroundColor) }

    // MARK: - Typography

    public static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    public static let title = Font.system(.title2, design: .rounded).weight(.semibold)
    public static let headline = Font.system(.headline, design: .rounded)
    public static let body = Font.system(.body, design: .default)
    public static let caption = Font.system(.caption, design: .default)
    public static let stat = Font.system(size: 36, weight: .bold, design: .rounded)

    // MARK: - Layout

    public static let cardRadius: CGFloat = 16
    public static let buttonRadius: CGFloat = 10
    public static let spacing: CGFloat = 16
    public static let padding: CGFloat = 24

    // MARK: - Animation

    public static let spring = Animation.spring(response: 0.38, dampingFraction: 0.82)
    public static let quick = Animation.easeOut(duration: 0.2)

    // Legacy alias used by views
    public static var accentFallback: Color { accent }
}

public struct RakshakCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    public func body(content: Content) -> some View {
        content
            .padding(RakshakTheme.spacing)
            .background(
                RoundedRectangle(cornerRadius: RakshakTheme.cardRadius, style: .continuous)
                    .fill(RakshakTheme.cardFallback)
                    .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.06), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RakshakTheme.cardRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    public func rakshakCard() -> some View { modifier(RakshakCardStyle()) }
}
