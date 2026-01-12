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
                
                GlassList {
                    ForEach(groupedModels) { group in
                        GlassListSection(group.name) {
                            ForEach(group.models) { model in
                                GlassListRow {
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
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Model")
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
}
