import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif
#if canImport(AppKit)
    import AppKit
#endif

struct SidebarView: View {
    @Binding var selectedConversation: ConversationResponse?
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ChatViewModel
    var onNewChat: (() -> Void)?
    @State private var searchText = ""
    @State private var searchMode: ConversationSearchMode = .words
    @State private var searchResults: [ConversationSearchResult] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearching = false
    @State private var showSettings = false

    // For navigation to other sections
    @State private var showAssistants = false
    @State private var showProjects = false
    @State private var showStarred = false
    @State private var showGallery = false

    // Multi-selection
    @StateObject private var multiSelectViewModel = MultiSelectViewModel<ConversationResponse>()

    // Conversation Management State
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
        ZStack(alignment: .leading) {
            // Dark Sidebar Background
            Theme.Colors.backgroundStart
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header: Search & New Chat or Edit Mode
                if multiSelectViewModel.isEditMode {
                    // Edit mode header
                    HStack {
                        Button {
                            multiSelectViewModel.exitEditMode()
                        } label: {
                            Text("Cancel")
                                .font(Theme.font(size: 16))
                                .foregroundStyle(Theme.Colors.accent)
                        }

                        Spacer()

                        Text(multiSelectViewModel.selectionDescription)
                            .font(Theme.font(size: 15, weight: .medium))
                            .foregroundStyle(Theme.Colors.text)

                        Spacer()

                        Button {
                            multiSelectViewModel.toggleSelectAll()
                        } label: {
                            Text(multiSelectViewModel.isAllSelected ? "Deselect" : "Select All")
                                .font(Theme.font(size: 16))
                                .foregroundStyle(Theme.Colors.accent)
                        }
                    }
                    .padding(.horizontal, Theme.scaled(16))
                    .padding(.top, Theme.scaled(16))
                    .padding(.bottom, Theme.scaled(8))
                } else {
                    // Normal header
                    HStack(spacing: Theme.scaled(12)) {
                        // Search Bar
                        HStack(spacing: Theme.scaled(8)) {
                            Image(systemName: "magnifyingglass")
                                .font(Theme.font(size: 16))
                                .foregroundStyle(Theme.Colors.textTertiary)

                            TextField("Search", text: $searchText)
                                .textFieldStyle(.plain)
                                .font(Theme.font(size: 16))
                                .foregroundStyle(Theme.Colors.text)
                        }
                        .padding(.horizontal, Theme.scaled(12))
                        .padding(.vertical, Theme.scaled(10))
                        .background(Theme.Colors.glassSurface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.scaled(10)))

                        Menu {
                            Picker("Search Mode", selection: $searchMode) {
                                ForEach(ConversationSearchMode.allCases) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(Theme.font(size: 20))
                                .foregroundStyle(
                                    searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                                        .isEmpty
                                        ? Theme.Colors.textTertiary
                                        : Theme.Colors.accent
                                )
                        }

                        // Edit Button
                        Button {
                            multiSelectViewModel.enterEditMode()
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .font(Theme.font(size: 20))
                                .foregroundStyle(Theme.Colors.text)
                        }

                        // New Chat Button
                        Button {
                            onNewChat?()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(Theme.font(size: 18))
                                .foregroundStyle(Theme.Colors.text)
                        }
                    }
                    .padding(.horizontal, Theme.scaled(16))
                    .padding(.top, Theme.scaled(16))
                    .padding(.bottom, Theme.scaled(8))
                }

                // Navigation List Items
                VStack(spacing: 2) {
                    SidebarListItem(icon: "sparkles", title: "Assistants") {
                        showAssistants = true
                    }
                    SidebarListItem(icon: "folder", title: "Projects") {
                        showProjects = true
                    }
                    SidebarListItem(icon: "star", title: "Starred") {
                        showStarred = true
                    }
                    SidebarListItem(icon: "photo.on.rectangle.angled", title: "Gallery") {
                        showGallery = true
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)

                // Thin divider
                Rectangle()
                    .fill(Theme.Colors.border)
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                // Conversations List
                ScrollView {
                    LazyVStack(spacing: 4, pinnedViews: .sectionHeaders) {
                        if (viewModel.isLoading && viewModel.conversations.isEmpty)
                            || (isSearching
                                && !searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    .isEmpty
                                && filteredConversations.isEmpty)
                        {
                            ProgressView()
                                .tint(Theme.Colors.secondary)
                                .padding()
                        } else {
                            let grouped = groupConversations(filteredConversations)

                            ForEach(grouped, id: \.0) { group, conversations in
                                Section(
                                    header:
                                        Text(group.rawValue)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 4)
                                    //.background(Theme.Colors.glassSurface.opacity(0.9)) // Sticky header bg
                                ) {
                                    ForEach(conversations, id: \.id) { conversation in
                                        Button {
                                            if multiSelectViewModel.isEditMode {
                                                multiSelectViewModel.toggleSelection(conversation)
                                            } else {
                                                selectedConversation = conversation
                                                withAnimation(
                                                    .spring(response: 0.3, dampingFraction: 0.8)
                                                ) {
                                                    isPresented = false
                                                }
                                            }
                                        } label: {
                                            SidebarRow(
                                                conversation: conversation,
                                                isSelected: selectedConversation?.id
                                                    == conversation.id,
                                                isSelectionMode: multiSelectViewModel.isEditMode,
                                                isChecked: multiSelectViewModel.isSelected(
                                                    conversation)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            if !multiSelectViewModel.isEditMode {
                                                Button {
                                                    Task { await togglePin(conversation) }
                                                } label: {
                                                    Label(
                                                        conversation.pinned ? "Unpin" : "Pin",
                                                        systemImage: conversation.pinned
                                                            ? "pin.slash" : "pin")
                                                }

                                                Button {
                                                    conversationToRename = conversation
                                                    newConversationTitle = conversation.title
                                                    showingRenameDialog = true
                                                } label: {
                                                    Label("Rename", systemImage: "pencil")
                                                }

                                                Button {
                                                    conversationToMove = conversation
                                                    showingMoveSheet = true
                                                    Task { await loadProjects() }
                                                } label: {
                                                    Label("Move to Project", systemImage: "folder")
                                                }

                                                Button {
                                                    multiSelectViewModel.enterEditMode()
                                                    multiSelectViewModel.toggleSelection(
                                                        conversation)
                                                } label: {
                                                    Label("Select", systemImage: "checkmark.circle")
                                                }

                                                Divider()

                                                Button(role: .destructive) {
                                                    Task {
                                                        await viewModel.deleteConversation(
                                                            id: conversation.id)
                                                        await viewModel.loadConversations()
                                                    }
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }

                Spacer()

                // Batch Operations Bar (shown in edit mode with selections)
                if multiSelectViewModel.isEditMode && multiSelectViewModel.hasSelection {
                    HStack(spacing: 20) {
                        // Move to Project
                        Button {
                            showingBatchMoveSheet = true
                            Task { await loadProjects() }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "folder")
                                    .font(.system(size: 20))
                                Text("Move")
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(Theme.Colors.text)
                        }

                        // Pin/Unpin
                        Button {
                            Task { await batchTogglePin() }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "pin")
                                    .font(.system(size: 20))
                                Text("Pin")
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(Theme.Colors.text)
                        }

                        // Delete
                        Button {
                            Task { await batchDelete() }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 20))
                                Text("Delete")
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.glassSurface)
                } else {
                    // User Footer
                    Button {
                        showSettings = true
                    } label: {
                        HStack(spacing: Theme.scaled(12)) {
                            // User Avatar
                            Circle()
                                .fill(Theme.Colors.accent)
                                .frame(width: Theme.scaled(32), height: Theme.scaled(32))
                                .overlay(
                                    Text("U")
                                        .font(Theme.font(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                )

                            Text("Settings")
                                .font(Theme.font(size: 15))
                                .foregroundStyle(Theme.Colors.text)

                            Spacer()

                            Image(systemName: "gearshape")
                                .font(Theme.font(size: 16))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Theme.scaled(16))
                        .padding(.vertical, Theme.scaled(12))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: 1)
            }
            .frame(width: Theme.scaled(300))
        }
        .sheet(isPresented: $showAssistants) { AssistantsListView() }
        .sheet(isPresented: $showProjects) { ProjectsListView() }
        .sheet(isPresented: $showStarred) { StarredMessagesView() }
        .sheet(isPresented: $showGallery) { ImageGalleryView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .alert("Rename Conversation", isPresented: $showingRenameDialog) {
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                if let conversation = conversationToRename, !newConversationTitle.isEmpty {
                    Task { await renameConversation(conversation, newTitle: newConversationTitle) }
                }
            }
        } message: {
            TextField("Conversation name", text: $newConversationTitle)
        }
        .sheet(isPresented: $showingMoveSheet) {
            ProjectPickerView(
                projects: projects,
                selectedProjectId: conversationToMove?.projectId,
                isLoading: isLoadingProjects
            ) { projectId in
                if let conversation = conversationToMove {
                    Task { await moveConversation(conversation, to: projectId) }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            Task { await viewModel.loadConversations() }
        }
        .onChange(of: viewModel.conversations) { _, newValue in
            multiSelectViewModel.items = newValue
            multiSelectViewModel.selectedItems = multiSelectViewModel.selectedItems.intersection(
                Set(newValue.map { $0.id }))
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                scheduleSearch()
            }
        }
        .onChange(of: searchText) { _, _ in
            scheduleSearch()
        }
        .onChange(of: searchMode) { _, _ in
            scheduleSearch()
        }
        .onDisappear {
            searchTask?.cancel()
        }
        .sheet(isPresented: $showingBatchMoveSheet) {
            ProjectPickerView(
                projects: projects,
                selectedProjectId: nil,
                isLoading: isLoadingProjects
            ) { projectId in
                Task { await batchMoveToProject(projectId) }
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Batch Operations

    private func batchDelete() async {
        let idsToDelete = multiSelectViewModel.selectedItems
        multiSelectViewModel.exitEditMode()

        for id in idsToDelete {
            await viewModel.deleteConversation(id: id)
        }
        await viewModel.loadConversations()
        HapticManager.shared.warning()
    }

    private func batchTogglePin() async {
        let idsToPin = multiSelectViewModel.selectedItems
        multiSelectViewModel.exitEditMode()

        for id in idsToPin {
            do {
                _ = try await NanoChatAPI.shared.toggleConversationPin(conversationId: id)
            } catch {
                // Continue with next
            }
        }
        await viewModel.loadConversations()
        HapticManager.shared.success()
    }

    private func batchMoveToProject(_ projectId: String?) async {
        let idsToMove = multiSelectViewModel.selectedItems
        showingBatchMoveSheet = false
        multiSelectViewModel.exitEditMode()

        for id in idsToMove {
            do {
                try await viewModel.setConversationProject(conversationId: id, projectId: projectId)
            } catch {
                // Continue with next
            }
        }
        await viewModel.loadConversations()
        HapticManager.shared.success()
    }

    // MARK: - Grouping Logic

    enum DateGroup: String, CaseIterable, Comparable {
        case today = "Today"
        case yesterday = "Yesterday"
        case previous7Days = "Previous 7 Days"
        case previous30Days = "Previous 30 Days"
        case older = "Older"

        var sortOrder: Int {
            switch self {
            case .today: return 0
            case .yesterday: return 1
            case .previous7Days: return 2
            case .previous30Days: return 3
            case .older: return 4
            }
        }

        static func < (lhs: DateGroup, rhs: DateGroup) -> Bool {
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private func groupConversations(_ conversations: [ConversationResponse]) -> [(
        DateGroup, [ConversationResponse]
    )] {
        let calendar = Calendar.current
        let now = Date()

        let grouped = Dictionary(grouping: conversations) { conversation -> DateGroup in
            if calendar.isDateInToday(conversation.updatedAt) {
                return .today
            } else if calendar.isDateInYesterday(conversation.updatedAt) {
                return .yesterday
            } else if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now),
                conversation.updatedAt > sevenDaysAgo
            {
                return .previous7Days
            } else if let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now),
                conversation.updatedAt > thirtyDaysAgo
            {
                return .previous30Days
            } else {
                return .older
            }
        }

        return grouped.sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.sorted { $0.updatedAt > $1.updatedAt }) }
    }

    private var filteredConversations: [ConversationResponse] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return viewModel.conversations
        }
        return searchResults.map(\.conversation)
    }

    private func scheduleSearch() {
        searchTask?.cancel()

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isSearching = false
            searchResults = []
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            do {
                let results = try await NanoChatAPI.shared.searchConversations(
                    search: trimmed,
                    mode: searchMode
                )
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Actions

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
                conversationId: conversation.id, title: newTitle)
            await viewModel.loadConversations()
        } catch {
            errorMessage = error.localizedDescription
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
                conversationId: conversation.id, projectId: projectId)
            showingMoveSheet = false
            conversationToMove = nil
            await viewModel.loadConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Components

struct SidebarListItem: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.scaled(12)) {
                Image(systemName: icon)
                    .font(Theme.font(size: 18))
                    .foregroundStyle(Theme.Colors.text)
                    .frame(width: Theme.scaled(24))

                Text(title)
                    .font(Theme.font(size: 16))
                    .foregroundStyle(Theme.Colors.text)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Theme.scaled(12))
            .padding(.vertical, Theme.scaled(12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SidebarRow: View {
    let conversation: ConversationResponse
    let isSelected: Bool
    var isSelectionMode: Bool = false
    var isChecked: Bool = false

    var body: some View {
        HStack(spacing: Theme.scaled(10)) {
            // Selection checkbox (shown in selection mode)
            if isSelectionMode {
                ZStack {
                    Circle()
                        .fill(isChecked ? Theme.Colors.accent : Color.clear)
                        .frame(width: Theme.scaled(22), height: Theme.scaled(22))
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isChecked ? Theme.Colors.accent : Theme.Colors.textTertiary,
                                    lineWidth: 2)
                        )

                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(Theme.font(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: isChecked)
            }

            Text(conversation.title)
                .font(Theme.font(size: 15))
                .foregroundStyle(Theme.Colors.text)
                .lineLimit(1)

            Spacer(minLength: 0)

            if conversation.pinned && !isSelectionMode {
                Image(systemName: "pin.fill")
                    .font(Theme.font(size: 10))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.scaled(12))
        .padding(.vertical, Theme.scaled(10))
        .background(
            isChecked
                ? Theme.Colors.accent.opacity(0.15)
                : (isSelected ? Theme.Colors.glassSurface : Color.clear)
        )
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: Theme.scaled(8)))
        .padding(.horizontal, Theme.scaled(8))
    }
}

// MARK: - Image Gallery

struct ImageGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var files: [GalleryFile] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var errorMessage: String?
    @State private var selectedImage: ImagePreviewItem?

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 10)
    ]

    private var imageFiles: [GalleryFile] {
        files.filter { $0.mimeType.lowercased().hasPrefix("image/") }
    }

    private var filteredImages: [GalleryFile] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return imageFiles }

        return imageFiles.filter { file in
            file.filename.localizedCaseInsensitiveContains(trimmed)
                || (file.conversationTitle?.localizedCaseInsensitiveContains(trimmed) == true)
                || (file.projectName?.localizedCaseInsensitiveContains(trimmed) == true)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && imageFiles.isEmpty {
                    ProgressView()
                } else if filteredImages.isEmpty {
                    ContentUnavailableView {
                        Label("No Images", systemImage: "photo.on.rectangle.angled")
                    } description: {
                        Text(
                            searchText.isEmpty
                                ? "Generated and uploaded images will appear here."
                                : "No images match your search."
                        )
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(filteredImages, id: \.id) { file in
                                Button {
                                    if let url = resolveURL(for: file) {
                                        selectedImage = ImagePreviewItem(
                                            url: url,
                                            fileName: file.filename,
                                            storageId: file.id
                                        )
                                    }
                                } label: {
                                    ZStack(alignment: .bottomLeading) {
                                        AuthenticatedGalleryThumbnail(
                                            storageId: file.id,
                                            fallbackURL: resolveURL(for: file)
                                        )

                                        LinearGradient(
                                            colors: [.clear, Color.black.opacity(0.65)],
                                            startPoint: .center,
                                            endPoint: .bottom
                                        )
                                        .frame(height: 40)

                                        Text(file.filename)
                                            .font(Theme.font(size: 11, weight: .medium))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                            .padding(.horizontal, 6)
                                            .padding(.bottom, 6)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Theme.Colors.border, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                }
            }
            .background(Theme.Colors.backgroundStart)
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search images")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await loadImages() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await loadImages()
            }
            .refreshable {
                await loadImages()
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .fullScreenCover(item: $selectedImage) { item in
            ImagePreviewView(item: item)
        }
    }

    private func loadImages() async {
        isLoading = true
        defer { isLoading = false }

        do {
            files = try await NanoChatAPI.shared.getGalleryFiles()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolveURL(for file: GalleryFile) -> URL? {
        if file.url.lowercased().hasPrefix("http") {
            return URL(string: file.url)
        }

        let base = APIConfiguration.shared.baseURL
        let cleanBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        let cleanPath = file.url.hasPrefix("/") ? file.url : "/" + file.url
        return URL(string: cleanBase + cleanPath)
    }
}

private struct AuthenticatedGalleryThumbnail: View {
    let storageId: String
    let fallbackURL: URL?

    @State private var imageData: Data?
    @State private var loadFailed = false

    private static let cache = NSCache<NSString, NSData>()

    var body: some View {
        ZStack {
            Theme.Colors.glassSurface

            if let imageData {
                imageView(data: imageData)
            } else if loadFailed {
                Image(systemName: "photo")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.textTertiary)
            } else {
                ProgressView()
                    .tint(Theme.Colors.secondary)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .task(id: taskIdentifier) {
            await loadImage()
        }
    }

    private var taskIdentifier: String {
        "\(storageId)|\(fallbackURL?.absoluteString ?? "")"
    }

    @ViewBuilder
    private func imageView(data: Data) -> some View {
        #if canImport(UIKit)
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(1, contentMode: .fill)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        #elseif canImport(AppKit)
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(1, contentMode: .fill)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        #else
            Image(systemName: "photo")
                .font(.system(size: 18))
                .foregroundStyle(Theme.Colors.textTertiary)
        #endif
    }

    @MainActor
    private func loadImage() async {
        let storageCacheKey = "storage:\(storageId)" as NSString
        if let cached = Self.cache.object(forKey: storageCacheKey) {
            imageData = cached as Data
            loadFailed = false
            return
        }

        do {
            let data = try await NanoChatAPI.shared.downloadStorageData(storageId: storageId)
            Self.cache.setObject(data as NSData, forKey: storageCacheKey)
            imageData = data
            loadFailed = false
            return
        } catch {
            // fall through to URL retry below
        }

        guard let fallbackURL else {
            imageData = nil
            loadFailed = true
            return
        }

        let urlCacheKey = "url:\(fallbackURL.absoluteString)" as NSString
        if let cached = Self.cache.object(forKey: urlCacheKey) {
            imageData = cached as Data
            loadFailed = false
            return
        }

        do {
            let data = try await NanoChatAPI.shared.downloadData(from: fallbackURL)
            Self.cache.setObject(data as NSData, forKey: urlCacheKey)
            imageData = data
            loadFailed = false
        } catch {
            imageData = nil
            loadFailed = true
        }
    }
}
