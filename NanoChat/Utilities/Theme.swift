import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if os(macOS)
private let scaleFactor: CGFloat = 1.5
#else
private let scaleFactor: CGFloat = {
    if ProcessInfo.processInfo.isiOSAppOnMac {
        return 1.5
    }
    return 1.0
}()
#endif

struct Theme {
    // MARK: - Colors
    struct Colors {
        #if os(iOS)
        // Background
        static let backgroundStart = Color(uiColor: .systemBackground)
        static let backgroundEnd = Color(uiColor: .systemBackground)
        
        // Text
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        
        // Glass/Surfaces
        static let glassBackground = Color(uiColor: .systemBackground)
        static let glassSurface = Color(uiColor: .secondarySystemBackground)
        static let userBubble = Color(uiColor: .systemGray5)
        static let border = Color(uiColor: .separator)
        
        #elseif os(macOS)
        // Background
        static let backgroundStart = Color(nsColor: .windowBackgroundColor)
        static let backgroundEnd = Color(nsColor: .windowBackgroundColor)
        
        // Text
        static let textTertiary = Color(nsColor: .tertiaryLabelColor)
        
        // Glass/Surfaces
        static let glassBackground = Color(nsColor: .windowBackgroundColor)
        static let glassSurface = Color(nsColor: .controlBackgroundColor)
        static let userBubble = Color(nsColor: .controlBackgroundColor) // Approximate
        static let border = Color(nsColor: .separatorColor)
        
        #else
        // Fallback for other platforms
        static let backgroundStart = Color.black
        static let backgroundEnd = Color.black
        static let textTertiary = Color.gray
        static let glassBackground = Color.black
        static let glassSurface = Color.gray.opacity(0.2)
        static let userBubble = Color.gray.opacity(0.3)
        static let border = Color.gray.opacity(0.5)
        #endif

        // Primary accents
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let accent = Color.blue

        // Gradient colors (Simplified/Removed for ChatGPT style)
        static let gradientStart = backgroundStart
        static let gradientEnd = backgroundEnd

        // Text colors
        static let text = Color.primary
        static let textSecondary = Color.secondary

        // Glass effect (Made very subtle or transparent)
        static let glassBorder = Color.clear
        static let glassShadow = Color.black.opacity(0.1)
        
        // Specific Glass Elements
        static let glassPane = Material.bar
        
        // User message gradient (Solid now)
        static let userBubbleGradient = LinearGradient(
            colors: [userBubble, userBubble],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Assistant message
        static let assistantBubble = Color.clear
        
        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // Aliases for compatibility
        static let textPrimary = text
        static let cardBackground = glassSurface
    }
    
    #if os(macOS)
    static let imageScaleFactor: CGFloat = 1.5
    #else
    static let imageScaleFactor: CGFloat = {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return 1.5
        }
        return 1.0
    }()
    #endif
    
    typealias Radius = CornerRadius

    // MARK: - Typography
    struct Typography {
        static let title = Font.system(size: 24 * scaleFactor, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22 * scaleFactor, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20 * scaleFactor, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 18 * scaleFactor, weight: .semibold, design: .rounded)
        static let subheadline = Font.system(size: 15 * scaleFactor, weight: .regular, design: .rounded)
        static let body = Font.system(size: 16 * scaleFactor, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 14 * scaleFactor, weight: .medium, design: .rounded)
        static let caption2 = Font.system(size: 12 * scaleFactor, weight: .regular, design: .rounded)
        
        static func system(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
            return Font.system(size: size * scaleFactor, weight: weight, design: design)
        }
    }

    // MARK: - Gradients
    struct Gradients {
        static let primary = LinearGradient(
            colors: [Colors.primary, Colors.primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let background = LinearGradient(
            colors: [Colors.backgroundStart, Colors.backgroundEnd],
            startPoint: .top,
            endPoint: .bottom
        )

        static let glow = LinearGradient(
            colors: [.clear, .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let glass = LinearGradient(
             colors: [
                 Color.clear,
                 Color.clear,
                 Color.clear
             ],
             startPoint: .topLeading,
             endPoint: .bottomTrailing
         )
         
         static let shimmer = LinearGradient(
             colors: [
                 Color.primary.opacity(0.0),
                 Color.primary.opacity(0.05),
                 Color.primary.opacity(0.0)
             ],
             startPoint: .leading,
             endPoint: .trailing
         )
    }

    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4 * scaleFactor
        static let sm: CGFloat = 8 * scaleFactor
        static let md: CGFloat = 12 * scaleFactor
        static let lg: CGFloat = 16 * scaleFactor
        static let xl: CGFloat = 24 * scaleFactor
        static let xxl: CGFloat = 32 * scaleFactor
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8 * scaleFactor
        static let md: CGFloat = 12 * scaleFactor
        static let lg: CGFloat = 16 * scaleFactor
        static let xl: CGFloat = 24 * scaleFactor
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
