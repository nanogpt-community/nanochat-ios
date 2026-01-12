import SwiftUI

struct ProviderPicker: View {
    let availableProviders: [ProviderInfo]
    let selectedProviderId: String?
    let onSelect: (String?) -> Void
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background
                    .ignoresSafeArea()
                
                GlassList {
                    GlassListSection("Select Provider") {
                        // Auto Option
                        GlassListRow {
                            Button {
                                onSelect(nil)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "server.rack")
                                        .foregroundStyle(Theme.Colors.primary)
                                    Text("Auto")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.Colors.text)
                                    Spacer()
                                    if selectedProviderId == nil {
                                        Image(systemName: "checkmark")
                                            .font(.subheadline)
                                            .foregroundStyle(Theme.Colors.primary)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Providers
                        ForEach(availableProviders) { provider in
                            GlassListRow {
                                Button {
                                    onSelect(provider.provider)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "server.rack")
                                            .foregroundStyle(Theme.Colors.primary)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(provider.provider.capitalized)
                                                .font(.subheadline)
                                                .foregroundStyle(Theme.Colors.text)
                                            Text("\(formatPrice(provider.pricing.inputPer1kTokens)) input / \(formatPrice(provider.pricing.outputPer1kTokens)) output")
                                                .font(.caption2)
                                                .foregroundStyle(Theme.Colors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedProviderId == provider.provider {
                                            Image(systemName: "checkmark")
                                                .font(.subheadline)
                                                .foregroundStyle(Theme.Colors.primary)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Text("5% markup on provider pricing")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
                }
            }
            .navigationTitle("Model Provider")
            .navigationBarTitleDisplayMode(.inline)
            .liquidGlassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.text)
                }
            }
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        String(format: "$%.4f", price)
    }
}
