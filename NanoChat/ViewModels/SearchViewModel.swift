import Foundation
import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var startDate: Date?
    @Published var endDate: Date?
    @Published var selectedModel: String?
    @Published var selectedProject: String?
    @Published var starredOnly: Bool = false
    @Published var hasAttachments: Bool = false
    @Published var results: [SearchResult] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var availableModels: [String] = []
    private var availableProjects: [ProjectResponse] = []
    private var allConversations: [ConversationResponse] = []
    private var allMessages: [MessageResponse] = []

    // MARK: - Search Result Model

    struct SearchResult: Identifiable, Hashable {
        let id = UUID()
        let message: MessageResponse
        let conversation: ConversationResponse
        let highlightedContext: String
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load conversations and their messages
            allConversations = try await NanoChatAPI.shared.getConversations()

            // Load projects for filtering
            availableProjects = try await NanoChatAPI.shared.getProjects()

            // Load all messages for search
            await loadAllMessages()

            // Extract unique models from messages (not conversations)
            let models = Set(allMessages.compactMap { $0.modelId })
            availableModels = Array(models).sorted()

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadAllMessages() async {
        allMessages = []

        for conversation in allConversations {
            do {
                let messages = try await NanoChatAPI.shared.getMessages(conversationId: conversation.id)
                allMessages.append(contentsOf: messages)
            } catch {
                print("Failed to load messages for conversation \(conversation.id): \(error)")
            }
        }
    }

    // MARK: - Search

    func performSearch() {
        isLoading = true
        defer { isLoading = false }

        var filtered = allMessages

        // Text search
        if !query.isEmpty {
            filtered = filtered.filter { message in
                message.content.localizedCaseInsensitiveContains(query)
            }
        }

        // Date range filter
        if let start = startDate {
            filtered = filtered.filter { message in
                message.createdAt >= start
            }
        }

        if let end = endDate {
            filtered = filtered.filter { message in
                message.createdAt <= end
            }
        }

        // Model filter
        if let model = selectedModel {
            filtered = filtered.filter { $0.modelId == model }
        }

        // Project filter
        if let project = selectedProject {
            filtered = filtered.filter { message in
                guard let conversation = allConversations.first(where: { $0.id == message.conversationId }) else {
                    return false
                }
                return conversation.projectId == project
            }
        }

        // Starred filter
        if starredOnly {
            filtered = filtered.filter { $0.starred == true }
        }

        // Attachments filter
        if hasAttachments {
            filtered = filtered.filter { message in
                (message.images?.isEmpty == false) || (message.documents?.isEmpty == false)
            }
        }

        // Convert to SearchResult with context
        results = filtered.map { message in
            SearchResult(
                message: message,
                conversation: allConversations.first(where: { $0.id == message.conversationId }) ?? ConversationResponse(
                    id: "",
                    title: "Unknown",
                    userId: "",
                    projectId: nil,
                    pinned: false,
                    generating: false
                ),
                highlightedContext: highlightText(in: message.content, query: query)
            )
        }
    }

    // MARK: - Helper Methods

    private func highlightText(in text: String, query: String) -> String {
        guard !query.isEmpty else { return text }

        // Return a snippet around the matched text
        if let range = text.range(of: query, options: .caseInsensitive) {
            let snippetRange = NSRange(range, in: text)
            let start = max(0, snippetRange.location - 50)
            let end = min(text.count, snippetRange.location + snippetRange.length + 50)
            let index = text.index(text.startIndex, offsetBy: start)
            let endIndex = text.index(text.startIndex, offsetBy: end)

            var snippet = String(text[index..<endIndex])
            if start > 0 { snippet = "...\(snippet)" }
            if end < text.count { snippet = "\(snippet)..." }

            return snippet
        }

        // Return first 150 chars if no match
        return String(text.prefix(150))
    }

    func clearFilters() {
        query = ""
        startDate = nil
        endDate = nil
        selectedModel = nil
        selectedProject = nil
        starredOnly = false
        hasAttachments = false
        results = []
    }

    // MARK: - Computed Properties

    var hasActiveFilters: Bool {
        !query.isEmpty ||
        startDate != nil ||
        endDate != nil ||
        selectedModel != nil ||
        selectedProject != nil ||
        starredOnly ||
        hasAttachments
    }

    var availableModelsForFilter: [String] {
        availableModels
    }

    var availableProjectsForFilter: [ProjectResponse] {
        availableProjects
    }
}
