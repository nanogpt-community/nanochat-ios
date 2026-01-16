import SwiftUI

struct GlassSheet<Content: View>: View {
    let title: String
    let icon: String?
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder let content: Content

    init(title: String, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        ZStack {
            Theme.Gradients.background.ignoresSafeArea()

            GlassEffectContainer {
                VStack(spacing: 0) {
                    // Header with glass effect
                    HStack(spacing: Theme.Spacing.sm) {
                        if let icon {
                            Image(systemName: icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.Colors.accent)
                                .frame(width: 32, height: 32)
                                .glassEffect(in: .circle)
                        }

                        Text(title)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.text)

                        Spacer()

                        Button {
                            HapticManager.shared.lightTap()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.Colors.text)
                                .frame(width: 32, height: 32)
                                .glassEffect(in: .circle)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .glassEffect(in: .rect(cornerRadius: 0))

                    // Content
                    content
                }
            }
        }
    }
}

// MARK: - Glass Modal Sheet (for full-screen modals)

struct GlassModalSheet<Content: View>: View {
    let title: String
    let icon: String?
    let onDismiss: () -> Void
    let onConfirm: (() -> Void)?
    let confirmTitle: String
    @ViewBuilder let content: Content

    init(
        title: String,
        icon: String? = nil,
        confirmTitle: String = "Done",
        onDismiss: @escaping () -> Void,
        onConfirm: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.confirmTitle = confirmTitle
        self.onDismiss = onDismiss
        self.onConfirm = onConfirm
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background.ignoresSafeArea()

                content
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.lightTap()
                        onDismiss()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }

                if let onConfirm {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(confirmTitle) {
                            HapticManager.shared.tap()
                            onConfirm()
                        }
                        .foregroundStyle(Theme.Colors.accent)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack {
        GlassSheet(title: "Settings", icon: "gearshape") {
            VStack {
                Text("Content goes here")
                    .padding()
                    .foregroundStyle(.white)
                Spacer()
            }
        }
    }
}
