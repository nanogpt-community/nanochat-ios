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

    /// Validates credentials by making a test API call, then saves if successful
    func validateAndSaveCredentials() async {
        isLoading = true
        errorMessage = nil

        // Temporarily save credentials so API can use them
        config.save(apiKey: apiKey)
        config.save(baseURL: baseURL)

        do {
            // Try to fetch conversations as a validation check
            _ = try await NanoChatAPI.shared.getConversations()
            // Success - credentials are valid
            isAuthenticated = true
        } catch let error as APIError {
            // Validation failed - clear the invalid credentials
            config.clearCredentials()

            switch error {
            case .httpError(let statusCode):
                if statusCode == 401 || statusCode == 403 {
                    errorMessage = "Invalid API key. Please check your credentials."
                } else if statusCode == 404 {
                    errorMessage = "Server not found. Please check the URL."
                } else {
                    errorMessage = "Server error (\(statusCode)). Please try again."
                }
            case .invalidURL:
                errorMessage = "Invalid server URL."
            case .invalidResponse:
                errorMessage = "Invalid response from server. Check the URL."
            default:
                errorMessage = "Connection failed: \(error.localizedDescription)"
            }
        } catch {
            // Network or other error - clear the invalid credentials
            config.clearCredentials()

            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet:
                    errorMessage = "No internet connection."
                case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                    errorMessage = "Cannot connect to server. Check the URL."
                case NSURLErrorTimedOut:
                    errorMessage = "Connection timed out. Please try again."
                default:
                    errorMessage = "Connection failed. Check your settings."
                }
            } else {
                errorMessage = "Connection failed: \(error.localizedDescription)"
            }
        }

        isLoading = false
    }

    func saveCredentials() {
        config.save(apiKey: apiKey)
        config.save(baseURL: baseURL)
        isAuthenticated = !apiKey.isEmpty
    }

    func clearCredentials() {
        apiKey = ""
        errorMessage = nil
        isAuthenticated = false
        config.clearCredentials()
    }
}
