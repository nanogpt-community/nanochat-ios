import Foundation
import SwiftUI

@MainActor
final class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var apiKey: String = ""
    @Published var baseURL: String = "https://t3.0xgingi.xyz"
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let config = APIConfiguration.shared

    init() {
        loadCredentials()
    }

    private func loadCredentials() {
        if let storedKey = config.apiKey, !storedKey.isEmpty {
            self.apiKey = storedKey
            self.isAuthenticated = true
        }
        if let storedURL = UserDefaults.standard.string(forKey: "api_base_url") {
            self.baseURL = storedURL
        }
    }

    func saveCredentials() {
        config.save(apiKey: apiKey)
        config.save(baseURL: baseURL)
        isAuthenticated = !apiKey.isEmpty
    }

    func clearCredentials() {
        apiKey = ""
        isAuthenticated = false
        config.clearCredentials()
    }
}
