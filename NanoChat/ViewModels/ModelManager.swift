import Foundation
import SwiftUI

@MainActor
final class ModelManager: ObservableObject {
    @Published var allModels: [UserModel] = []
    @Published var groupedModels: [ModelGroup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedModel: UserModel?
    @Published var hiddenModelIds: Set<String> = []

    private let api = NanoChatAPI.shared

    func loadModels(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        // 1. Try Cache First
        if !forceRefresh {
            if let cachedData = UserDefaults.standard.data(forKey: "cachedModels"),
                let cachedModels = try? JSONDecoder().decode([UserModel].self, from: cachedData)
            {
                print("Loaded models from cache")
                self.allModels = cachedModels
                refreshVisibilityFromServerState()
                self.updateGroupedModels()
                self.selectDefaultModelIfNeeded()

                // Check if cache is fresh enough (e.g. 1 hour)
                let lastFetch = UserDefaults.standard.double(forKey: "lastModelFetchTime")
                let now = Date().timeIntervalSince1970
                if now - lastFetch < 3600 {  // 1 hour
                    return  // Cache is fresh, skip API call
                }
            }
        }

        // 2. Fetch from API
        do {
            let fetchedModels = try await api.getUserModels()

            // Update only if changed (optional optimization, but simple replace is fine)
            allModels = fetchedModels

            // Save to Cache
            if let data = try? JSONEncoder().encode(allModels) {
                UserDefaults.standard.set(data, forKey: "cachedModels")
                UserDefaults.standard.set(
                    Date().timeIntervalSince1970, forKey: "lastModelFetchTime")
            }

            // Load hidden models
            refreshVisibilityFromServerState()

            updateGroupedModels()
            selectDefaultModelIfNeeded()

        } catch {
            errorMessage = error.localizedDescription
            // If API fails but we have cache (loaded above), we might want to keep silent or show a toast?
            // Current behavior shows error message which is fine.
        }
    }

    private func refreshVisibilityFromServerState() {
        hiddenModelIds = Set(allModels.filter { !$0.enabled }.map { $0.modelId })
    }

    private func selectDefaultModelIfNeeded() {
        let visibleModels = allModels.filter { !hiddenModelIds.contains($0.modelId) }

        // Try to restore the last used model
        let lastUsedModelId = UserDefaults.standard.string(forKey: "lastUsedModel")

        if let lastUsedModelId = lastUsedModelId,
            let lastModel = visibleModels.first(where: { $0.modelId == lastUsedModelId })
        {
            selectedModel = lastModel
        } else if let defaultModel = visibleModels.first(where: { $0.pinned }) {
            // Fall back to pinned model
            selectedModel = defaultModel
        } else if let firstModel = visibleModels.first {
            // Fall back to first enabled model
            selectedModel = firstModel
        }
    }

    func selectModel(_ model: UserModel) {
        selectedModel = model
    }

    func setModelEnabled(id: String, enabled: Bool) async {
        guard let index = allModels.firstIndex(where: { $0.modelId == id }) else { return }

        do {
            try await api.setUserModelEnabled(
                provider: allModels[index].provider, modelId: id, enabled: enabled)

            let updated = UserModel(
                modelId: allModels[index].modelId,
                provider: allModels[index].provider,
                enabled: enabled,
                pinned: allModels[index].pinned,
                name: allModels[index].name,
                description: allModels[index].description,
                capabilities: allModels[index].capabilities,
                costEstimate: allModels[index].costEstimate,
                subscriptionIncluded: allModels[index].subscriptionIncluded,
                resolutions: allModels[index].resolutions,
                additionalParams: allModels[index].additionalParams,
                maxImages: allModels[index].maxImages,
                defaultSettings: allModels[index].defaultSettings
            )
            allModels[index] = updated

            if enabled {
                hiddenModelIds.remove(id)
            } else {
                hiddenModelIds.insert(id)

                if selectedModel?.modelId == id {
                    selectedModel = allModels.first(where: {
                        $0.enabled && !hiddenModelIds.contains($0.modelId)
                    })
                }
            }

            if let data = try? JSONEncoder().encode(allModels) {
                UserDefaults.standard.set(data, forKey: "cachedModels")
                UserDefaults.standard.set(
                    Date().timeIntervalSince1970, forKey: "lastModelFetchTime")
            }
            updateGroupedModels()
            selectDefaultModelIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveLastProvider(for modelId: String, providerId: String) {
        var lastProviders =
            UserDefaults.standard.dictionary(forKey: "lastProvidersForModel") as? [String: String]
            ?? [:]
        lastProviders[modelId] = providerId
        UserDefaults.standard.set(lastProviders, forKey: "lastProvidersForModel")
    }

    func getLastProvider(for modelId: String) -> String? {
        let lastProviders =
            UserDefaults.standard.dictionary(forKey: "lastProvidersForModel") as? [String: String]
        return lastProviders?[modelId]
    }

    private func updateGroupedModels() {
        groupedModels =
            allModels
            // Hide disabled models to match server-enabled state.
            .filter { !hiddenModelIds.contains($0.modelId) }
            .groupedByProvider()
    }
}
