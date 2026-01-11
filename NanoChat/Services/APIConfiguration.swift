import Foundation

struct APIConfiguration {
    static let shared = APIConfiguration()

    let baseURL: String
    let apiKey: String?

    private init() {
        // Default to production server, can be overridden in settings
        self.baseURL = UserDefaults.standard.string(forKey: "api_base_url") ?? "https://t3.0xgingi.xyz"
        self.apiKey = UserDefaults.standard.string(forKey: "api_key")
    }

    func save(baseURL: String) {
        UserDefaults.standard.set(baseURL, forKey: "api_base_url")
    }

    func save(apiKey: String) {
        UserDefaults.standard.set(apiKey, forKey: "api_key")
    }
}
