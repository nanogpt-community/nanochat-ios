import SwiftUI

struct Theme {
    // MARK: - Colors
    struct Colors {
        // Background gradient (dark purple to black)
        static let backgroundStart = Color(red: 0.11, green: 0.05, blue: 0.2)
        static let backgroundEnd = Color(red: 0.02, green: 0.02, blue: 0.05)

        // Primary accents (purple/pink)
        static let primary = Color(red: 0.6, green: 0.2, blue: 0.8)
        static let secondary = Color(red: 0.9, green: 0.3, blue: 0.6)
        static let accent = Color(red: 0.7, green: 0.25, blue: 0.95)

        // Gradient colors
        static let gradientStart = Color(red: 0.4, green: 0.15, blue: 0.7)
        static let gradientEnd = Color(red: 0.8, green: 0.2, blue: 0.6)

        // Text colors
        static let text = Color.white
        static let textSecondary = Color(white: 0.7)
        static let textTertiary = Color(white: 0.5)

        // Glass effect
        static let glassBackground = Color.white.opacity(0.08)
        static let glassBorder = Color.white.opacity(0.12)
        static let glassShadow = Color.black.opacity(0.3)

        // User message
        static let userBubble = Color(red: 0.5, green: 0.2, blue: 0.7)
        static let userBubbleGradient = LinearGradient(
            colors: [Color(red: 0.6, green: 0.25, blue: 0.85), Color(red: 0.8, green: 0.3, blue: 0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Assistant message
        static let assistantBubble = Color.white.opacity(0.08)
        
        // Status colors
        static let success = Color(red: 0.3, green: 0.85, blue: 0.5)
        static let warning = Color(red: 1.0, green: 0.75, blue: 0.3)
        static let error = Color(red: 1.0, green: 0.35, blue: 0.35)
    }

    // MARK: - Gradients
    struct Gradients {
        static let primary = LinearGradient(
            colors: [Colors.gradientStart, Colors.gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let background = LinearGradient(
            colors: [Colors.backgroundStart, Colors.backgroundEnd],
            startPoint: .top,
            endPoint: .bottom
        )

        static let glow = LinearGradient(
            colors: [Colors.primary.opacity(0.3), Colors.secondary.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let shimmer = LinearGradient(
            colors: [
                Colors.glassBackground,
                Colors.glassBorder,
                Colors.glassBackground
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick: SwiftUI.Animation = .easeOut(duration: 0.15)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let smooth: SwiftUI.Animation = .easeInOut(duration: 0.35)
        static let spring: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.75)
        static let bouncy: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.6)
        
        // For staggered animations
        static func staggered(index: Int, baseDelay: Double = 0.05) -> SwiftUI.Animation {
            .easeOut(duration: 0.3).delay(Double(index) * baseDelay)
        }
    }
    
    // MARK: - Shadows
    struct Shadows {
        static func glow(color: Color = Colors.primary, radius: CGFloat = 10) -> some View {
            Circle()
                .fill(color.opacity(0.3))
                .blur(radius: radius)
        }
    }
}

// MARK: - Haptic Feedback Manager
@MainActor
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // Convenience methods
    func lightTap() { impact(.light) }
    func tap() { impact(.medium) }
    func heavyTap() { impact(.heavy) }
    func success() { notification(.success) }
    func warning() { notification(.warning) }
    func error() { notification(.error) }
}

// MARK: - View Extensions
extension View {
    func themedBackground() -> some View {
        self.background(
            ZStack {
                Theme.Gradients.background.ignoresSafeArea()

                // Subtle glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.Colors.primary.opacity(0.15), .clear],
                            center: .topTrailing,
                            startRadius: 0,
                            endRadius: 400
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: 100, y: -100)
            }
        )
    }

    func glassCard(
        isPressed: Bool = false
    ) -> some View {
        self.background(
            ZStack {
                if isPressed {
                    Theme.Colors.primary.opacity(0.2)
                } else {
                    Theme.Colors.glassBackground
                }
            }
            .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.Colors.glassBorder,
                            Theme.Colors.glassBorder.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Theme.Colors.glassShadow, radius: 10, x: 0, y: 4)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                ZStack {
                    Theme.Gradients.primary

                    if configuration.isPressed {
                        Color.black.opacity(0.2)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Theme.Colors.text)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .glassCard(isPressed: configuration.isPressed)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
