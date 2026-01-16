import Foundation
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var conversations: [ConversationResponse] = []
    @Published var messages: [MessageResponse] = []
    @Published var currentConversation: ConversationResponse?
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var webSearchEnabled = false
    @Published var webSearchMode: WebSearchMode = .off
    @Published var webSearchProvider: WebSearchProvider = .linkup
    @Published var selectedProviderId: String?
    @Published var availableProviders: [ProviderInfo] = []
    @Published var supportsProviderSelection = false

    @Published var imageParams: [String: AnyCodable] = [:]
    @Published var videoParams: [String: AnyCodable] = [:]

    @Published var starredMessages: [MessageResponse] = []
    @Published var isLoadingStarred = false

    @Published var followUpSuggestions: [String] = []
    @Published var isLoadingFollowUps = false

    private let api = NanoChatAPI.shared

    func loadConversations() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedConversations = try await api.getConversations()
            conversations = loadedConversations
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMessages(conversationId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedMessages = try await api.getMessages(conversationId: conversationId)
            messages = loadedMessages
            if let conversation = conversations.first(where: { $0.id == conversationId }) {
                currentConversation = conversation
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadStarredMessages() async {
        isLoadingStarred = true
        defer { isLoadingStarred = false }

        do {
            let loadedMessages = try await api.getStarredMessages()
            starredMessages = loadedMessages
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createConversation(title: String? = nil, projectId: String? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let newConversation: ConversationResponse
            if let title = title {
                newConversation = try await api.createConversation(
                    title: title, projectId: projectId)
            } else {
                newConversation = try await api.createConversation(
                    title: "New Chat", projectId: projectId)
            }

            conversations.insert(newConversation, at: 0)
            currentConversation = newConversation
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setConversationProject(conversationId: String, projectId: String?) async throws {
        isLoading = true
        defer { isLoading = false }

        try await api.setConversationProject(
            conversationId: conversationId, projectId: projectId)
        await loadConversations()
    }

    func sendMessage(
        message: String,
        modelId: String,
        conversationId: String? = nil,
        assistantId: String? = nil,
        webSearchEnabled: Bool = false,
        webSearchMode: String? = nil,
        webSearchProvider: String? = nil,
        providerId: String? = nil,
        images: [ImageAttachment]? = nil,
        documents: [DocumentAttachment]? = nil,
        imageParams: [String: AnyCodable]? = nil,
        videoParams: [String: AnyCodable]? = nil
    ) async {
        guard !message.isEmpty || images?.isEmpty == false || documents?.isEmpty == false else {
            return
        }

        isGenerating = true

        do {
            let response = try await api.generateMessage(
                message: message,
                modelId: modelId,
                conversationId: conversationId ?? currentConversation?.id,
                assistantId: assistantId,
                webSearchEnabled: webSearchEnabled,
                webSearchMode: webSearchMode,
                webSearchProvider: webSearchProvider,
                providerId: providerId,
                images: images,
                documents: documents,
                imageParams: imageParams,
                videoParams: videoParams
            )

            let targetConversationId =
                conversationId ?? currentConversation?.id ?? response.conversationId

            for i in 0..<120 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)

                if i % 3 == 0 {
                    await loadConversations()
                }

                await loadMessages(conversationId: targetConversationId)

                let conversation = conversations.first { $0.id == targetConversationId }
                let isStillGenerating = conversation?.generating ?? false

                if let lastMessage = messages.last,
                    lastMessage.role == "assistant",
                    !lastMessage.content.isEmpty,
                    !isStillGenerating
                {
                    // Haptic feedback when message is received
                    HapticManager.shared.messageReceived()
                    break
                }
            }

            isGenerating = false
        } catch {
            errorMessage = error.localizedDescription
            isGenerating = false
        }
    }

    func fetchModelProviders(modelId: String) async {
        do {
            let response = try await api.fetchModelProviders(modelId: modelId)
            availableProviders = response.providers.filter { $0.available }
            supportsProviderSelection = response.supportsProviderSelection

            if !supportsProviderSelection {
                selectedProviderId = nil
            } else if let currentProvider = selectedProviderId,
                !availableProviders.contains(where: { $0.provider == currentProvider })
            {
                selectedProviderId = nil
            }
        } catch {
            errorMessage = error.localizedDescription
            supportsProviderSelection = false
            availableProviders = []
        }
    }

    func selectProvider(providerId: String?) {
        selectedProviderId = providerId
    }

    func deleteConversation(id: String) async {
        do {
            try await api.deleteConversation(id: id)
            conversations.removeAll { $0.id == id }
            if currentConversation?.id == id {
                currentConversation = nil
                messages = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Follow-Up Questions

    func fetchFollowUpQuestions(conversationId: String, messageId: String) async {
        isLoadingFollowUps = true
        defer { isLoadingFollowUps = false }

        do {
            let suggestions = try await api.generateFollowUpQuestions(
                conversationId: conversationId,
                messageId: messageId
            )
            followUpSuggestions = suggestions
        } catch {
            followUpSuggestions = []
        }
    }

    func clearFollowUpSuggestions() {
        followUpSuggestions = []
    }

    func removeStarredMessage(messageId: String) {
        starredMessages.removeAll { $0.id == messageId }
    }
}
