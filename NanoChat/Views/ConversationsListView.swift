import SwiftUI

struct ConversationsListView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var searchText = ""
    @State private var navigationPath = [ConversationResponse]()
    @State private var showingRenameDialog = false
    @State private var conversationToRename: ConversationResponse?
    @State private var newConversationTitle = ""
    @State private var showingMoveSheet = false
    @State private var conversationToMove: ConversationResponse?
    @State private var projects: [ProjectResponse] = []
    @State private var isLoadingProjects = false
    @State private var errorMessage: String?

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
                                .listRowInsets(
                                    EdgeInsets(
                                        top: Theme.Spacing.xs, leading: Theme.Spacing.lg,
                                        bottom: Theme.Spacing.xs, trailing: Theme.Spacing.lg)
                                )
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
                                            systemImage: conversation.pinned
                                                ? "pin.slash.fill" : "pin.fill"
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

                                    Button {
                                        conversationToMove = conversation
                                        showingMoveSheet = true
                                        Task {
                                            await loadProjects()
                                        }
                                    } label: {
                                        Label("Move to Project", systemImage: "folder")
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
                    ChatView(
                        conversation: conversation,
                        onMessageSent: {
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
                                    .shadow(
                                        color: Theme.Colors.primary.opacity(0.4), radius: 6, x: 0,
                                        y: 3)

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
                    Button("Cancel", role: .cancel) {}
                    Button("Rename") {
                        if let conversation = conversationToRename, !newConversationTitle.isEmpty {
                            Task {
                                await renameConversation(
                                    conversation, newTitle: newConversationTitle)
                            }
                        }
                    }
                } message: {
                    TextField("Conversation name", text: $newConversationTitle)
                        .onAppear {
                            newConversationTitle = conversationToRename?.title ?? ""
                        }
                }
                .sheet(isPresented: $showingMoveSheet) {
                    ProjectPickerView(
                        projects: projects,
                        selectedProjectId: conversationToMove?.projectId,
                        isLoading: isLoadingProjects
                    ) { projectId in
                        if let conversation = conversationToMove {
                            Task {
                                await moveConversation(conversation, to: projectId)
                            }
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
                .alert("Error", isPresented: .constant(errorMessage != nil)) {
                    Button("OK") {
                        errorMessage = nil
                    }
                } message: {
                    if let error = errorMessage {
                        Text(error)
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

    private func loadProjects() async {
        isLoadingProjects = true
        defer { isLoadingProjects = false }

        do {
            projects = try await NanoChatAPI.shared.getProjects()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func moveConversation(_ conversation: ConversationResponse, to projectId: String?) async
    {
        HapticManager.shared.tap()
        do {
            try await viewModel.setConversationProject(
                conversationId: conversation.id,
                projectId: projectId
            )
            showingMoveSheet = false
            conversationToMove = nil
        } catch {
            errorMessage = error.localizedDescription
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

struct ProjectPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let projects: [ProjectResponse]
    let selectedProjectId: String?
    let isLoading: Bool
    let onSelect: (String?) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background
                    .ignoresSafeArea()

                GlassList {
                    GlassListSection("Project") {
                        GlassListRow {
                            Button {
                                onSelect(nil)
                                dismiss()
                            } label: {
                                HStack {
                                    Text("No Project")
                                        .foregroundStyle(Theme.Colors.text)

                                    Spacer()

                                    if selectedProjectId == nil {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.Colors.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    GlassListSection("All Projects") {
                        if isLoading {
                            GlassListRow(showDivider: false) {
                                ProgressView()
                                    .tint(Theme.Colors.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        } else if projects.isEmpty {
                            GlassListRow(showDivider: false) {
                                Text("No projects available")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        } else {
                            ForEach(projects, id: \.id) { project in
                                GlassListRow {
                                    Button {
                                        onSelect(project.id)
                                        dismiss()
                                    } label: {
                                        HStack {
                                            Text(project.name)
                                                .foregroundStyle(Theme.Colors.text)

                                            Spacer()

                                            if selectedProjectId == project.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(Theme.Colors.secondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Spacer(minLength: Theme.Spacing.xxl)
                }
            }
            .navigationTitle("Move to Project")
            .navigationBarTitleDisplayMode(.inline)
            .liquidGlassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }
}
