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

    // Streaming properties
    @Published var streamingContent: String = ""
    @Published var streamingReasoning: String = ""
    @Published var streamingMessageId: String?
    @Published var streamingConversationId: String?

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

        // Reuse existing empty "New Chat" if available
        if title == nil {
            if let latest = conversations.first,
               latest.title == "New Chat",
               latest.projectId == projectId {
                
                // Verify it has no messages to be safe
                if let msgs = try? await api.getMessages(conversationId: latest.id), msgs.isEmpty {
                    currentConversation = latest
                    return
                }
            }
        }

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
        videoParams: [String: AnyCodable]? = nil,
        reasoningEffort: String? = nil
    ) async {
        guard !message.isEmpty || images?.isEmpty == false || documents?.isEmpty == false else {
            return
        }

        // Use SSE streaming for text models (no images/imageParams/videoParams)
        let isImageOrVideoGeneration =
            images?.isEmpty == false || imageParams?.isEmpty == false
            || videoParams?.isEmpty == false

        if !isImageOrVideoGeneration {
            await sendMessageWithStreaming(
                message: message,
                modelId: modelId,
                conversationId: conversationId,
                assistantId: assistantId,
                webSearchEnabled: webSearchEnabled,
                webSearchMode: webSearchMode,
                webSearchProvider: webSearchProvider,
                providerId: providerId,
                documents: documents,
                reasoningEffort: reasoningEffort
            )
        } else {
            // Fallback to polling for image/video generation
            await sendMessageWithPolling(
                message: message,
                modelId: modelId,
                conversationId: conversationId,
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
        }
    }

    /// Send message using SSE streaming for real-time token delivery
    private func sendMessageWithStreaming(
        message: String,
        modelId: String,
        conversationId: String? = nil,
        assistantId: String? = nil,
        webSearchEnabled: Bool = false,
        webSearchMode: String? = nil,
        webSearchProvider: String? = nil,
        providerId: String? = nil,
        documents: [DocumentAttachment]? = nil,
        reasoningEffort: String? = nil
    ) async {
        isGenerating = true
        streamingContent = ""
        streamingReasoning = ""
        streamingMessageId = nil
        streamingConversationId = nil

        var receivedAnyEvent = false

        do {
            let stream = api.generateMessageStream(
                message: message,
                modelId: modelId,
                conversationId: conversationId ?? currentConversation?.id,
                assistantId: assistantId,
                projectId: currentConversation?.projectId,
                webSearchEnabled: webSearchEnabled,
                webSearchMode: webSearchMode,
                webSearchProvider: webSearchProvider,
                providerId: providerId,
                documents: documents,
                reasoningEffort: reasoningEffort
            )

            for try await event in stream {
                receivedAnyEvent = true

                switch event {
                case .messageStart(let convId, let msgId):
                    streamingConversationId = convId
                    streamingMessageId = msgId

                    // Update current conversation if this is a new one
                    if conversationId == nil && currentConversation?.id != convId {
                        await loadConversations()
                        if let conversation = conversations.first(where: { $0.id == convId }) {
                            currentConversation = conversation
                        }
                    }

                    // Load messages to get the user message that was created
                    await loadMessages(conversationId: convId)

                case .delta(let content, let reasoning):
                    streamingContent += content
                    if !reasoning.isEmpty {
                        streamingReasoning += reasoning
                    }

                case .messageComplete(_, _, _):
                    // Reload messages to get the final saved message from the server
                    if let convId = streamingConversationId {
                        await loadMessages(conversationId: convId)
                        await loadConversations()
                    }

                    // Clear streaming state in correct order:
                    // 1. First clear streamingMessageId so the final message appears in the list
                    // 2. Then clear other state to hide the streaming bubble
                    // 3. Set isGenerating false before clearing content to avoid showing TypingIndicator
                    streamingMessageId = nil
                    streamingConversationId = nil
                    isGenerating = false
                    streamingContent = ""
                    streamingReasoning = ""

                    // Haptic feedback when message is received
                    HapticManager.shared.messageReceived()

                case .error(let errorMsg):
                    errorMessage = errorMsg
                    streamingMessageId = nil
                    streamingConversationId = nil
                    isGenerating = false
                    streamingContent = ""
                    streamingReasoning = ""
                }
            }

            // Only set false if not already handled by messageComplete or error
            if isGenerating {
                isGenerating = false
            }
        } catch {
            // If streaming failed and we didn't receive any events, fall back to polling
            if !receivedAnyEvent {
                print("SSE streaming failed, falling back to polling: \(error.localizedDescription)")
                streamingMessageId = nil
                streamingConversationId = nil
                streamingContent = ""
                streamingReasoning = ""

                await sendMessageWithPolling(
                    message: message,
                    modelId: modelId,
                    conversationId: conversationId,
                    assistantId: assistantId,
                    webSearchEnabled: webSearchEnabled,
                    webSearchMode: webSearchMode,
                    webSearchProvider: webSearchProvider,
                    providerId: providerId,
                    images: nil,
                    documents: documents,
                    imageParams: nil,
                    videoParams: nil
                )
            } else {
                errorMessage = error.localizedDescription
                streamingMessageId = nil
                streamingConversationId = nil
                isGenerating = false
                streamingContent = ""
                streamingReasoning = ""
            }
        }
    }

    /// Send message using polling for image/video generation
    private func sendMessageWithPolling(
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
