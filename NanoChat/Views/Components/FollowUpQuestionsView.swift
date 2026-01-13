import SwiftUI

struct FollowUpQuestionsView: View {
    let suggestions: [String]
    let onSuggestionTapped: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Follow-up questions")
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Colors.textTertiary)
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
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.glassBorder, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    ZStack {
        Theme.Gradients.background
            .ignoresSafeArea()

        VStack {
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
            Spacer()
        }
        .padding()
    }
}
