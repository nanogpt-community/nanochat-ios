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
        self.background(.ultraThinMaterial, in: LiquidGlassRectangle())
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    func liquidGlassBackground() -> some View {
        self.background(.ultraThinMaterial, in: LiquidGlassRectangle())
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
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
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Liquid Glass Button Style

struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Liquid Glass Progress View

struct LiquidGlassProgressView: View {
    var body: some View {
        ProgressView()
            .scaleEffect(1.5)
            .padding(24)
            .background(.ultraThinMaterial, in: Circle())
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
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
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Liquid Glass Navigation Bar

extension View {
    func liquidGlassNavigationBar() -> some View {
        self.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
