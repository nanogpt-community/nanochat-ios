import Foundation

struct ModelPerformanceStat: Codable, Identifiable, Hashable {
    let id: String
    let modelId: String
    let provider: String
    let totalMessages: Int
    let avgRating: Double?
    let thumbsUpCount: Int
    let thumbsDownCount: Int
    let regenerateCount: Int
    let avgResponseTime: Double?
    let avgTokens: Double?
    let totalCost: Double
    let errorCount: Int
    let accurateCount: Int
    let helpfulCount: Int
    let creativeCount: Int
    let fastCount: Int
    let costEffectiveCount: Int
}

struct AnalyticsInsights: Codable, Hashable {
    let totalMessages: Int
    let totalCost: Double
    let avgRating: Double?
    let mostUsedModel: ModelPerformanceStat?
    let bestRatedModel: ModelPerformanceStat?
    let mostCostEffective: ModelPerformanceStat?
    let fastestModel: ModelPerformanceStat?
}

struct AnalyticsResponse: Codable, Hashable {
    let stats: [ModelPerformanceStat]
    let insights: AnalyticsInsights
}
