import SwiftUI

struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
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
    
    init(_ title: String, icon: String? = nil, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.lg)
            .background(
                style.gradient.opacity(style == .primary ? 0.8 : 0.3)
            )
            .background(Theme.Colors.glassPane)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Theme.Colors.glassShadow, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle()) // To handle custom animation if needed
        .foregroundStyle(Theme.Colors.text)
    }
}

#Preview {
    ZStack {
        Theme.Gradients.background.ignoresSafeArea()
        VStack(spacing: 20) {
            GlassButton("Primary Action", icon: "star.fill") {}
            GlassButton("Secondary Action", style: .secondary) {}
            GlassButton("Delete", icon: "trash", style: .destructive) {}
        }
        .padding()
    }
}
