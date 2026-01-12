import SwiftUI

struct ProviderPicker: View {
    let availableProviders: [ProviderInfo]
    let selectedProviderId: String?
    let onSelect: (String?) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        onSelect(nil)
                    }) {
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundColor(Theme.Colors.primary)
                            Text("Auto")
                                .foregroundColor(Theme.Colors.text)
                            Spacer()
                            if selectedProviderId == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                    }

                    ForEach(availableProviders) { provider in
                        Button(action: {
                            onSelect(provider.provider)
                        }) {
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundColor(Theme.Colors.primary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(provider.provider.capitalized)
                                        .foregroundColor(Theme.Colors.text)
                                    Text("\(formatPrice(provider.pricing.inputPer1kTokens)) input / \(formatPrice(provider.pricing.outputPer1kTokens)) output")
                                        .font(.caption)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                                Spacer()
                                if selectedProviderId == provider.provider {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Theme.Colors.primary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select Provider")
                } footer: {
                    Text("5% markup on provider pricing")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Model Provider")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func formatPrice(_ price: Double) -> String {
        String(format: "$%.4f", price)
    }
}
