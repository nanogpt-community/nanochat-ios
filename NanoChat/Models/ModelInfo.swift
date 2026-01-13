import Foundation

struct ModelInfoResponse: Codable, Hashable {
    let model: ModelInfo
    let benchmarks: ModelBenchmarks
}

struct ModelInfo: Codable, Hashable {
    let id: String
    let name: String
    let description: String?
    let iconUrl: String?
    let ownedBy: String?
    let contextLength: Int?
    let maxOutputTokens: Int?
    let created: Double?
    let pricing: ModelPricing?
    let costEstimate: Double?
    let subscription: ModelSubscription?
    let capabilities: ModelCapabilities?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case iconUrl = "icon_url"
        case ownedBy = "owned_by"
        case contextLength = "context_length"
        case maxOutputTokens = "max_output_tokens"
        case created
        case pricing
        case costEstimate = "cost_estimate"
        case subscription
        case capabilities
    }
}

struct ModelPricing: Codable, Hashable {
    let prompt: String?
    let completion: String?
    let image: String?
    let request: String?
}

struct ModelSubscription: Codable, Hashable {
    let included: Bool
    let note: String?
}

struct ModelBenchmarks: Codable, Hashable {
    let available: Bool
    let stale: Bool?
    let source: String?
    let sourceUrl: String?
    let llm: LlmBenchmark?
    let image: ImageBenchmark?

    enum CodingKeys: String, CodingKey {
        case available
        case stale
        case source
        case sourceUrl = "source_url"
        case llm
        case image
    }
}

struct LlmBenchmark: Codable, Hashable {
    let name: String
    let slug: String
    let intelligence: Double?
    let coding: Double?
    let math: Double?
    let speedTokensPerSecond: Double?

    enum CodingKeys: String, CodingKey {
        case name
        case slug
        case intelligence
        case coding
        case math
        case speedTokensPerSecond = "speed_tokens_per_second"
    }
}

struct ImageBenchmark: Codable, Hashable {
    let name: String
    let slug: String
    let elo: Double?
    let rank: Int?
}
