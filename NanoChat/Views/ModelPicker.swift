import SwiftUI

struct ModelPicker: View {
    let groupedModels: [ModelGroup]
    let selectedModelId: String?
    let onSelect: (UserModel) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var infoModel: UserModel?

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
                                    HStack(spacing: Theme.Spacing.sm) {
                                        Button {
                                            onSelect(model)
                                            dismiss()
                                        } label: {
                                            HStack(spacing: Theme.Spacing.sm) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(model.name ?? model.modelId)
                                                        .font(.subheadline)
                                                        .foregroundStyle(Theme.Colors.text)

                                                    ModelCapabilityBadges(
                                                        capabilities: model.capabilities,
                                                        subscriptionIncluded: model
                                                            .subscriptionIncluded
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
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                        Button {
                                            infoModel = model
                                        } label: {
                                            Image(systemName: "info.circle")
                                                .font(.subheadline)
                                                .foregroundStyle(Theme.Colors.textSecondary)
                                                .padding(.horizontal, Theme.Spacing.xs)
                                        }
                                        .buttonStyle(.plain)
                                    }
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
        .sheet(item: $infoModel) { model in
            ModelInfoView(model: model)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
