import SwiftUI

struct AvailableModelsView: View {
    @ObservedObject var modelManager: ModelManager
    @State private var searchText = ""
    @State private var showSubscriptionOnly = false
    @State private var showImageOnly = false
    @State private var showVideoOnly = false
    
    var filteredModels: [UserModel] {
        modelManager.allModels.filter { model in
            // Filter disabled models first
            // if !model.enabled { return false }
            
            // Search filter
            if !searchText.isEmpty {
                let name = model.name ?? model.modelId
                if !name.localizedCaseInsensitiveContains(searchText) {
                    return false
                }
            }
            
            // Capability filters
            if showSubscriptionOnly {
                if !(model.subscriptionIncluded ?? false) { return false }
            }
            
            if showImageOnly {
                if !(model.capabilities?.images ?? false) { return false }
            }
            
            if showVideoOnly {
                if !(model.capabilities?.video ?? false) { return false }
            }
            
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Header
            VStack(spacing: Theme.Spacing.md) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.Colors.textTertiary)
                    
                    TextField("Search models", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Theme.Colors.text)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.glassBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                
                // Filter Toggles
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        FilterToggle(
                            title: "Subscription",
                            icon: "ticket.fill",
                            color: .yellow,
                            isOn: $showSubscriptionOnly
                        )
                        
                        FilterToggle(
                            title: "Image",
                            icon: "photo",
                            color: Theme.Colors.success,
                            isOn: $showImageOnly
                        )
                        
                        FilterToggle(
                            title: "Video",
                            icon: "video.fill",
                            color: Theme.Colors.warning,
                            isOn: $showVideoOnly
                        )
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // List
            List {
                Section {
                    ForEach(filteredModels) { model in
                        Button {
                            modelManager.toggleModelVisibility(id: model.modelId)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(model.name ?? model.modelId)
                                        .foregroundStyle(Theme.Colors.text)
                                    
                                    ModelCapabilityBadges(
                                        capabilities: model.capabilities,
                                        subscriptionIncluded: model.subscriptionIncluded
                                    )
                                    .font(.caption2)
                                }
                                
                                Spacer()
                                
                                if !modelManager.hiddenModelIds.contains(model.modelId) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.Colors.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Available Models")
                } footer: {
                    Text("Select which models appear in your picker. This won't affect existing conversations.")
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Available Models")
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.Gradients.background)
    }
}

struct FilterToggle: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        Button {
            withAnimation {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isOn ? color : Theme.Colors.glassBackground)
            .foregroundStyle(isOn ? .white : Theme.Colors.text)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isOn ? color : Theme.Colors.glassBorder, lineWidth: 1)
            )
        }
    }
}
