import Foundation
import SwiftUI

struct UserModel: Codable, Identifiable, Hashable {
    let modelId: String
    let provider: String
    let enabled: Bool
    let pinned: Bool

    // Additional details that we might fetch
    let name: String?
    let description: String?
    let capabilities: ModelCapabilities?
    let costEstimate: Double?

    // Use modelId as the id for Identifiable
    var id: String { modelId }

    enum CodingKeys: String, CodingKey {
        case modelId
        case provider
        case enabled
        case pinned
        case name
        case description
        case capabilities
        case costEstimate
    }
}

struct ModelCapabilities: Codable, Hashable {
    let vision: Bool?
    let reasoning: Bool?
    let images: Bool?
    let video: Bool?
}

struct ProviderInfo: Codable, Identifiable, Hashable {
    let provider: String
    let pricing: ProviderPricing
    let available: Bool

    var id: String { provider }

    struct ProviderPricing: Codable, Hashable {
        let inputPer1kTokens: Double
        let outputPer1kTokens: Double
    }
}

struct ModelProvidersResponse: Codable {
    let canonicalId: String
    let displayName: String
    let supportsProviderSelection: Bool
    let defaultPrice: ProviderPricing?
    let providers: [ProviderInfo]
    let error: String?

    struct ProviderPricing: Codable {
        let inputPer1kTokens: Double
        let outputPer1kTokens: Double
    }
}

struct ModelGroup: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let models: [UserModel]
}

// Helper to categorize models
extension [UserModel] {
    func groupedByProvider() -> [ModelGroup] {
        let grouped = Dictionary(grouping: self) { $0.provider }

        // Sort providers: pinned models first, then alphabetically
        let sortedProviders = grouped.keys.sorted { provider1, provider2 in
            let hasPinned1 = grouped[provider1]?.contains(where: { $0.pinned }) ?? false
            let hasPinned2 = grouped[provider2]?.contains(where: { $0.pinned }) ?? false

            if hasPinned1 && !hasPinned2 {
                return true
            } else if !hasPinned1 && hasPinned2 {
                return false
            } else {
                return provider1 < provider2
            }
        }

        return sortedProviders.map { provider in
            let models = grouped[provider]?
                .sorted { model1, model2 in
                    if model1.pinned && !model2.pinned {
                        return true
                    } else if !model1.pinned && model2.pinned {
                        return false
                    } else {
                        return (model1.name ?? model1.modelId) < (model2.name ?? model2.modelId)
                    }
                } ?? []

            return ModelGroup(name: provider, models: models)
        }
    }

    func filterEnabled() -> [UserModel] {
        self.filter { $0.enabled }
    }
}
