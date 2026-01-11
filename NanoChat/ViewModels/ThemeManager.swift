import Foundation
import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    enum Theme: String, CaseIterable {
        case system
        case light
        case dark
    }

    @Published var currentTheme: Theme {
        didSet {
            saveTheme()
        }
    }

    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selected_theme"),
           let theme = Theme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
    }

    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "selected_theme")
    }
}
