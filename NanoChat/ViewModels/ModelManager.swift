import Foundation
import SwiftUI

@MainActor
final class ModelManager: ObservableObject {
    @Published var allModels: [UserModel] = []
    @Published var groupedModels: [ModelGroup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedModel: UserModel?

    private let api = NanoChatAPI.shared

    func loadModels() async {
        isLoading = true
        defer { isLoading = false }

        do {
            allModels = try await api.getUserModels()
            groupedModels = allModels.filterEnabled().groupedByProvider()

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
            errorMessage = error.localizedDescription
        }
    }

    func selectModel(_ model: UserModel) {
        selectedModel = model
    }
}
