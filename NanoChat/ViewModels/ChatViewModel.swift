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

    @Published var followUpSuggestions: [String] = []
    @Published var isLoadingFollowUps = false

    private let api = NanoChatAPI.shared

    func loadConversations() async {
        print("ChatViewModel.loadConversations() called")
        isLoading = true
        defer { isLoading = false }

        do {
            print("Fetching conversations from API...")
            let loadedConversations = try await api.getConversations()
            print("Successfully loaded \(loadedConversations.count) conversations")
            conversations = loadedConversations
        } catch {
            print("Error loading conversations: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
   func loadMessages(conversationId: String) async {
        isLoading = true
        defer { isLoading = false }

        print("Loading messages for conversation: \(conversationId)")
        do {
            let loadedMessages = try await api.getMessages(conversationId: conversationId)
            print("Loaded \(loadedMessages.count) messages")
            messages = loadedMessages
            if let conversation = conversations.first(where: { $0.id == conversationId }) {
                currentConversation = conversation
            }
        } catch {
            print("Error loading messages: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    func createConversation(title: String? = nil, projectId: String? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let newConversation: ConversationResponse
            if let title = title {
                newConversation = try await api.createConversation(title: title, projectId: projectId)
            } else {
                newConversation = try await api.createConversation(title: "New Chat", projectId: projectId)
            }

            conversations.insert(newConversation, at: 0)
            currentConversation = newConversation
        } catch {
            errorMessage = error.localizedDescription
        }
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
        guard !message.isEmpty || images?.isEmpty == false || documents?.isEmpty == false else { return }

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

            print("Generate message response: \(response)")

            let targetConversationId = conversationId ?? currentConversation?.id ?? response.conversationId

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
                   !isStillGenerating {
                    print("Assistant response completed, stopping poll")
                    break
                }

                if let lastMessage = messages.last,
                   lastMessage.role == "assistant",
                   !lastMessage.content.isEmpty {
                    print("Still generating... (current content length: \(lastMessage.content.count))")
                }
            }

            isGenerating = false
        } catch {
            print("Error sending message: \(error)")
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
                      !availableProviders.contains(where: { $0.provider == currentProvider }) {
                selectedProviderId = nil
            }
        } catch {
            print("Error fetching model providers: \(error)")
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
            print("Loaded \(suggestions.count) follow-up suggestions")
        } catch {
            print("Failed to fetch follow-up questions: \(error)")
            followUpSuggestions = []
        }
    }

    func clearFollowUpSuggestions() {
        followUpSuggestions = []
    }
}
