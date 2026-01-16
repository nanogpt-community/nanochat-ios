import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()
            
            Group {
                if authManager.isAuthenticated {
                    // Switch to RootView (Sidebar + Chat)
                    RootView()
                } else {
                    AuthenticationView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
}
