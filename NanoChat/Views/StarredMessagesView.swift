import SwiftUI

struct StarredMessagesView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var searchText = ""
    @State private var starringIds: Set<String> = []

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Colors.secondary.opacity(0.12), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 350
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: -100, y: -100)
                .ignoresSafeArea()

            NavigationStack {
                Group {
                    if viewModel.isLoadingStarred && viewModel.starredMessages.isEmpty {
                        ProgressView()
                            .tint(Theme.Colors.secondary)
                    } else if filteredStarredMessages.isEmpty {
                        ContentUnavailableView {
                            Label("No Starred Messages", systemImage: "star")
                                .foregroundStyle(Theme.Colors.textSecondary)
                        } description: {
                            Text("Star messages in chats to find them here.")
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    } else {
                        List {
                            ForEach(filteredStarredMessages, id: \.id) { message in
                                if let conversation = conversation(for: message) {
                                    NavigationLink(value: conversation) {
                                        StarredMessageRow(
                                            message: message,
                                            conversationTitle: conversation.title,
                                            isUpdating: starringIds.contains(message.id),
                                            onUnstar: {
                                                Task { await unstar(message) }
                                            }
                                        )
                                    }
                                } else {
                                    StarredMessageRow(
                                        message: message,
                                        conversationTitle: conversationTitle(for: message),
                                        isUpdating: starringIds.contains(message.id),
                                        onUnstar: {
                                            Task { await unstar(message) }
                                        }
                                    )
                                    .onTapGesture {
                                        viewModel.errorMessage = "Conversation not found."
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(
                                EdgeInsets(
                                    top: Theme.Spacing.xs,
                                    leading: Theme.Spacing.lg,
                                    bottom: Theme.Spacing.xs,
                                    trailing: Theme.Spacing.lg
                                )
                            )
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Starred")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .navigationDestination(for: ConversationResponse.self) { conversation in
                    ChatView(conversation: conversation, onMessageSent: nil)
                }
                .searchable(text: $searchText, prompt: "Search starred messages")
                .tint(Theme.Colors.secondary)
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
                .alert(
                    "Error",
                    isPresented: Binding(
                        get: { viewModel.errorMessage != nil },
                        set: { if !$0 { viewModel.errorMessage = nil } }
                    )
                ) {
                    Button("OK") {
                        viewModel.errorMessage = nil
                    }
                } message: {
                    if let error = viewModel.errorMessage {
                        Text(error)
                    }
                }
            }
        }
    }

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
        HStack(spacing: Theme.Spacing.md) {
            Circle()
                .fill(
                    message.role == "user"
                        ? Theme.Colors.userBubbleGradient
                        : LinearGradient(
                            colors: [Theme.Colors.secondary, Theme.Colors.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: message.role == "user" ? "person.fill" : "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
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
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onUnstar) {
                if isUpdating {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(Theme.Colors.secondary)
                } else {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondary)
                }
            }
            .buttonStyle(.borderless)
            .disabled(isUpdating)
        }
        .padding(Theme.Spacing.md)
        .glassCard()
    }
}

#Preview {
    StarredMessagesView()
        .preferredColorScheme(.dark)
}
