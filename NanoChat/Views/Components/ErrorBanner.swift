import SwiftUI

struct ErrorBanner: View {
    let message: String
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Colors.error)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.text)
                .lineLimit(2)

            Spacer()

            if let onRetry = onRetry {
                Button {
                    HapticManager.shared.tap()
                    onRetry()
                } label: {
                    Text("Retry")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.secondary)
                }
                .buttonStyle(.plain)
            }

            Button {
                HapticManager.shared.lightTap()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.error.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, Theme.Spacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    VStack {
        ErrorBanner(
            message: "Failed to load conversations",
            onRetry: { print("Retry tapped") },
            onDismiss: { print("Dismiss tapped") }
        )
        Spacer()
    }
    .background(Theme.Gradients.background)
}
