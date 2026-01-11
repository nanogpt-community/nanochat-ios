import Foundation
import SwiftData

@Model
final class Assistant {
    var id: String
    var name: String
    var assistantDescription: String?
    var systemPrompt: String
    var isDefault: Bool
    var defaultModelId: String?
    var defaultWebSearchMode: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        name: String,
        assistantDescription: String? = nil,
        systemPrompt: String,
        isDefault: Bool = false,
        defaultModelId: String? = nil,
        defaultWebSearchMode: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.assistantDescription = assistantDescription
        self.systemPrompt = systemPrompt
        self.isDefault = isDefault
        self.defaultModelId = defaultModelId
        self.defaultWebSearchMode = defaultWebSearchMode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct AssistantResponse: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let systemPrompt: String
    let isDefault: Bool
    let defaultModelId: String?
    let defaultWebSearchMode: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case systemPrompt
        case isDefault
        case defaultModelId
        case defaultWebSearchMode
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        isDefault = try container.decode(Bool.self, forKey: .isDefault)
        defaultModelId = try container.decodeIfPresent(String.self, forKey: .defaultModelId)
        defaultWebSearchMode = try container.decodeIfPresent(String.self, forKey: .defaultWebSearchMode)

        // Decode ISO 8601 date strings
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let createdDate = dateFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt,
                in: container,
                debugDescription: "Cannot decode ISO 8601 date string"
            )
        }

        guard let updatedDate = dateFormatter.date(from: updatedAtString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .updatedAt,
                in: container,
                debugDescription: "Cannot decode ISO 8601 date string"
            )
        }

        createdAt = createdDate
        updatedAt = updatedDate
    }

    init(
        id: String,
        name: String,
        description: String? = nil,
        systemPrompt: String,
        isDefault: Bool = false,
        defaultModelId: String? = nil,
        defaultWebSearchMode: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.systemPrompt = systemPrompt
        self.isDefault = isDefault
        self.defaultModelId = defaultModelId
        self.defaultWebSearchMode = defaultWebSearchMode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct CreateAssistantRequest: Codable {
    let name: String
    let systemPrompt: String
    let defaultModelId: String?
    let defaultWebSearchMode: String?
    let defaultWebSearchProvider: String?
}
