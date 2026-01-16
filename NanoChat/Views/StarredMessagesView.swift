import SwiftUI

struct StarredMessagesView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var multiSelectViewModel = MultiSelectViewModel<MessageResponse>()
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
                        StarredMessagesSkeleton()
                            .transition(.opacity)
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
                                ZStack(alignment: .topTrailing) {
                                    if let conversation = conversation(for: message) {
                                        NavigationLink(value: conversation) {
                                            StarredMessageRow(
                                                message: message,
                                                conversationTitle: conversation.title,
                                                isUpdating: starringIds.contains(message.id),
                                                onUnstar: {
                                                    Task { await unstar(message) }
                                                },
                                                isSelected: multiSelectViewModel.isSelected(message)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .opacity(multiSelectViewModel.isEditMode ? 0 : 1)
                                        .onLongPressGesture {
                                            multiSelectViewModel.enterEditMode()
                                            multiSelectViewModel.toggleSelection(message)
                                        }
                                    } else {
                                        StarredMessageRow(
                                            message: message,
                                            conversationTitle: conversationTitle(for: message),
                                            isUpdating: starringIds.contains(message.id),
                                            onUnstar: {
                                                Task { await unstar(message) }
                                            },
                                            isSelected: multiSelectViewModel.isSelected(message)
                                        )
                                        .onTapGesture {
                                            if multiSelectViewModel.isEditMode {
                                                multiSelectViewModel.toggleSelection(message)
                                            } else {
                                                viewModel.errorMessage = "Conversation not found."
                                            }
                                        }
                                        .onLongPressGesture {
                                            multiSelectViewModel.enterEditMode()
                                            multiSelectViewModel.toggleSelection(message)
                                        }
                                    }

                                    // Selection indicator
                                    if multiSelectViewModel.isEditMode {
                                        ZStack {
                                            Circle()
                                                .fill(multiSelectViewModel.isSelected(message) ? Theme.Colors.secondary : Color.clear)
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
                                                )

                                            if multiSelectViewModel.isSelected(message) {
                                                Image(systemName: "checkmark")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .padding(Theme.Spacing.sm)
                                        .transition(.scale.combined(with: .opacity))
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
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle(multiSelectViewModel.isEditMode ? "Select Items" : "Starred")
                .navigationBarTitleDisplayMode(multiSelectViewModel.isEditMode ? .inline : .large)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .navigationDestination(for: ConversationResponse.self) { conversation in
                    if !multiSelectViewModel.isEditMode {
                        ChatView(conversation: conversation, onMessageSent: nil)
                    }
                }
                .searchable(text: $searchText, prompt: "Search starred messages")
                .tint(Theme.Colors.secondary)
                .disabled(multiSelectViewModel.isEditMode)
                .toolbar {
                    if multiSelectViewModel.isEditMode {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                multiSelectViewModel.exitEditMode()
                            }
                            .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        ToolbarItem(placement: .principal) {
                            Text(multiSelectViewModel.selectionDescription)
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                multiSelectViewModel.toggleSelectAll()
                            } label: {
                                Text(multiSelectViewModel.isAllSelected ? "Deselect All" : "Select All")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Theme.Colors.secondary)
                        }
                    } else {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                multiSelectViewModel.enterEditMode()
                            } label: {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if multiSelectViewModel.isEditMode && multiSelectViewModel.hasSelection {
                        batchOperationsBar
                    }
                }
                .onAppear {
                    Task {
                        await viewModel.loadConversations()
                        await viewModel.loadStarredMessages()
                    }
                }
                .onChange(of: viewModel.starredMessages) { _, newValue in
                    multiSelectViewModel.items = newValue
                    multiSelectViewModel.selectedItems = multiSelectViewModel.selectedItems.intersection(Set(newValue.map { $0.id }))
                }
                .refreshable {
                    HapticManager.shared.refreshTriggered()
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

    // MARK: - Batch Operations Bar

    private var batchOperationsBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button {
                Task {
                    await batchUnstar()
                }
            } label: {
                Label("Unstar", systemImage: "star.slash.fill")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.warning)

            Button {
                batchExport()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.secondary)

            Button {
                batchCopy()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.primary)
        }
        .padding()
        .background(Theme.Colors.glassPane)
        .overlay(
            Rectangle()
                .fill(Theme.Colors.glassBorder)
                .frame(height: 1),
            alignment: .top
        )
    }

    // MARK: - Batch Operations

    private func batchUnstar() async {
        await multiSelectViewModel.starSelected { ids in
            for id in ids {
                if viewModel.starredMessages.contains(where: { $0.id == id }) {
                    Task {
                        try? await NanoChatAPI.shared.setMessageStarred(messageId: id, starred: false)
                    }
                }
            }
        }
        await viewModel.loadStarredMessages()
    }

    private func batchExport() {
        multiSelectViewModel.exportSelected { ids in
            let selectedMessages = viewModel.starredMessages.filter { ids.contains($0.id) }

            // Group messages by conversation
            let grouped = Dictionary(grouping: selectedMessages) { $0.conversationId }

            let items: [(conversation: ConversationResponse, messages: [MessageResponse])] = grouped.compactMapValues { messages in
                messages
            }.compactMap { (conversationId, messages) in
                guard let conv = viewModel.conversations.first(where: { $0.id == conversationId }) else {
                    return nil
                }
                return (conv, messages)
            }

            ExportManager.shared.presentShareSheetForMultiple(items: items)
        }
    }

    private func batchCopy() {
        multiSelectViewModel.exportSelected { ids in
            let selectedMessages = viewModel.starredMessages.filter { ids.contains($0.id) }
            let combinedContent = selectedMessages
                .map { message in
                    let role = message.role == "user" ? "You" : "Assistant"
                    return "\(role): \(message.content)"
                }
                .joined(separator: "\n\n---\n\n")

            UIPasteboard.general.string = combinedContent
            HapticManager.shared.success()
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
    let isSelected: Bool

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
        .background(isSelected ? Theme.Colors.secondary.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .glassCard()
    }
}

#Preview {
    StarredMessagesView()
        .preferredColorScheme(.dark)
}
