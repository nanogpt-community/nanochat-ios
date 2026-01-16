import SwiftUI

#if os(macOS)
private let navScaleFactor: CGFloat = 1.5
#else
private let navScaleFactor: CGFloat = {
    if ProcessInfo.processInfo.isiOSAppOnMac {
        return 1.5
    }
    return 1.0
}()
#endif

@main
struct NanoChatApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .onAppear {
                    setupAppearance()
                }
        }
    }

    private func setupAppearance() {
        // Configure Navigation Bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        navAppearance.backgroundColor = UIColor(Theme.Colors.glassBackground)
        
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17 * navScaleFactor, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34 * navScaleFactor, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(Theme.Colors.accent)
        
        // Configure Tab Bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        tabAppearance.backgroundColor = UIColor(Theme.Colors.glassBackground)
        
        let itemAppearance = UITabBarItemAppearance()
        let tabFont = UIFont.systemFont(ofSize: 10 * navScaleFactor, weight: .medium)
        
        itemAppearance.normal.iconColor = UIColor(Theme.Colors.textTertiary)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.textTertiary),
            .font: tabFont
        ]
        itemAppearance.selected.iconColor = UIColor(Theme.Colors.accent)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.accent),
            .font: tabFont
        ]
        
        tabAppearance.stackedLayoutAppearance = itemAppearance
        tabAppearance.inlineLayoutAppearance = itemAppearance
        tabAppearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        // Configure other UI elements
        UITextField.appearance().keyboardAppearance = .dark
        UITextField.appearance().tintColor = UIColor(Theme.Colors.accent)
        UITextView.appearance().tintColor = UIColor(Theme.Colors.accent)
        UITableView.appearance().backgroundColor = .clear
    }
}
