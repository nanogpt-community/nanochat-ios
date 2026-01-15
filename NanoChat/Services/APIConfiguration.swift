import Foundation

final class APIConfiguration: @unchecked Sendable {
    static let shared = APIConfiguration()

    private let baseURLKey = "api_base_url"
    private let defaultBaseURL = "https://t3.0xgingi.xyz"
    private let keychain = KeychainManager.shared

    /// Always reads fresh from UserDefaults
    var baseURL: String {
        UserDefaults.standard.string(forKey: baseURLKey) ?? defaultBaseURL
    }

    /// Always reads fresh from Keychain (secure storage)
    var apiKey: String? {
        // First check Keychain
        if let keychainKey = keychain.get(.apiKey) {
            return keychainKey
        }
        // Migration: check if key exists in UserDefaults (old location)
        if let legacyKey = UserDefaults.standard.string(forKey: "api_key") {
            // Migrate to Keychain
            _ = keychain.save(legacyKey, for: .apiKey)
            UserDefaults.standard.removeObject(forKey: "api_key")
            return legacyKey
        }
        return nil
    }

    private init() {}

    func save(baseURL: String) {
        UserDefaults.standard.set(baseURL, forKey: baseURLKey)
    }

    func save(apiKey: String) {
        _ = keychain.save(apiKey, for: .apiKey)
        // Also remove from UserDefaults if it was there (migration cleanup)
        UserDefaults.standard.removeObject(forKey: "api_key")
    }

    func clearCredentials() {
        keychain.delete(.apiKey)
        UserDefaults.standard.removeObject(forKey: "api_key")
    }
}
