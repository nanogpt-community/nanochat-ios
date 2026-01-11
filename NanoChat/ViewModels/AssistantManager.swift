import Foundation
import SwiftUI

@MainActor
final class AssistantManager: ObservableObject {
    @Published var assistants: [AssistantResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedAssistant: AssistantResponse?

    private let api = NanoChatAPI.shared

    func loadAssistants() async {
        isLoading = true
        defer { isLoading = false }

        do {
            assistants = try await api.getAssistants()

            // Try to restore the last used assistant
            let lastUsedAssistantId = UserDefaults.standard.string(forKey: "lastUsedAssistant")

            if let lastUsedAssistantId = lastUsedAssistantId,
               let lastAssistant = assistants.first(where: { $0.id == lastUsedAssistantId }) {
                selectedAssistant = lastAssistant
            } else if let defaultAssistant = assistants.first(where: { $0.isDefault }) {
                // Fall back to default assistant
                selectedAssistant = defaultAssistant
            } else if let firstAssistant = assistants.first {
                // Fall back to first assistant
                selectedAssistant = firstAssistant
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectAssistant(_ assistant: AssistantResponse) {
        selectedAssistant = assistant
        UserDefaults.standard.set(assistant.id, forKey: "lastUsedAssistant")
    }
}
