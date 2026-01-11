import SwiftUI

struct WebSearchToggle: View {
    @Binding var webSearchMode: WebSearchMode
    @Binding var webSearchEnabled: Bool
    @Binding var webSearchProvider: WebSearchProvider

    var body: some View {
        Menu {
            // Web Search Mode Section
            Section("Search Mode") {
                ForEach(WebSearchMode.allCases) { mode in
                    Button {
                        webSearchMode = mode
                        webSearchEnabled = mode != .off
                    } label: {
                        HStack {
                            Text(mode.displayName)
                            if !mode.costDisplay.isEmpty {
                                Text(mode.costDisplay)
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                            if webSearchMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.Colors.secondary)
                            }
                        }
                    }
                }
            }

            // Provider Section (only show when web search is enabled)
            if webSearchEnabled {
                Section("Provider") {
                    ForEach(WebSearchProvider.allCases) { provider in
                        Button {
                            webSearchProvider = provider
                        } label: {
                            HStack {
                                Image(systemName: provider.iconName)
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.secondary)
                                Text(provider.displayName)
                                if webSearchProvider == provider {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.Colors.secondary)
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                ZStack {
                    if webSearchEnabled {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.secondary, Theme.Colors.primary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)
                            .shadow(color: Theme.Colors.secondary.opacity(0.4), radius: 4, x: 0, y: 2)

                        Image(systemName: "globe")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .fill(Theme.Colors.glassBackground)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                            )

                        Image(systemName: "globe")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                if webSearchEnabled {
                    Text(webSearchMode.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.text)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .glassCard()
            .animation(.none, value: webSearchEnabled)
        }
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.xl) {
        WebSearchToggle(
            webSearchMode: .constant(.off),
            webSearchEnabled: .constant(false),
            webSearchProvider: .constant(.linkup)
        )

        WebSearchToggle(
            webSearchMode: .constant(.standard),
            webSearchEnabled: .constant(true),
            webSearchProvider: .constant(.tavily)
        )

        WebSearchToggle(
            webSearchMode: .constant(.deep),
            webSearchEnabled: .constant(true),
            webSearchProvider: .constant(.kagi)
        )
    }
    .padding()
    .background(Theme.Gradients.background)
}
