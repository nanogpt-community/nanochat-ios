import SwiftUI

struct ErrorBanner: View {
    let message: String
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Error icon with glass badge
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.error)
                .frame(width: 32, height: 32)
                .glassEffect(in: .circle)

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
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Colors.text)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.xs)
                        .glassEffect()
                }
                .buttonStyle(.plain)
            }

            Button {
                HapticManager.shared.lightTap()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: 28, height: 28)
                    .glassEffect(in: .circle)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
        .tint(Theme.Colors.error)
        .glassEffect(in: .rect(cornerRadius: Theme.CornerRadius.lg))
        .padding(.horizontal, Theme.Spacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Warning Banner Variant

struct WarningBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.warning)
                .frame(width: 32, height: 32)
                .glassEffect(in: .circle)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.text)
                .lineLimit(2)

            Spacer()

            Button {
                HapticManager.shared.lightTap()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: 28, height: 28)
                    .glassEffect(in: .circle)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
        .tint(Theme.Colors.warning)
        .glassEffect(in: .rect(cornerRadius: Theme.CornerRadius.lg))
        .padding(.horizontal, Theme.Spacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Success Banner Variant

struct SuccessBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.success)
                .frame(width: 32, height: 32)
                .glassEffect(in: .circle)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.text)
                .lineLimit(2)

            Spacer()

            Button {
                HapticManager.shared.lightTap()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: 28, height: 28)
                    .glassEffect(in: .circle)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
        .tint(Theme.Colors.success)
        .glassEffect(in: .rect(cornerRadius: Theme.CornerRadius.lg))
        .padding(.horizontal, Theme.Spacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    GlassEffectContainer {
        VStack(spacing: Theme.Spacing.lg) {
            ErrorBanner(
                message: "Failed to load conversations",
                onRetry: { print("Retry tapped") },
                onDismiss: { print("Dismiss tapped") }
            )

            WarningBanner(
                message: "Your session will expire soon",
                onDismiss: { print("Dismiss tapped") }
            )

            SuccessBanner(
                message: "Message sent successfully",
                onDismiss: { print("Dismiss tapped") }
            )

            Spacer()
        }
        .padding(.top, Theme.Spacing.lg)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.Gradients.background)
}
