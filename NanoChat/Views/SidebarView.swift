import SwiftUI

struct SidebarView: View {
    @Binding var selectedConversation: ConversationResponse?
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ChatViewModel
    @State private var searchText = ""
    @State private var showSettings = false
    
    // For navigation to other sections
    @State private var showAssistants = false
    @State private var showProjects = false
    @State private var showStarred = false
    
    // Conversation Management State
    @State private var showingRenameDialog = false
    @State private var conversationToRename: ConversationResponse?
    @State private var newConversationTitle = ""
    @State private var showingMoveSheet = false
    @State private var conversationToMove: ConversationResponse?
    @State private var projects: [ProjectResponse] = []
    @State private var isLoadingProjects = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Dark Sidebar Background
            Theme.Colors.glassSurface
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header: Search & Navigation
                VStack(spacing: 12) {
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        
                        TextField("Search", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.text)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.glassBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Main Navigation Links (Compact)
                    HStack(spacing: 4) {
                        SidebarLink(icon: "sparkles", title: "Assistants", action: { showAssistants = true })
                        SidebarLink(icon: "folder", title: "Projects", action: { showProjects = true })
                        SidebarLink(icon: "star", title: "Starred", action: { showStarred = true })
                    }
                }
                .padding()
                
                // Conversations List
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                        if viewModel.isLoading && viewModel.conversations.isEmpty {
                            ProgressView()
                                .tint(Theme.Colors.secondary)
                                .padding()
                        } else {
                            let grouped = groupConversations(filteredConversations)
                            
                            ForEach(grouped, id: \.0) { group, conversations in
                                Section(header: 
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
                                            selectedConversation = conversation
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                isPresented = false
                                            }
                                        } label: {
                                            SidebarRow(conversation: conversation, isSelected: selectedConversation?.id == conversation.id)
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button {
                                                Task { await togglePin(conversation) }
                                            } label: {
                                                Label(conversation.pinned ? "Unpin" : "Pin", systemImage: conversation.pinned ? "pin.slash" : "pin")
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
                                            
                                            Divider()
                                            
                                            Button(role: .destructive) {
                                                Task { await viewModel.deleteConversation(id: conversation.id); await viewModel.loadConversations() }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
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
                
                // User Footer
                VStack(spacing: 0) {
                    Divider()
                        .overlay(Theme.Colors.border)
                    
                    Button {
                        showSettings = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("User")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Theme.Colors.text)
                                Text("Settings")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "ellipsis")
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                        .padding()
                        .background(Theme.Colors.glassSurface)
                    }
                    .buttonStyle(.plain)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: 1)
            }
            .frame(width: 300) // Constrain width to match RootView offset
        }
        .sheet(isPresented: $showAssistants) { AssistantsListView() }
        .sheet(isPresented: $showProjects) { ProjectsListView() }
        .sheet(isPresented: $showStarred) { StarredMessagesView() }
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
    
    private func groupConversations(_ conversations: [ConversationResponse]) -> [(DateGroup, [ConversationResponse])] {
        let calendar = Calendar.current
        let now = Date()
        
        let grouped = Dictionary(grouping: conversations) { conversation -> DateGroup in
            if calendar.isDateInToday(conversation.updatedAt) {
                return .today
            } else if calendar.isDateInYesterday(conversation.updatedAt) {
                return .yesterday
            } else if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now),
                      conversation.updatedAt > sevenDaysAgo {
                return .previous7Days
            } else if let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now),
                      conversation.updatedAt > thirtyDaysAgo {
                return .previous30Days
            } else {
                return .older
            }
        }
        
        return grouped.sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.sorted { $0.updatedAt > $1.updatedAt }) }
    }
    
    private var filteredConversations: [ConversationResponse] {
        if searchText.isEmpty {
            return viewModel.conversations
        }
        return viewModel.conversations.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
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
            try await NanoChatAPI.shared.updateConversationTitle(conversationId: conversation.id, title: newTitle)
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
    
    private func moveConversation(_ conversation: ConversationResponse, to projectId: String?) async {
        HapticManager.shared.tap()
        do {
            try await viewModel.setConversationProject(conversationId: conversation.id, projectId: projectId)
            showingMoveSheet = false
            conversationToMove = nil
            await viewModel.loadConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Components

struct SidebarLink: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Theme.Colors.glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct SidebarRow: View {
    let conversation: ConversationResponse
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Text(conversation.title)
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? Theme.Colors.text : Theme.Colors.textSecondary)
                .lineLimit(1)
            
            Spacer()
            
            if conversation.pinned {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            isSelected ? Theme.Colors.secondary.opacity(0.1) : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 8)
    }
}
