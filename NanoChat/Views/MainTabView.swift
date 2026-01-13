import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ConversationsListView()
                .tabItem {
                    Label("Chats", systemImage: selectedTab == 0 ? "message.fill" : "message")
                }
                .tag(0)

            StarredMessagesView()
                .tabItem {
                    Label("Starred", systemImage: selectedTab == 1 ? "star.fill" : "star")
                }
                .tag(1)

            AssistantsListView()
                .tabItem {
                    Label(
                        "Assistants", systemImage: selectedTab == 2 ? "person.2.fill" : "person.2")
                }
                .tag(2)

            ProjectsListView()
                .tabItem {
                    Label("Projects", systemImage: selectedTab == 3 ? "folder.fill" : "folder")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label(
                        "Settings", systemImage: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                }
                .tag(4)
        }
        .tint(Theme.Colors.accent)
    }
}
