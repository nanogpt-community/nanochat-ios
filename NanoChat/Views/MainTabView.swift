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

            AssistantsListView()
                .tabItem {
                    Label("Assistants", systemImage: selectedTab == 1 ? "person.2.fill" : "person.2")
                }
                .tag(1)

            ProjectsListView()
                .tabItem {
                    Label("Projects", systemImage: selectedTab == 2 ? "folder.fill" : "folder")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                }
                .tag(3)
        }
        .tint(Theme.Colors.accent)
    }
}
