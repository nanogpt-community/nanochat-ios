import SwiftUI

struct ModelPicker: View {
    let groupedModels: [ModelGroup]
    let selectedModelId: String?
    let onSelect: (UserModel) -> Void
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedModels) { group in
                    Section(group.name) {
                        ForEach(group.models) { model in
                            Button(action: {
                                onSelect(model)
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(model.name ?? model.modelId)
                                            .foregroundColor(Theme.Colors.text)
                                        
                                        ModelCapabilityBadges(
                                            capabilities: model.capabilities,
                                            subscriptionIncluded: model.subscriptionIncluded
                                        )
                                        .font(.caption2)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedModelId == model.modelId {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Theme.Colors.secondary)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
