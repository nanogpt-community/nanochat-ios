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
        ZStack {
            // Darker background for sidebar (Drawer style)
            Theme.Colors.glassSurface
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.Colors.textTertiary)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Theme.Colors.text)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.glassBackground) // Slightly lighter/darker
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                
                // Main Navigation Links
                VStack(spacing: Theme.Spacing.xs) {
                    SidebarLink(icon: "sparkles", title: "Assistants", color: .primary) {
                        showAssistants = true
                    }
                    
                    SidebarLink(icon: "folder", title: "Projects", color: .primary) {
                        showProjects = true
                    }
                    
                    SidebarLink(icon: "star", title: "Starred", color: .primary) {
                        showStarred = true
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, Theme.Spacing.md)

                // Conversations List
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.xs) {
                        if viewModel.isLoading && viewModel.conversations.isEmpty {
                            ProgressView()
                                .tint(Theme.Colors.secondary)
                                .padding()
                        } else {
                            // Section Header for Recent
                            HStack {
                                Text("Recent")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, Theme.Spacing.sm)
                            
                            ForEach(filteredConversations, id: \.id) { conversation in
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
                                        newConversationTitle = conversation.title
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
                                            // Refresh list logic if needed, viewModel usually handles it via published property
                                            await viewModel.loadConversations()
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80) // Space for user footer
                }
                
                Spacer()
                
                // User / Settings Footer
                Button {
                    showSettings = true
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(Theme.Colors.textSecondary)
                        
                        Text("User Settings")
                            .font(Theme.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.Colors.text)
                        
                        Spacer()
                        
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding()
                    .background(Theme.Colors.glassBackground)
                }
                .buttonStyle(.plain)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: 1)
            }
        }
        .sheet(isPresented: $showAssistants) {
            AssistantsListView()
        }
        .sheet(isPresented: $showProjects) {
            ProjectsListView()
        }
        .sheet(isPresented: $showStarred) {
            StarredMessagesView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
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
        .onAppear {
            Task {
                await viewModel.loadConversations()
            }
        }
    }
    
    private var filteredConversations: [ConversationResponse] {
        if searchText.isEmpty {
            return viewModel.conversations
        }
        return viewModel.conversations.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    // MARK: - Helper Methods
    
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
            await viewModel.loadConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SidebarLink: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.text)
                
                Spacer()
            }
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.md)
            .background(Color.clear) // Clean background
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SidebarRow: View {
    let conversation: ConversationResponse
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.title)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(isSelected ? Theme.Colors.text : Theme.Colors.textSecondary)
                    .lineLimit(1)
                
                if conversation.pinned {
                    HStack(spacing: 4) {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                        Text("Pinned")
                            .font(.caption2)
                    }
                    .foregroundStyle(Theme.Colors.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.md)
        .padding(.horizontal, Theme.Spacing.md)
        .background(
            isSelected ? Theme.Colors.secondary.opacity(0.2) : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .contentShape(Rectangle())
    }
}
