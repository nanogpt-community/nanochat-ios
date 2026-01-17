import SwiftUI

struct ProviderPicker: View {
    let availableProviders: [ProviderInfo]
    let selectedProviderId: String?
    let onSelectProvider: (String?) -> Void
    
    @Binding var webSearchMode: WebSearchMode
    @Binding var webSearchProvider: WebSearchProvider
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(Theme.font(size: 17, weight: .semibold))
                .foregroundStyle(Theme.Colors.text)
                .padding(.vertical, Theme.scaled(12))
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.glassBackground)

            Divider()

            ScrollView {
                VStack(spacing: Theme.scaled(24)) {

                    // MARK: - Web Search Section
                    VStack(alignment: .leading, spacing: Theme.scaled(12)) {
                        Text("Web Search")
                            .font(Theme.font(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, Theme.scaled(16))

                        // Search Mode Selector
                        HStack(spacing: Theme.scaled(8)) {
                            ForEach(WebSearchMode.allCases) { mode in
                                Button {
                                    withAnimation {
                                        webSearchMode = mode
                                    }
                                } label: {
                                    VStack(spacing: Theme.scaled(2)) {
                                        Text(mode.displayName)
                                            .font(Theme.font(size: 14, weight: .medium))
                                        if !mode.costDisplay.isEmpty {
                                            Text(mode.costDisplay)
                                                .font(Theme.font(size: 11))
                                                .opacity(0.7)
                                        }
                                    }
                                    .padding(.vertical, Theme.scaled(8))
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        webSearchMode == mode
                                        ? Theme.Colors.accent.opacity(0.1)
                                        : Theme.Colors.glassBackground
                                    )
                                    .foregroundStyle(
                                        webSearchMode == mode
                                        ? Theme.Colors.accent
                                        : Theme.Colors.text
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.scaled(8)))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.scaled(8))
                                            .stroke(
                                                webSearchMode == mode
                                                ? Theme.Colors.accent
                                                : Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.scaled(16))

                        // Search Provider Selector (Only if not off)
                        if webSearchMode != .off {
                            VStack(alignment: .leading, spacing: Theme.scaled(8)) {
                                Text("Search Provider")
                                    .font(Theme.font(size: 12))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                                    .padding(.horizontal, Theme.scaled(16))

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Theme.scaled(8)) {
                                        ForEach(WebSearchProvider.allCases) { provider in
                                            Button {
                                                webSearchProvider = provider
                                            } label: {
                                                HStack(spacing: Theme.scaled(6)) {
                                                    Image(systemName: provider.iconName)
                                                        .font(Theme.font(size: 12))
                                                    Text(provider.displayName)
                                                        .font(Theme.font(size: 12))
                                                }
                                                .padding(.vertical, Theme.scaled(6))
                                                .padding(.horizontal, Theme.scaled(12))
                                                .background(
                                                    webSearchProvider == provider
                                                    ? Theme.Colors.primary.opacity(0.1)
                                                    : Theme.Colors.glassBackground
                                                )
                                                .foregroundStyle(
                                                    webSearchProvider == provider
                                                    ? Theme.Colors.primary
                                                    : Theme.Colors.text
                                                )
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule()
                                                        .stroke(
                                                            webSearchProvider == provider
                                                            ? Theme.Colors.primary
                                                            : Theme.Colors.border,
                                                            lineWidth: 1
                                                        )
                                                )
                                                .contentShape(Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, Theme.scaled(16))
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.top, Theme.scaled(16))

                    Divider()

                    // MARK: - Model Provider Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Model Provider")
                            .font(Theme.font(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, Theme.scaled(16))
                            .padding(.bottom, Theme.scaled(8))

                        // Auto Option
                        Button {
                            onSelectProvider(nil)
                        } label: {
                            HStack {
                                Image(systemName: "server.rack")
                                    .font(Theme.font(size: 16))
                                    .foregroundStyle(Theme.Colors.primary)
                                Text("Auto (Recommended)")
                                    .font(Theme.font(size: 16))
                                    .foregroundStyle(Theme.Colors.text)
                                Spacer()
                                if selectedProviderId == nil {
                                    Image(systemName: "checkmark")
                                        .font(Theme.font(size: 14))
                                        .foregroundStyle(Theme.Colors.accent)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, Theme.scaled(16))
                            .padding(.vertical, Theme.scaled(12))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, Theme.scaled(16))

                        // Providers List
                        ForEach(availableProviders) { provider in
                            Button {
                                onSelectProvider(provider.provider)
                            } label: {
                                HStack {
                                    Image(systemName: "server.rack")
                                        .font(Theme.font(size: 16))
                                        .foregroundStyle(Theme.Colors.primary)

                                    VStack(alignment: .leading, spacing: Theme.scaled(2)) {
                                        Text(provider.provider.capitalized)
                                            .font(Theme.font(size: 16))
                                            .foregroundStyle(Theme.Colors.text)
                                        Text("\(formatPrice(provider.pricing.inputPer1kTokens)) input / \(formatPrice(provider.pricing.outputPer1kTokens)) output")
                                            .font(Theme.font(size: 12))
                                            .foregroundStyle(Theme.Colors.textSecondary)
                                    }

                                    Spacer()

                                    if selectedProviderId == provider.provider {
                                        Image(systemName: "checkmark")
                                            .font(Theme.font(size: 14))
                                            .foregroundStyle(Theme.Colors.accent)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, Theme.scaled(16))
                                .padding(.vertical, Theme.scaled(12))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider().padding(.leading, Theme.scaled(16))
                        }
                    }

                    Text("5% markup on provider pricing")
                        .font(Theme.font(size: 11))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(.horizontal, Theme.scaled(16))
                        .padding(.bottom, Theme.scaled(16))
                }
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxHeight: Theme.scaled(520))
        .background(Theme.Colors.backgroundStart)
        .clipShape(RoundedRectangle(cornerRadius: Theme.scaled(16)))
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.horizontal, Theme.scaled(16))
    }
    
    private func formatPrice(_ price: Double) -> String {
        String(format: "$%.4f", price)
    }
}
