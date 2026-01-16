import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = Theme.CornerRadius.xl
    var padding: CGFloat = Theme.Spacing.lg
    var tintColor: Color? = nil
    @ViewBuilder let content: Content

    init(
        cornerRadius: CGFloat = Theme.CornerRadius.xl,
        padding: CGFloat = Theme.Spacing.lg,
        tintColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.tintColor = tintColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .tint(tintColor)
            .glassEffect(in: .rect(cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Card with Header

struct GlassCardWithHeader<Content: View>: View {
    let title: String
    let icon: String?
    var cornerRadius: CGFloat = Theme.CornerRadius.xl
    @ViewBuilder let content: Content

    init(
        title: String,
        icon: String? = nil,
        cornerRadius: CGFloat = Theme.CornerRadius.xl,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack(spacing: Theme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.accent)
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.text)
            }

            // Content
            content
        }
        .padding(Theme.Spacing.lg)
        .glassEffect(in: .rect(cornerRadius: cornerRadius))
    }
}

// MARK: - Interactive Glass Card

struct InteractiveGlassCard<Content: View>: View {
    let action: () -> Void
    var cornerRadius: CGFloat = Theme.CornerRadius.lg
    var padding: CGFloat = Theme.Spacing.md
    @ViewBuilder let content: Content

    init(
        cornerRadius: CGFloat = Theme.CornerRadius.lg,
        padding: CGFloat = Theme.Spacing.md,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.tap()
            action()
        }) {
            content
                .padding(padding)
                .glassEffect(in: .rect(cornerRadius: cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GlassEffectContainer {
        VStack(spacing: Theme.Spacing.lg) {
            GlassCard {
                Text("Glass Card Content")
                    .foregroundStyle(Theme.Colors.text)
            }

            GlassCard(tintColor: Theme.Colors.accent) {
                Text("Tinted Glass Card")
                    .foregroundStyle(Theme.Colors.text)
            }

            GlassCardWithHeader(title: "Settings", icon: "gearshape") {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Configure your preferences")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            InteractiveGlassCard(action: { print("Tapped!") }) {
                HStack {
                    Text("Tap me!")
                        .foregroundStyle(Theme.Colors.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
        }
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.Gradients.background)
}
