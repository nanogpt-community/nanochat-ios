import SwiftUI

struct ModelPicker: View {
    let groupedModels: [ModelGroup]
    let selectedModelId: String?
    let onSelect: (UserModel) -> Void
    var onDismiss: (() -> Void)?

    @State private var searchText = ""
    @State private var infoModel: UserModel?

    private var filteredGroups: [ModelGroup] {
        if searchText.isEmpty {
            return groupedModels
        }
        return groupedModels.compactMap { group in
            let filtered = group.models.filter { model in
                (model.name ?? model.modelId).localizedCaseInsensitiveContains(searchText)
                    || model.modelId.localizedCaseInsensitiveContains(searchText)
            }
            if filtered.isEmpty { return nil }
            return ModelGroup(name: group.name, models: filtered)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                headerView

                // Search Bar
                searchBar
                    .padding(.horizontal, Theme.scaled(16))
                    .padding(.vertical, Theme.scaled(12))

                Divider()
                    .background(Theme.Colors.border)

                // Models List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredGroups) { group in
                                // Provider Section Header
                                providerHeader(group.name)

                                // Models in this group
                                ForEach(group.models) { model in
                                    ModelRow(
                                        model: model,
                                        isSelected: selectedModelId == model.modelId,
                                        onSelect: {
                                            onSelect(model)
                                        },
                                        onInfo: {
                                            infoModel = model
                                        }
                                    )
                                    .id(model.modelId)
                                }
                            }
                        }
                        .padding(.bottom, Theme.scaled(20))
                    }
                    .scrollIndicators(.hidden)
                    .onAppear {
                        if let selectedId = selectedModelId {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(selectedId, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: geometry.size.height * 0.75)
            .background(Theme.Colors.backgroundStart)
            .clipShape(RoundedRectangle(cornerRadius: Theme.scaled(20)))
            .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
            .padding(.horizontal, Theme.scaled(16))
        }
        .sheet(item: $infoModel) { model in
            ModelInfoView(model: model)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Select Model")
                .font(Theme.font(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Colors.text)

            Spacer()

            if let onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(Theme.font(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: Theme.scaled(28), height: Theme.scaled(28))
                        .background(Theme.Colors.glassSurface)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, Theme.scaled(20))
        .padding(.top, Theme.scaled(20))
        .padding(.bottom, Theme.scaled(4))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.scaled(10)) {
            Image(systemName: "magnifyingglass")
                .font(Theme.font(size: 16))
                .foregroundStyle(Theme.Colors.textTertiary)

            TextField("Search models...", text: $searchText)
                .font(Theme.font(size: 16))
                .foregroundStyle(Theme.Colors.text)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(Theme.font(size: 16))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, Theme.scaled(12))
        .padding(.vertical, Theme.scaled(10))
        .background(Theme.Colors.glassSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.scaled(10)))
    }

    // MARK: - Provider Header

    private func providerHeader(_ name: String) -> some View {
        HStack(spacing: Theme.scaled(8)) {
            // Provider icon
            providerIcon(for: name)
                .frame(width: Theme.scaled(24), height: Theme.scaled(24))

            Text(name.capitalized)
                .font(Theme.font(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, Theme.scaled(20))
        .padding(.top, Theme.scaled(16))
        .padding(.bottom, Theme.scaled(8))
    }

    private func providerIcon(for name: String) -> some View {
        let config = providerIconConfig(for: name)
        return Image(systemName: config.icon)
            .font(Theme.font(size: 16))
            .foregroundStyle(config.color)
    }

    private func providerIconConfig(for name: String) -> (icon: String, color: Color) {
        switch name.lowercased() {
        case "openai":
            return ("circle.hexagongrid", .green)
        case "anthropic":
            return ("a.circle.fill", .orange)
        case "google":
            return ("g.circle.fill", .blue)
        case "nanogpt":
            return ("sparkles", Theme.Colors.accent)
        default:
            return ("cpu", Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Model Row

struct ModelRow: View {
    let model: UserModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onInfo: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.scaled(12)) {
                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected
                                ? Theme.Colors.accent : Theme.Colors.textTertiary.opacity(0.5),
                            lineWidth: 2
                        )
                        .frame(width: Theme.scaled(22), height: Theme.scaled(22))

                    if isSelected {
                        Circle()
                            .fill(Theme.Colors.accent)
                            .frame(width: Theme.scaled(14), height: Theme.scaled(14))
                    }
                }

                // Model info
                VStack(alignment: .leading, spacing: Theme.scaled(4)) {
                    Text(model.name ?? model.modelId)
                        .font(Theme.font(size: 16, weight: .medium))
                        .foregroundStyle(Theme.Colors.text)
                        .lineLimit(1)

                    // Capabilities row
                    HStack(spacing: Theme.scaled(8)) {
                        if let capabilities = model.capabilities {
                            if capabilities.vision == true {
                                capabilityPill(icon: "eye", text: "Vision", color: .blue)
                            }
                            if capabilities.reasoning == true {
                                capabilityPill(icon: "brain", text: "Reasoning", color: .purple)
                            }
                            if capabilities.images == true {
                                capabilityPill(icon: "photo", text: "Images", color: .green)
                            }
                            if capabilities.video == true {
                                capabilityPill(icon: "video", text: "Video", color: .orange)
                            }
                        }

                        if model.subscriptionIncluded == true {
                            capabilityPill(
                                icon: "checkmark.seal.fill", text: "Free",
                                color: Theme.Colors.success)
                        }
                    }
                }

                Spacer()

                // Info button
                Button(action: onInfo) {
                    Image(systemName: "info.circle")
                        .font(Theme.font(size: 18))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.scaled(20))
            .padding(.vertical, Theme.scaled(14))
            .background(isSelected ? Theme.Colors.accent.opacity(0.25) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.scaled(8))
                    .strokeBorder(
                        isSelected ? Theme.Colors.accent.opacity(0.5) : Color.clear, lineWidth: 1
                    )
                    .padding(.horizontal, Theme.scaled(8))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func capabilityPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: Theme.scaled(3)) {
            Image(systemName: icon)
                .font(Theme.font(size: 9))
            Text(text)
                .font(Theme.font(size: 10, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, Theme.scaled(6))
        .padding(.vertical, Theme.scaled(3))
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ModelPicker(
            groupedModels: [],
            selectedModelId: nil,
            onSelect: { _ in },
            onDismiss: {}
        )
    }
}
