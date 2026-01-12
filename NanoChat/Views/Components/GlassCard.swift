import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = Theme.CornerRadius.xl
    var padding: CGFloat = Theme.Spacing.lg
    @ViewBuilder let content: Content
    
    init(cornerRadius: CGFloat = Theme.CornerRadius.xl, padding: CGFloat = Theme.Spacing.lg, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Theme.Colors.glassBackground)
            .background(Theme.Colors.glassPane)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
            )
            .shadow(color: Theme.Colors.glassShadow, radius: 15, x: 0, y: 8)
    }
}

#Preview {
    ZStack {
        Theme.Gradients.background.ignoresSafeArea()
        GlassCard {
            Text("Glass Card Content")
                .foregroundStyle(Theme.Colors.text)
        }
    }
}
