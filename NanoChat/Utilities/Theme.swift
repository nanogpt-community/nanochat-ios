import SwiftUI

struct Theme {
    // MARK: - Colors
    struct Colors {
        // Background (Pure Black)
        static let backgroundStart = Color.black
        static let backgroundEnd = Color.black

        // Primary accents (Neon Pink/Purple)
        static let primary = Color(red: 0.85, green: 0.2, blue: 0.65)   // Neon Pink
        static let secondary = Color(red: 0.6, green: 0.1, blue: 0.9)   // Deep Neon Purple
        static let accent = Color(red: 1.0, green: 0.4, blue: 0.8)      // Hot Pink for accents

        // Gradient colors
        static let gradientStart = Color(red: 0.9, green: 0.2, blue: 0.7) // Pink
        static let gradientEnd = Color(red: 0.6, green: 0.1, blue: 0.9)   // Purple

        // Text colors
        static let text = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.4)

        // Glass effect
        static let glassBackground = Color.white.opacity(0.05)
        static let glassBorder = Color.white.opacity(0.15)
        static let glassShadow = Color.black.opacity(0.4)
        
        // Specific Glass Elements
        static let glassPane = Material.ultraThin
        static let glassSurface = Color.white.opacity(0.03)

        // User message
        static let userBubble = Color(red: 0.7, green: 0.2, blue: 0.6)
        static let userBubbleGradient = LinearGradient(
            colors: [Color(red: 0.8, green: 0.2, blue: 0.7), Color(red: 0.6, green: 0.1, blue: 0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Assistant message
        static let assistantBubble = Color.white.opacity(0.05)
        
        // Status colors
        static let success = Color(red: 0.2, green: 0.9, blue: 0.6)
        static let warning = Color(red: 1.0, green: 0.8, blue: 0.3)
        static let error = Color(red: 1.0, green: 0.3, blue: 0.4)
        
        // Aliases for compatibility
        static let textPrimary = text
        static let cardBackground = glassBackground
        static let border = glassBorder
    }
    
    typealias Radius = CornerRadius

    // MARK: - Typography
    struct Typography {
        static let title = Font.system(size: 24, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 14, weight: .medium, design: .rounded)
        static let caption2 = Font.system(size: 12, weight: .regular, design: .rounded)
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
        
        static let glass = LinearGradient(
             colors: [
                 Colors.glassBorder.opacity(0.6),
                 Colors.glassBorder.opacity(0.1),
                 Colors.glassBorder.opacity(0.3)
             ],
             startPoint: .topLeading,
             endPoint: .bottomTrailing
         )
         
         static let shimmer = LinearGradient(
             colors: [
                 Color.white.opacity(0.0),
                 Color.white.opacity(0.1),
                 Color.white.opacity(0.0)
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

    // Additional specific haptic patterns
    func messageSent() { impact(.light) }
    func messageReceived() { notification(.success) }
    func scrollInteraction() { impact(.light) }
    func refreshTriggered() { impact(.medium) }
    func longPressActivated() { heavyTap() }
    func selectionChanged() { selection() }
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
                    Theme.Colors.glassBackground.opacity(0.5)
                } else {
                    Theme.Colors.glassBackground
                }
            }
            .background(Theme.Colors.glassPane)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
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
