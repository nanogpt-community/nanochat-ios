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

    func loadModels() async {
        isLoading = true
        defer { isLoading = false }

        do {
            allModels = try await api.getUserModels()
            
            // Load hidden models
            if UserDefaults.standard.object(forKey: "hiddenModelIds") != nil {
                if let savedHiddenIds = UserDefaults.standard.array(forKey: "hiddenModelIds") as? [String] {
                    hiddenModelIds = Set(savedHiddenIds)
                }
            } else {
                // First time load: hide models that are disabled on server
                let serverDisabledIds = allModels.filter { !$0.enabled }.map { $0.modelId }
                hiddenModelIds = Set(serverDisabledIds)
            }
            
            updateGroupedModels()

            // Try to restore the last used model
            let lastUsedModelId = UserDefaults.standard.string(forKey: "lastUsedModel")

            if let lastUsedModelId = lastUsedModelId,
               let lastModel = allModels.filterEnabled().first(where: { $0.modelId == lastUsedModelId }) {
                selectedModel = lastModel
                print("Restored last used model: \(lastModel.modelId)")
            } else if let defaultModel = allModels.filterEnabled().first(where: { $0.pinned }) {
                // Fall back to pinned model
                selectedModel = defaultModel
                print("Using pinned model: \(defaultModel.modelId)")
            } else if let firstModel = allModels.filterEnabled().first {
                // Fall back to first enabled model
                selectedModel = firstModel
                print("Using first enabled model: \(firstModel.modelId)")
            }
        } catch {
            print("CRITICAL ERROR loading models: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("Type mismatch: \(type), context: \(context)")
                case .valueNotFound(let type, let context):
                    print("Value not found: \(type), context: \(context)")
                case .keyNotFound(let key, let context):
                    print("Key not found: \(key), context: \(context)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
            errorMessage = error.localizedDescription
        }
    }

    func selectModel(_ model: UserModel) {
        selectedModel = model
    }
    
    func toggleModelVisibility(id: String) {
        if hiddenModelIds.contains(id) {
            hiddenModelIds.remove(id)
        } else {
            hiddenModelIds.insert(id)
        }
        
        UserDefaults.standard.set(Array(hiddenModelIds), forKey: "hiddenModelIds")
        updateGroupedModels()
    }

    func saveLastProvider(for modelId: String, providerId: String) {
        var lastProviders = UserDefaults.standard.dictionary(forKey: "lastProvidersForModel") as? [String: String] ?? [:]
        lastProviders[modelId] = providerId
        UserDefaults.standard.set(lastProviders, forKey: "lastProvidersForModel")
    }

    func getLastProvider(for modelId: String) -> String? {
        let lastProviders = UserDefaults.standard.dictionary(forKey: "lastProvidersForModel") as? [String: String]
        return lastProviders?[modelId]
    }
    
    private func updateGroupedModels() {
        groupedModels = allModels
            // .filterEnabled() <-- REMOVED: We now rely purely on hiddenModelIds for user preference
            .filter { !hiddenModelIds.contains($0.modelId) }
            .groupedByProvider()
    }
}
