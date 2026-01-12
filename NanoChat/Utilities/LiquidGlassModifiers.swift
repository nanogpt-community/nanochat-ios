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
            .background(Theme.Colors.glassPane, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .background(Theme.Colors.glassBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            case .destructive: return LinearGradient(colors: [Theme.Colors.error.opacity(0.8), Theme.Colors.error.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
            .background(Theme.Colors.glassPane, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .background(Theme.Colors.glassBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
        self.toolbarBackground(Theme.Colors.glassPane, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
