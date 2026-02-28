import Foundation

struct UserSettings: Codable, Sendable {
    let id: String
    let userId: String
    var timezone: String
    var privacyMode: Bool
    var contextMemoryEnabled: Bool
    var persistentMemoryEnabled: Bool
    var youtubeTranscriptsEnabled: Bool
    var webScrapingEnabled: Bool
    var mcpEnabled: Bool
    var followUpQuestionsEnabled: Bool
    var suggestedPromptsEnabled: Bool
    var freeMessagesUsed: Int
    var dailyMessagesUsed: Int
    var lastMessageDate: String?
    var karakeepUrl: String?
    var karakeepApiKey: String?
    var theme: String?
    var titleModelId: String?
    var titleProviderId: String?
    var followUpModelId: String?
    var followUpProviderId: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "userId"
        case timezone = "timezone"
        case privacyMode = "privacyMode"
        case contextMemoryEnabled = "contextMemoryEnabled"
        case persistentMemoryEnabled = "persistentMemoryEnabled"
        case youtubeTranscriptsEnabled = "youtubeTranscriptsEnabled"
        case webScrapingEnabled = "webScrapingEnabled"
        case mcpEnabled = "mcpEnabled"
        case followUpQuestionsEnabled = "followUpQuestionsEnabled"
        case suggestedPromptsEnabled = "suggestedPromptsEnabled"
        case freeMessagesUsed = "freeMessagesUsed"
        case dailyMessagesUsed = "dailyMessagesUsed"
        case lastMessageDate = "lastMessageDate"
        case karakeepUrl = "karakeepUrl"
        case karakeepApiKey = "karakeepApiKey"
        case theme
        case titleModelId = "titleModelId"
        case titleProviderId = "titleProviderId"
        case followUpModelId = "followUpModelId"
        case followUpProviderId = "followUpProviderId"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        timezone =
            try container.decodeIfPresent(String.self, forKey: .timezone)
            ?? TimeZone.current.identifier
        privacyMode = try container.decodeIfPresent(Bool.self, forKey: .privacyMode) ?? false
        contextMemoryEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .contextMemoryEnabled) ?? false
        persistentMemoryEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .persistentMemoryEnabled) ?? false
        youtubeTranscriptsEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .youtubeTranscriptsEnabled) ?? false
        webScrapingEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .webScrapingEnabled) ?? false
        mcpEnabled = try container.decodeIfPresent(Bool.self, forKey: .mcpEnabled) ?? false
        followUpQuestionsEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .followUpQuestionsEnabled) ?? true
        suggestedPromptsEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .suggestedPromptsEnabled) ?? true
        freeMessagesUsed = try container.decodeIfPresent(Int.self, forKey: .freeMessagesUsed) ?? 0
        dailyMessagesUsed = try container.decodeIfPresent(Int.self, forKey: .dailyMessagesUsed) ?? 0
        lastMessageDate = try container.decodeIfPresent(String.self, forKey: .lastMessageDate)
        karakeepUrl = try container.decodeIfPresent(String.self, forKey: .karakeepUrl)
        karakeepApiKey = try container.decodeIfPresent(String.self, forKey: .karakeepApiKey)
        theme = try container.decodeIfPresent(String.self, forKey: .theme)
        titleModelId = try container.decodeIfPresent(String.self, forKey: .titleModelId)
        titleProviderId = try container.decodeIfPresent(String.self, forKey: .titleProviderId)
        followUpModelId = try container.decodeIfPresent(String.self, forKey: .followUpModelId)
        followUpProviderId = try container.decodeIfPresent(String.self, forKey: .followUpProviderId)

        // Try to decode dates, but use current date if decoding fails
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let createdAtString = try? container.decode(String.self, forKey: .createdAt),
            let createdDate = dateFormatter.date(from: createdAtString)
        {
            createdAt = createdDate
        } else {
            createdAt = Date()
        }

        if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt),
            let updatedDate = dateFormatter.date(from: updatedAtString)
        {
            updatedAt = updatedDate
        } else {
            updatedAt = Date()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(timezone, forKey: .timezone)
        try container.encode(privacyMode, forKey: .privacyMode)
        try container.encode(contextMemoryEnabled, forKey: .contextMemoryEnabled)
        try container.encode(persistentMemoryEnabled, forKey: .persistentMemoryEnabled)
        try container.encode(youtubeTranscriptsEnabled, forKey: .youtubeTranscriptsEnabled)
        try container.encode(webScrapingEnabled, forKey: .webScrapingEnabled)
        try container.encode(mcpEnabled, forKey: .mcpEnabled)
        try container.encode(followUpQuestionsEnabled, forKey: .followUpQuestionsEnabled)
        try container.encode(suggestedPromptsEnabled, forKey: .suggestedPromptsEnabled)
        try container.encode(freeMessagesUsed, forKey: .freeMessagesUsed)
        try container.encode(dailyMessagesUsed, forKey: .dailyMessagesUsed)
        try container.encodeIfPresent(lastMessageDate, forKey: .lastMessageDate)
        try container.encodeIfPresent(karakeepUrl, forKey: .karakeepUrl)
        try container.encodeIfPresent(karakeepApiKey, forKey: .karakeepApiKey)
        try container.encodeIfPresent(theme, forKey: .theme)
        try container.encodeIfPresent(titleModelId, forKey: .titleModelId)
        try container.encodeIfPresent(titleProviderId, forKey: .titleProviderId)
        try container.encodeIfPresent(followUpModelId, forKey: .followUpModelId)
        try container.encodeIfPresent(followUpProviderId, forKey: .followUpProviderId)

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
}
