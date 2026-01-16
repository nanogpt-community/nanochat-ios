import SwiftUI

struct RootView: View {
    @State private var showSidebar = false
    @State private var selectedConversation: ConversationResponse?
    @StateObject private var viewModel = ChatViewModel() // For creating new chats
    
    // Drag gesture state
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Sidebar Layer (Main layer when open)
            SidebarView(
                selectedConversation: $selectedConversation,
                isPresented: $showSidebar,
                viewModel: viewModel
            )
            
            // Chat Layer (Slides over)
            ZStack {
                Theme.Colors.backgroundStart
                    .ignoresSafeArea()
                
                if let conversation = selectedConversation {
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
                    .id(conversation.id) // Force recreate when conversation changes
                } else {
                    // Empty state / New Chat placeholder
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
            .offset(x: showSidebar ? 300 : 0) // Slide right
            .shadow(color: .black.opacity(0.1), radius: 10, x: -5, y: 0) // Shadow for depth
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
            await viewModel.createConversation()
            if let newConv = viewModel.currentConversation {
                await MainActor.run {
                    selectedConversation = newConv
                    showSidebar = false
                }
            }
        }
    }
}
