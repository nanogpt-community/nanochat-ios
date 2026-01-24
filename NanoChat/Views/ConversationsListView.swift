import SwiftUI

struct ConversationsListView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var multiSelectViewModel = MultiSelectViewModel<ConversationResponse>()
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
    @State private var showingBatchMoveSheet = false

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
                ZStack(alignment: .top) {
                    Group {
                        if viewModel.isLoading && viewModel.conversations.isEmpty {
                            ScrollView {
                                ConversationListSkeleton()
                                    .padding(.top, Theme.Spacing.xs)
                            }
                            .transition(.opacity)
                        } else if filteredConversations.isEmpty && viewModel.errorMessage == nil {
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
                                    ZStack(alignment: .topTrailing) {
                                        Button {
                                            if multiSelectViewModel.isEditMode {
                                                multiSelectViewModel.toggleSelection(conversation)
                                            } else {
                                                navigationPath.append(conversation)
                                            }
                                        } label: {
                                            ConversationRow(conversation: conversation)
                                        }
                                        .buttonStyle(.plain)
                                        .background(
                                            multiSelectViewModel.isSelected(conversation)
                                                ? Theme.Colors.secondary.opacity(0.1) : Color.clear
                                        )
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                        )
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(
                                            EdgeInsets(
                                                top: Theme.Spacing.xs, leading: Theme.Spacing.lg,
                                                bottom: Theme.Spacing.xs, trailing: Theme.Spacing.lg
                                            )
                                        )
                                        .onLongPressGesture {
                                            if !multiSelectViewModel.isEditMode {
                                                multiSelectViewModel.enterEditMode()
                                                multiSelectViewModel.toggleSelection(conversation)
                                            }
                                        }

                                        // Selection indicator
                                        if multiSelectViewModel.isEditMode {
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        multiSelectViewModel.isSelected(
                                                            conversation)
                                                            ? Theme.Colors.secondary : Color.clear
                                                    )
                                                    .frame(width: 24, height: 24)
                                                    .overlay(
                                                        Circle()
                                                            .strokeBorder(
                                                                Theme.Gradients.glass, lineWidth: 1)
                                                    )

                                                if multiSelectViewModel.isSelected(conversation) {
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
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            HapticManager.shared.warning()
                                            Task {
                                                await viewModel.deleteConversation(
                                                    id: conversation.id)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                        .tint(Theme.Colors.error)

                                        Button {
                                            HapticManager.shared.tap()
                                            conversationToMove = conversation
                                            showingMoveSheet = true
                                            Task {
                                                await loadProjects()
                                            }
                                        } label: {
                                            Label("Move", systemImage: "folder.fill")
                                        }
                                        .tint(Theme.Colors.primary)
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
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

                                        Button {
                                            HapticManager.shared.success()
                                            Task {
                                                await archiveConversation(conversation)
                                            }
                                        } label: {
                                            Label("Archive", systemImage: "archivebox.fill")
                                        }
                                        .tint(Theme.Colors.secondary)
                                    }
                                    .contextMenu {
                                        Button {
                                            Task {
                                                await togglePin(conversation)
                                            }
                                        } label: {
                                            Label(
                                                conversation.pinned ? "Unpin" : "Pin",
                                                systemImage: conversation.pinned
                                                    ? "pin.slash" : "pin"
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

                                        Button {
                                            HapticManager.shared.tap()
                                            exportConversation(conversation)
                                        } label: {
                                            Label("Export", systemImage: "square.and.arrow.up")
                                        }

                                        Divider()

                                        Button(role: .destructive) {
                                            Task {
                                                await viewModel.deleteConversation(
                                                    id: conversation.id)
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

                    // Error Banner overlay
                    if let error = viewModel.errorMessage {
                        VStack {
                            ErrorBanner(
                                message: error,
                                onRetry: {
                                    Task {
                                        await viewModel.loadConversations()
                                    }
                                },
                                onDismiss: {
                                    withAnimation {
                                        viewModel.errorMessage = nil
                                    }
                                }
                            )
                            Spacer()
                        }
                        .padding(.top, Theme.Spacing.md)
                    }
                }
                .navigationTitle(multiSelectViewModel.isEditMode ? "Select Items" : "Chats")
                .navigationBarTitleDisplayMode(multiSelectViewModel.isEditMode ? .inline : .large)
                .liquidGlassNavigationBar()
                .navigationDestination(for: ConversationResponse.self) { conversation in
                    if !multiSelectViewModel.isEditMode {
                        ChatView(
                            conversation: conversation,
                            onMessageSent: {
                                Task { @MainActor in
                                    await viewModel.loadConversations()
                                }
                            })
                    }
                }
                .searchable(text: $searchText, prompt: "Search conversations")
                .tint(Theme.Colors.secondary)
                .toolbar {
                    if multiSelectViewModel.isEditMode {
                        // Edit mode toolbar
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
                                Text(
                                    multiSelectViewModel.isAllSelected
                                        ? "Deselect All" : "Select All"
                                )
                                .font(.subheadline)
                            }
                            .foregroundStyle(Theme.Colors.secondary)
                        }
                    } else {
                        // Normal mode toolbar
                        ToolbarItem(placement: .primaryAction) {
                            HStack(spacing: Theme.Spacing.md) {
                                Button {
                                    multiSelectViewModel.enterEditMode()
                                } label: {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }

                                Button(action: createNewConversation) {
                                    ZStack {
                                        Circle()
                                            .fill(Theme.Gradients.primary)
                                            .frame(width: 36, height: 36)
                                            .shadow(
                                                color: Theme.Colors.primary.opacity(0.4), radius: 6,
                                                x: 0,
                                                y: 3)

                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                }
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
                    }
                }
                .onChange(of: viewModel.conversations) { _, newValue in
                    multiSelectViewModel.items = newValue
                    // Remove selected items that no longer exist
                    multiSelectViewModel.selectedItems = multiSelectViewModel.selectedItems
                        .intersection(Set(newValue.map { $0.id }))
                }
                .refreshable {
                    HapticManager.shared.refreshTriggered()
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
                .sheet(isPresented: $showingBatchMoveSheet) {
                    ProjectPickerView(
                        projects: projects,
                        selectedProjectId: nil,
                        isLoading: isLoadingProjects
                    ) { projectId in
                        Task {
                            await batchMoveToProject(projectId)
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

    // MARK: - Batch Operations Bar

    private var batchOperationsBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button {
                Task {
                    await batchDelete()
                }
            } label: {
                Label("Delete", systemImage: "trash.fill")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.error)

            Button {
                showingBatchMoveSheet = true
                Task {
                    await loadProjects()
                }
            } label: {
                Label("Move", systemImage: "folder.fill")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.primary)

            Button {
                batchExport()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.secondary)
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

    private func batchDelete() async {
        await multiSelectViewModel.deleteSelected { ids in
            for id in ids {
                Task {
                    await viewModel.deleteConversation(id: id)
                }
            }
        }
        await viewModel.loadConversations()
    }

    private func batchMoveToProject(_ projectId: String?) async {
        await multiSelectViewModel.moveToProject(
            using: { ids, targetProjectId in
                for id in ids {
                    if let conversation = viewModel.conversations.first(where: { $0.id == id }) {
                        Task {
                            try? await viewModel.setConversationProject(
                                conversationId: conversation.id,
                                projectId: targetProjectId
                            )
                        }
                    }
                }
            }, projectId: projectId)
        showingBatchMoveSheet = false
        await viewModel.loadConversations()
    }

    private func batchExport() {
        multiSelectViewModel.exportSelected { ids in
            let selectedConversations = viewModel.conversations.filter { ids.contains($0.id) }

            Task {
                let items: [(conversation: ConversationResponse, messages: [MessageResponse])] =
                    await withTaskGroup(of: (String, [MessageResponse]).self) { group in
                        var results: [String: [MessageResponse]] = [:]

                        for conversation in selectedConversations {
                            group.addTask {
                                let messages = try? await NanoChatAPI.shared.getMessages(
                                    conversationId: conversation.id)
                                return (conversation.id, messages ?? [])
                            }
                        }

                        for await (conversationId, messages) in group {
                            results[conversationId] = messages
                        }

                        return selectedConversations.compactMap { conv in
                            guard let msgs = results[conv.id] else { return nil }
                            return (conv, msgs)
                        }
                    }

                await MainActor.run {
                    ExportManager.shared.presentShareSheetForMultiple(items: items)
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
        HapticManager.shared.tap()
        do {
            _ = try await NanoChatAPI.shared.toggleConversationPin(conversationId: conversation.id)
            await viewModel.loadConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func renameConversation(_ conversation: ConversationResponse, newTitle: String) async {
        HapticManager.shared.tap()
        do {
            try await NanoChatAPI.shared.updateConversationTitle(
                conversationId: conversation.id,
                title: newTitle
            )
            await viewModel.loadConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
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

    private func archiveConversation(_ conversation: ConversationResponse) async {
        // TODO: Implement proper archive functionality when API supports it
        // For now, this is a placeholder that could be expanded to:
        // - Move to a special "Archived" project
        // - Set an archived flag (if API adds support)
        // - Hide from main list with a filter toggle
        HapticManager.shared.tap()
    }

    private func exportConversation(_ conversation: ConversationResponse) {
        Task {
            // Fetch messages for this conversation
            let messages = try? await NanoChatAPI.shared.getMessages(
                conversationId: conversation.id)

            await MainActor.run {
                guard let messages = messages else {
                    return
                }

                let markdown = ExportManager.shared.exportConversationToMarkdown(
                    conversation: conversation,
                    messages: messages
                )
                let filename = ExportManager.shared.sanitizeFilename(conversation.title)
                ExportManager.shared.presentShareSheet(
                    content: markdown,
                    fileName: filename,
                    format: .markdown
                )
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
