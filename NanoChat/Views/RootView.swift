import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSidebar = false
    @State private var selectedConversation: ConversationResponse?
    @StateObject private var viewModel = ChatViewModel()  // For creating new chats
    @State private var connectionError: String?
    @State private var isInitialLoading = true

    // Drag gesture state
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Sidebar Layer (Main layer when open)
            SidebarView(
                selectedConversation: $selectedConversation,
                isPresented: $showSidebar,
                viewModel: viewModel,
                onNewChat: createNewChat
            )

            // Chat Layer (Slides over)
            ZStack {
                Theme.Colors.backgroundStart
                    .ignoresSafeArea()

                if let error = connectionError {
                    // Connection error state with option to return to login
                    connectionErrorView(error: error)
                } else if let conversation = selectedConversation {
                    ChatView(
                        conversation: conversation,
                        showSidebar: $showSidebar,
                        onNewChat: createNewChat,
                        onMessageSent: {
                            Task { @MainActor in
                                await viewModel.loadConversations()
                            }
                        }
                    )
                    .id(conversation.id)  // Force recreate when conversation changes
                } else if isInitialLoading {
                    // Initial loading state
                    VStack(spacing: Theme.Spacing.lg) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Connecting...")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .onAppear {
                        createNewChat()
                    }
                } else {
                    // Fallback empty state
                    ProgressView()
                        .onAppear {
                            createNewChat()
                        }
                }

                // Dimming overlay when sidebar is open
                if showSidebar {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showSidebar = false
                            }
                        }
                }
            }
            .offset(x: showSidebar ? Theme.scaled(300) : 0)  // Slide right
            .shadow(color: .black.opacity(0.1), radius: 10, x: -5, y: 0)  // Shadow for depth
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showSidebar)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        if value.translation.width > 0 && !showSidebar {
                            state = value.translation.width
                        } else if value.translation.width < 0 && showSidebar {
                            state = value.translation.width
                        }
                    }
                    .onEnded { value in
                        if value.translation.width > 100 {
                            showSidebar = true
                        } else if value.translation.width < -100 {
                            showSidebar = false
                        }
                    }
            )
        }
    }

    private func createNewChat() {
        Task {
            // Load conversations first so we can check for existing empty chats
            if viewModel.conversations.isEmpty {
                await viewModel.loadConversations()
            }

            // Check if there was an error loading conversations (likely auth issue)
            if let error = viewModel.errorMessage, viewModel.conversations.isEmpty {
                await MainActor.run {
                    connectionError = error
                    isInitialLoading = false
                }
                return
            }

            await viewModel.createConversation()

            // Check if creating conversation failed
            if let error = viewModel.errorMessage, viewModel.currentConversation == nil {
                await MainActor.run {
                    connectionError = error
                    isInitialLoading = false
                }
                return
            }

            if let newConv = viewModel.currentConversation {
                await MainActor.run {
                    selectedConversation = newConv
                    showSidebar = false
                    isInitialLoading = false
                    connectionError = nil
                }
            }
        }
    }

    @ViewBuilder
    private func connectionErrorView(error: String) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Error icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.error.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundStyle(Theme.Colors.error)
            }

            VStack(spacing: Theme.Spacing.md) {
                Text("Connection Failed")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.Colors.text)

                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            VStack(spacing: Theme.Spacing.md) {
                // Retry button
                Button(action: {
                    connectionError = nil
                    isInitialLoading = true
                    viewModel.errorMessage = nil
                    createNewChat()
                }) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Theme.Colors.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                }
                .buttonStyle(.plain)

                // Update credentials button
                Button(action: {
                    authManager.clearCredentials()
                }) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "key")
                        Text("Update Credentials")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(.ultraThinMaterial)
                    .foregroundStyle(Theme.Colors.text)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.xxl)

            Spacer()
        }
    }
}
