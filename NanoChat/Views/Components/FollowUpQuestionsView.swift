import SwiftUI

struct FollowUpQuestionsView: View {
    let suggestions: [String]
    let onSuggestionTapped: (String) -> Void

    var body: some View {
        GlassEffectContainer {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Header with glass badge
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(width: 20, height: 20)
                        .glassEffect(in: .circle)

                    Text("Suggestions")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(.leading, Theme.Spacing.xs)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                            FollowUpChip(text: suggestion) {
                                onSuggestionTapped(suggestion)
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.9)).animation(Theme.Animation.staggered(index: index)),
                                removal: .opacity
                            ))
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.xs)
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
    }
}

struct FollowUpChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.lightTap()
            action()
        }) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Colors.secondary)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .glassEffect()
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Quick Actions View (Alternative Layout)

struct QuickActionsView: View {
    let actions: [(icon: String, label: String, action: () -> Void)]
    @Namespace private var actionsNamespace

    var body: some View {
        GlassEffectContainer {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(Array(actions.enumerated()), id: \.offset) { index, item in
                        Button {
                            HapticManager.shared.lightTap()
                            item.action()
                        } label: {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.accent)

                                Text(item.label)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Theme.Colors.text)
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .glassEffect()
                            .glassEffectID(index, in: actionsNamespace)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.Gradients.background
            .ignoresSafeArea()

        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            FollowUpQuestionsView(
                suggestions: [
                    "What are some practical applications?",
                    "How does this compare to alternatives?",
                    "Can you explain the limitations?"
                ]
            ) { suggestion in
                print("Tapped: \(suggestion)")
            }

            QuickActionsView(actions: [
                (icon: "doc.on.doc", label: "Copy", action: {}),
                (icon: "square.and.arrow.up", label: "Share", action: {}),
                (icon: "speaker.wave.2", label: "Read Aloud", action: {}),
                (icon: "star", label: "Star", action: {})
            ])

            Spacer()
        }
        .padding()
    }
}
