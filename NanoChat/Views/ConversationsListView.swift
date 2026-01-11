import SwiftUI

struct ConversationsListView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var searchText = ""
    @State private var navigationPath = [ConversationResponse]()
    @State private var showingRenameDialog = false
    @State private var conversationToRename: ConversationResponse?
    @State private var newConversationTitle = ""

    var body: some View {
        ZStack {
            // Background
            Theme.Gradients.background
                .ignoresSafeArea()

            // Subtle glow effect
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

            NavigationStack(path: $navigationPath) {
                Group {
                    if viewModel.isLoading && viewModel.conversations.isEmpty {
                        ProgressView()
                            .tint(Theme.Colors.secondary)
                    } else if filteredConversations.isEmpty {
                        ContentUnavailableView {
                            Label("No Conversations", systemImage: "message.circle")
                                .foregroundStyle(Theme.Colors.textSecondary)
                        } description: {
                            Text("Start a new conversation to begin chatting")
                                .foregroundStyle(Theme.Colors.textTertiary)
                        } actions: {
                            Button("New Chat") {
                                createNewConversation()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    } else {
                        List {
                            ForEach(filteredConversations, id: \.id) { conversation in
                                Button {
                                    navigationPath.append(conversation)
                                } label: {
                                    ConversationRow(conversation: conversation)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: Theme.Spacing.xs, leading: Theme.Spacing.lg, bottom: Theme.Spacing.xs, trailing: Theme.Spacing.lg))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HapticManager.shared.warning()
                                        Task {
                                            await viewModel.deleteConversation(id: conversation.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                    .tint(Theme.Colors.error)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        HapticManager.shared.tap()
                                        Task {
                                            await togglePin(conversation)
                                        }
                                    } label: {
                                        Label(
                                            conversation.pinned ? "Unpin" : "Pin",
                                            systemImage: conversation.pinned ? "pin.slash.fill" : "pin.fill"
                                        )
                                    }
                                    .tint(Theme.Colors.warning)
                                }
                                .contextMenu {
                                    Button {
                                        Task {
                                            await togglePin(conversation)
                                        }
                                    } label: {
                                        Label(
                                            conversation.pinned ? "Unpin" : "Pin",
                                            systemImage: conversation.pinned ? "pin.slash" : "pin"
                                        )
                                    }

                                    Button {
                                        showingRenameDialog = true
                                        conversationToRename = conversation
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteConversation(id: conversation.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Chats")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .navigationDestination(for: ConversationResponse.self) { conversation in
                    ChatView(conversation: conversation, onMessageSent: {
                        Task { @MainActor in
                            await viewModel.loadConversations()
                        }
                    })
                }
                .searchable(text: $searchText, prompt: "Search conversations")
                    .tint(Theme.Colors.secondary)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: createNewConversation) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Gradients.primary)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 6, x: 0, y: 3)

                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .onAppear {
                    Task {
                        await viewModel.loadConversations()
                    }
                }
                .refreshable {
                    await viewModel.loadConversations()
                }
                .alert("Rename Conversation", isPresented: $showingRenameDialog) {
                    Button("Cancel", role: .cancel) { }
                    Button("Rename") {
                        if let conversation = conversationToRename, !newConversationTitle.isEmpty {
                            Task {
                                await renameConversation(conversation, newTitle: newConversationTitle)
                            }
                        }
                    }
                } message: {
                    TextField("Conversation name", text: $newConversationTitle)
                        .onAppear {
                            newConversationTitle = conversationToRename?.title ?? ""
                        }
                }
            }
        }
    }

    private var filteredConversations: [ConversationResponse] {
        let result: [ConversationResponse]
        if searchText.isEmpty {
            result = viewModel.conversations
        } else {
            result = viewModel.conversations.filter { conversation in
                conversation.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    private func togglePin(_ conversation: ConversationResponse) async {
        print("Toggle pin for conversation: \(conversation.id)")
    }

    private func renameConversation(_ conversation: ConversationResponse, newTitle: String) async {
        print("Rename conversation \(conversation.id) to: \(newTitle)")
    }

    private func createNewConversation() {
        HapticManager.shared.tap()
        Task { @MainActor in
            await viewModel.createConversation()
            if let createdConversation = viewModel.currentConversation {
                navigationPath.append(createdConversation)
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: ConversationResponse

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Avatar
            Circle()
                .fill(Theme.Gradients.primary)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "message.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(conversation.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.text)
                        .lineLimit(1)

                    Spacer()

                    if conversation.pinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondary)
                    }

                    if let cost = conversation.costUsd {
                        Text("$\(String(format: "%.4f", cost))")
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                Text(conversation.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.md)
        .glassCard()
    }
}

#Preview {
    ConversationsListView()
        .preferredColorScheme(.dark)
}
