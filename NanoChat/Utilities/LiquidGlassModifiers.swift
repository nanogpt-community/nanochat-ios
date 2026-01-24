import SwiftUI

// MARK: - Liquid Glass Materials

struct LiquidGlassRectangle: InsettableShape {
    var cornerRadius: CGFloat = 16
    var insets = UIEdgeInsets()

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.inset(by: insets)
        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .path(in: insetRect)
    }

    func inset(by amount: CGFloat) -> Self {
        var insettable = self
        insettable.insets = UIEdgeInsets(
            top: amount,
            left: amount,
            bottom: amount,
            right: amount
        )
        return insettable
    }
}

// MARK: - Native iOS 26 Liquid Glass Extensions

extension View {
    /// Applies native iOS 26 liquid glass effect with a capsule shape (default)
    func nativeGlass() -> some View {
        self.glassEffect()
    }

    /// Applies native iOS 26 liquid glass effect with a custom shape
    func nativeGlass<S: Shape>(in shape: S) -> some View {
        self.glassEffect(in: shape)
    }

    /// Applies native iOS 26 liquid glass with rounded rectangle
    func nativeGlassRounded(cornerRadius: CGFloat = Theme.CornerRadius.lg) -> some View {
        self.glassEffect(in: .rect(cornerRadius: cornerRadius))
    }

    /// Applies native iOS 26 liquid glass with a tint color for emphasis
    func nativeGlassTinted(_ color: Color) -> some View {
        self.tint(color)
            .glassEffect()
    }

    /// Applies native iOS 26 liquid glass with circle shape
    func nativeGlassCircle() -> some View {
        self.glassEffect(in: .circle)
    }
}

// MARK: - Legacy Liquid Glass Extensions (Fallback)

extension View {
    var liquidGlassMaterial: some View {
        self.background(Theme.Colors.glassPane, in: LiquidGlassRectangle())
            .background(Theme.Colors.glassBackground, in: LiquidGlassRectangle())
            .overlay(
                LiquidGlassRectangle()
                    .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
            )
            .shadow(color: Theme.Colors.glassShadow, radius: 15, x: 0, y: 8)
    }

    func liquidGlassBackground() -> some View {
        self.background(Theme.Colors.glassPane, in: LiquidGlassRectangle())
            .background(Theme.Colors.glassBackground, in: LiquidGlassRectangle())
            .overlay(
                LiquidGlassRectangle()
                    .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
            )
            .shadow(color: Theme.Colors.glassShadow, radius: 15, x: 0, y: 8)
    }

    // For when you need just the border
    func liquidGlassBorder() -> some View {
        self.overlay(
            LiquidGlassRectangle()
                .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
        )
    }
}

extension TextFieldStyle where Self == LiquidGlassTextFieldStyle {
    static var liquidGlass: LiquidGlassTextFieldStyle {
        LiquidGlassTextFieldStyle()
    }
}

struct LiquidGlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(
                Theme.Colors.glassPane, in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .background(
                Theme.Colors.glassBackground,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Theme.Colors.glassBorder.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Theme.Colors.glassShadow.opacity(0.5), radius: 5, x: 0, y: 2)
            .foregroundStyle(Theme.Colors.text)
            .tint(Theme.Colors.accent)
    }
}

// MARK: - Liquid Glass Button Style

struct LiquidGlassButtonStyle: ButtonStyle {
    var style: Style = .primary

    enum Style {
        case primary
        case secondary
        case destructive

        var gradient: LinearGradient {
            switch self {
            case .primary: return Theme.Gradients.primary
            case .secondary: return Theme.Gradients.glass
            case .destructive:
                return LinearGradient(
                    colors: [Theme.Colors.error.opacity(0.8), Theme.Colors.error.opacity(0.4)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Theme.Colors.glassPane,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .background(
                configuration.isPressed
                    ? style.gradient.opacity(0.8)
                    : style.gradient.opacity(style == .primary ? 0.8 : 0.3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
            )
            .shadow(color: Theme.Colors.glassShadow, radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .foregroundStyle(Theme.Colors.text)
    }
}

// MARK: - Liquid Glass Progress View

struct LiquidGlassProgressView: View {
    var body: some View {
        ProgressView()
            .tint(Theme.Colors.accent)
            .scaleEffect(1.5)
            .padding(24)
            .background(Theme.Colors.glassPane, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
            )
            .shadow(color: Theme.Colors.glassShadow, radius: 10, x: 0, y: 4)
    }
}

// MARK: - Liquid Glass Card

struct LiquidGlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                Theme.Colors.glassPane, in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .background(
                Theme.Colors.glassBackground,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
            )
            .shadow(color: Theme.Colors.glassShadow, radius: 20, x: 0, y: 10)
    }
}

// MARK: - Liquid Glass Navigation Bar

extension View {
    func liquidGlassNavigationBar() -> some View {
        self.modifier(LiquidGlassNavigationBarModifier())
    }

    func liquidGlassTabBar() -> some View {
        self.modifier(LiquidGlassTabBarModifier())
    }
}

private struct LiquidGlassNavigationBarModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
    }
}

private struct LiquidGlassTabBarModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(colorScheme, for: .tabBar)
    }
}

