import SwiftUI

struct StarredMessagesView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var multiSelectViewModel = MultiSelectViewModel<MessageResponse>()
    @State private var searchText = ""
    @State private var starringIds: Set<String> = []

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingStarred && viewModel.starredMessages.isEmpty {
                    ProgressView()
                } else if filteredStarredMessages.isEmpty {
                    ContentUnavailableView {
                        Label("No Starred Messages", systemImage: "star")
                    } description: {
                        Text("Star messages in chats to find them here.")
                    }
                } else {
                    List(selection: $multiSelectViewModel.selectedItems) {
                        ForEach(filteredStarredMessages, id: \.id) { message in
                            StarredMessageRow(
                                message: message,
                                conversationTitle: conversationTitle(for: message),
                                isUpdating: starringIds.contains(message.id),
                                onUnstar: {
                                    Task { await unstar(message) }
                                }
                            )
                            // Navigation logic is tricky in edit mode with standard List selection.
                            // Standard List handles selection automatically if we bind selection.
                            // But we need custom navigation behavior.
                            // Let's use a simple ZStack or Overlay approach if standard List selection isn't enough.
                            // Actually, standard List supports selection AND navigation if we use NavigationLink properly.
                            .background {
                                if let conversation = conversation(for: message) {
                                    NavigationLink("", value: conversation).opacity(0)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    Task { await unstar(message) }
                                } label: {
                                    Label("Unstar", systemImage: "star.slash")
                                }
                                .tint(.orange)
                            }
                            .tag(message.id)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Starred")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: ConversationResponse.self) { conversation in
                ChatView(conversation: conversation, showSidebar: .constant(false), onMessageSent: nil)
            }
            .searchable(text: $searchText, prompt: "Search starred messages")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadConversations()
                    await viewModel.loadStarredMessages()
                }
            }
            .refreshable {
                await viewModel.loadConversations()
                await viewModel.loadStarredMessages()
            }
        }
    }

    // MARK: - Helpers (Keep existing logic)

    private var filteredStarredMessages: [MessageResponse] {
        if searchText.isEmpty {
            return viewModel.starredMessages
        }

        return viewModel.starredMessages.filter { message in
            let conversationTitle = conversationTitle(for: message)
            return message.content.localizedCaseInsensitiveContains(searchText)
                || conversationTitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func conversationTitle(for message: MessageResponse) -> String {
        conversation(for: message)?.title ?? "Conversation"
    }

    private func conversation(for message: MessageResponse) -> ConversationResponse? {
        viewModel.conversations.first(where: { $0.id == message.conversationId })
    }

    private func unstar(_ message: MessageResponse) async {
        guard !starringIds.contains(message.id) else { return }
        starringIds.insert(message.id)
        HapticManager.shared.selection()

        do {
            _ = try await NanoChatAPI.shared.setMessageStarred(
                messageId: message.id, starred: false)
            HapticManager.shared.success()
            viewModel.removeStarredMessage(messageId: message.id)
        } catch {
            HapticManager.shared.error()
            viewModel.errorMessage = error.localizedDescription
        }

        starringIds.remove(message.id)
    }
}

struct StarredMessageRow: View {
    let message: MessageResponse
    let conversationTitle: String
    let isUpdating: Bool
    let onUnstar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(conversationTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.text)
                    .lineLimit(1)

                Spacer()

                Text(message.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Text(message.content)
                .font(.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    StarredMessagesView()
}
