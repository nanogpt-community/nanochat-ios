import SwiftUI

struct ModelPicker: View {
    let groupedModels: [ModelGroup]
    let selectedModelId: String?
    let onSelect: (UserModel) -> Void

    @State private var infoModel: UserModel?

    var body: some View {
        VStack(spacing: 0) {
            // Header for dropdown look
            Text("Select Model")
                .font(.headline)
                .foregroundStyle(Theme.Colors.text)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.glassBackground)
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(groupedModels) { group in
                        Section(header: 
                            Text(group.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Theme.Colors.glassBackground)
                        ) {
                            ForEach(group.models) { model in
                                Button {
                                    onSelect(model)
                                } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(model.name ?? model.modelId)
                                                .font(.body)
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
                                                .font(.body)
                                                .foregroundStyle(Theme.Colors.accent)
                                        }
                                        
                                        // Info Button
                                        Button {
                                            infoModel = model
                                        } label: {
                                            Image(systemName: "info.circle")
                                                .foregroundStyle(Theme.Colors.textTertiary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedModelId == model.modelId ? Theme.Colors.secondary.opacity(0.1) : Color.clear
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxHeight: 400) // Constraint height for dropdown feel
        .background(Theme.Colors.backgroundStart)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 16)
        .sheet(item: $infoModel) { model in
            ModelInfoView(model: model)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
