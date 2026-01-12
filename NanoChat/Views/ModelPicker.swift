import SwiftUI

struct ModelPicker: View {
    let groupedModels: [ModelGroup]
    let selectedModelId: String?
    let onSelect: (UserModel) -> Void
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.lg) {
                        ForEach(groupedModels) { group in
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text(group.name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                                    .padding(.horizontal, Theme.Spacing.sm)
                                
                                VStack(spacing: Theme.Spacing.sm) {
                                    ForEach(group.models) { model in
                                        Button {
                                            onSelect(model)
                                            dismiss()
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(model.name ?? model.modelId)
                                                        .font(.subheadline)
                                                        .foregroundStyle(Theme.Colors.text)
                                                    
                                                    ModelCapabilityBadges(
                                                        capabilities: model.capabilities,
                                                        subscriptionIncluded: model.subscriptionIncluded
                                                    )
                                                    .font(.caption2)
                                                }
                                                
                                                Spacer()
                                                
                                                if selectedModelId == model.modelId {
                                                    Image(systemName: "checkmark")
                                                        .font(.subheadline)
                                                        .foregroundStyle(Theme.Colors.secondary)
                                                }
                                            }
                                            .padding(Theme.Spacing.md)
                                            .glassCard()
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
}
