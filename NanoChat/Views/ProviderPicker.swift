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
                .font(.headline)
                .foregroundStyle(Theme.Colors.text)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.glassBackground)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Web Search Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Web Search")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, 16)
                        
                        // Search Mode Selector
                        HStack(spacing: 8) {
                            ForEach(WebSearchMode.allCases) { mode in
                                Button {
                                    withAnimation {
                                        webSearchMode = mode
                                    }
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(mode.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        if !mode.costDisplay.isEmpty {
                                            Text(mode.costDisplay)
                                                .font(.caption2)
                                                .opacity(0.7)
                                        }
                                    }
                                    .padding(.vertical, 8)
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
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                webSearchMode == mode 
                                                ? Theme.Colors.accent 
                                                : Color.clear, 
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Search Provider Selector (Only if not off)
                        if webSearchMode != .off {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Search Provider")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                                    .padding(.horizontal, 16)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(WebSearchProvider.allCases) { provider in
                                            Button {
                                                webSearchProvider = provider
                                            } label: {
                                                HStack(spacing: 6) {
                                                    Image(systemName: provider.iconName)
                                                        .font(.caption)
                                                    Text(provider.displayName)
                                                        .font(.caption)
                                                }
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 12)
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
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.top, 16)

                    Divider()

                    // MARK: - Model Provider Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Model Provider")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)

                        // Auto Option
                        Button {
                            onSelectProvider(nil)
                        } label: {
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundStyle(Theme.Colors.primary)
                                Text("Auto (Recommended)")
                                    .font(.body)
                                    .foregroundStyle(Theme.Colors.text)
                                Spacer()
                                if selectedProviderId == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.Colors.accent)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider().padding(.leading, 16)
                        
                        // Providers List
                        ForEach(availableProviders) { provider in
                            Button {
                                onSelectProvider(provider.provider)
                            } label: {
                                HStack {
                                    Image(systemName: "server.rack")
                                        .foregroundStyle(Theme.Colors.primary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(provider.provider.capitalized)
                                            .font(.body)
                                            .foregroundStyle(Theme.Colors.text)
                                        Text("\(formatPrice(provider.pricing.inputPer1kTokens)) input / \(formatPrice(provider.pricing.outputPer1kTokens)) output")
                                            .font(.caption)
                                            .foregroundStyle(Theme.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedProviderId == provider.provider {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.Colors.accent)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Divider().padding(.leading, 16)
                        }
                    }
                    
                    Text("5% markup on provider pricing")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxHeight: 520)
        .background(Theme.Colors.backgroundStart)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 16)
    }
    
    private func formatPrice(_ price: Double) -> String {
        String(format: "$%.4f", price)
    }
}