// MARK: - Native Glass Button Style (iOS 26)

struct NativeGlassButtonStyle: ButtonStyle {
    var isInteractive: Bool = true
    var cornerRadius: CGFloat = Theme.CornerRadius.md

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .foregroundStyle(Theme.Colors.text)
            .glassEffect(in: .rect(cornerRadius: cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct NativeGlassTintedButtonStyle: ButtonStyle {
    var tintColor: Color = Theme.Colors.accent
    var cornerRadius: CGFloat = Theme.CornerRadius.md

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .foregroundStyle(Theme.Colors.text)
            .tint(tintColor)
            .glassEffect(in: .rect(cornerRadius: cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Native Glass Circular Button

struct NativeGlassCircularButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44
    var tintColor: Color? = nil

    init(icon: String, size: CGFloat = 44, tintColor: Color? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.tintColor = tintColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.tap()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(tintColor ?? Theme.Colors.text)
                .frame(width: size, height: size)
                .glassEffect(in: .circle)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Native Glass Capsule Button

struct NativeGlassCapsuleButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var tintColor: Color? = nil

    init(
        _ title: String, icon: String? = nil, tintColor: Color? = nil, action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.tintColor = tintColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.tap()
            action()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(tintColor ?? Theme.Colors.text)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .glassEffect()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Native Glass Chip (for tags, filters, suggestions)

struct NativeGlassChip: View {
    let text: String
    let icon: String?
    let action: () -> Void
    var isSelected: Bool = false

    init(
        _ text: String, icon: String? = nil, isSelected: Bool = false, action: @escaping () -> Void
    ) {
        self.text = text
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.lightTap()
            action()
        }) {
            HStack(spacing: Theme.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(text)
                    .font(.subheadline)
                    .lineLimit(2)
            }
            .foregroundStyle(isSelected ? Theme.Colors.accent : Theme.Colors.text)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .tint(isSelected ? Theme.Colors.accent : nil)
            .glassEffect()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Native Glass Icon Badge

struct NativeGlassIconBadge: View {
    let icon: String
    var size: CGFloat = 32
    var tintColor: Color? = nil

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(tintColor ?? Theme.Colors.text)
            .frame(width: size, height: size)
            .glassEffect(in: .circle)
    }
}

// MARK: - Native Glass Floating Action Button

struct NativeGlassFloatingButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 56
    var tintColor: Color = Theme.Colors.accent

    var body: some View {
        Button(action: {
            HapticManager.shared.tap()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(Theme.Colors.text)
                .frame(width: size, height: size)
                .tint(tintColor)
                .glassEffect(in: .circle)
        }
        .buttonStyle(.plain)
        .shadow(color: tintColor.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Preview Helpers

#Preview("Liquid Glass Components") {
    VStack(spacing: 32) {
        TextField("Enter text", text: .constant(""))
            .textFieldStyle(.liquidGlass)

        Button("Action") {
            print("Tapped")
        }
        .buttonStyle(LiquidGlassButtonStyle())

        LiquidGlassProgressView()

        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Card Title")
                    .font(.headline)
                Text("This is a liquid glass card with content inside.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}

#Preview("Native Glass Components") {
    GlassEffectContainer {
        VStack(spacing: 24) {
            // Circular buttons
            HStack(spacing: 16) {
                NativeGlassCircularButton(icon: "plus") {}
                NativeGlassCircularButton(icon: "mic.fill", tintColor: Theme.Colors.accent) {}
                NativeGlassCircularButton(icon: "photo") {}
            }

            // Capsule buttons
            HStack(spacing: 12) {
                NativeGlassCapsuleButton(
                    "Send", icon: "paperplane.fill", tintColor: Theme.Colors.accent
                ) {}
                NativeGlassCapsuleButton("Cancel") {}
            }

            // Chips
            HStack(spacing: 8) {
                NativeGlassChip("Follow up", icon: "arrow.turn.down.right") {}
                NativeGlassChip("Selected", isSelected: true) {}
            }

            // Icon badges
            HStack(spacing: 12) {
                NativeGlassIconBadge(icon: "star.fill", tintColor: Theme.Colors.warning)
                NativeGlassIconBadge(icon: "checkmark", tintColor: Theme.Colors.success)
                NativeGlassIconBadge(icon: "xmark", tintColor: Theme.Colors.error)
            }

            // Floating action button
            NativeGlassFloatingButton(icon: "plus") {}

            // Text with native glass
            Text("Native Glass Text")
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .nativeGlassRounded()
        }
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.Gradients.background)
}
