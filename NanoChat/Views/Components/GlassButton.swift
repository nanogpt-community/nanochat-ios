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

        var tintColor: Color {
            switch self {
            case .primary: return Theme.Colors.accent
            case .secondary: return .clear
            case .destructive: return Theme.Colors.error
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
        Button(action: {
            HapticManager.shared.tap()
            action()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.lg)
            .foregroundStyle(Theme.Colors.text)
            .tint(style.tintColor)
            .glassEffect(in: .rect(cornerRadius: Theme.CornerRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Glass Button

struct CompactGlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var tintColor: Color? = nil

    init(_ title: String, icon: String? = nil, tintColor: Color? = nil, action: @escaping () -> Void) {
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
            HStack(spacing: Theme.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .foregroundStyle(tintColor ?? Theme.Colors.text)
            .tint(tintColor)
            .glassEffect()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon-only Glass Button

struct GlassIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44
    var tintColor: Color? = nil

    init(_ icon: String, size: CGFloat = 44, tintColor: Color? = nil, action: @escaping () -> Void) {
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
                .tint(tintColor)
                .glassEffect(in: .circle)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GlassEffectContainer {
        VStack(spacing: 20) {
            GlassButton("Primary Action", icon: "star.fill") {}
            GlassButton("Secondary Action", style: .secondary) {}
            GlassButton("Delete", icon: "trash", style: .destructive) {}

            Divider().overlay(Theme.Colors.glassBorder)

            HStack(spacing: Theme.Spacing.md) {
                CompactGlassButton("Copy", icon: "doc.on.doc") {}
                CompactGlassButton("Share", icon: "square.and.arrow.up", tintColor: Theme.Colors.accent) {}
            }

            HStack(spacing: Theme.Spacing.md) {
                GlassIconButton("plus") {}
                GlassIconButton("mic.fill", tintColor: Theme.Colors.accent) {}
                GlassIconButton("trash", tintColor: Theme.Colors.error) {}
            }
        }
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.Gradients.background)
}
