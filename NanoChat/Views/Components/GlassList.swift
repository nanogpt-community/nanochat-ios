import SwiftUI

struct GlassList<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            GlassEffectContainer {
                LazyVStack(spacing: Theme.Spacing.md) {
                    content
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}

struct GlassListSection<Content: View>: View {
    let title: String?
    let icon: String?
    @ViewBuilder let content: Content

    init(_ title: String? = nil, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if let title = title {
                HStack(spacing: Theme.Spacing.xs) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 18, height: 18)
                            .glassEffect(in: .circle)
                    }
                    Text(title.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.leading, Theme.Spacing.sm)
            }

            VStack(spacing: 1) {
                content
            }
            .glassEffect(in: .rect(cornerRadius: Theme.CornerRadius.lg))
        }
    }
}

struct GlassListRow<Content: View>: View {
    @ViewBuilder let content: Content
    let showDivider: Bool

    init(showDivider: Bool = true, @ViewBuilder content: () -> Content) {
        self.showDivider = showDivider
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                content
                Spacer()
            }
            .padding(Theme.Spacing.lg)
            .background(Color.white.opacity(0.001)) // For tap target

            if showDivider {
                Divider()
                    .overlay(Theme.Colors.glassBorder)
            }
        }
    }
}

// MARK: - Interactive Glass List Row

struct InteractiveGlassListRow<Content: View>: View {
    let action: () -> Void
    let showDivider: Bool
    @ViewBuilder let content: Content

    init(showDivider: Bool = true, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.showDivider = showDivider
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.lightTap()
            action()
        }) {
            VStack(spacing: 0) {
                HStack {
                    content
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(Theme.Spacing.lg)

                if showDivider {
                    Divider()
                        .overlay(Theme.Colors.glassBorder)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Theme.Gradients.background.ignoresSafeArea()
        GlassList {
            GlassListSection("Account", icon: "person") {
                InteractiveGlassListRow(action: {}) {
                    Label("Profile", systemImage: "person.circle")
                        .foregroundStyle(Theme.Colors.text)
                }
                InteractiveGlassListRow(showDivider: false, action: {}) {
                    Label("Settings", systemImage: "gearshape")
                        .foregroundStyle(Theme.Colors.text)
                }
            }

            GlassListSection("Preferences") {
                GlassListRow(showDivider: false) {
                    Toggle("Dark Mode", isOn: .constant(true))
                        .tint(Theme.Colors.accent)
                }
            }
        }
    }
}
