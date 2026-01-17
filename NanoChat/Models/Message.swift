import Foundation
import SwiftData

@Model
final class Message {
    var id: String
    var conversationId: String
    var role: String
    var content: String
    var contentHtml: String?
    var modelId: String?
    var reasoning: String?
    var starred: Bool
    var createdAt: Date
    var updatedAt: Date?
    var followUpSuggestions: [String]?

    var conversation: Conversation?

    @Relationship(deleteRule: .cascade)
    var images: [MessageImage] = []

    @Relationship(deleteRule: .cascade)
    var documents: [MessageDocument] = []

    init(
        id: String,
        conversationId: String,
        role: String,
        content: String,
        contentHtml: String? = nil,
        modelId: String? = nil,
        reasoning: String? = nil,
        starred: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        followUpSuggestions: [String]? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.contentHtml = contentHtml
        self.modelId = modelId
        self.reasoning = reasoning
        self.starred = starred
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.followUpSuggestions = followUpSuggestions
    }
}

@Model
final class MessageImage {
    var id: String
    var url: String
    var storageId: String
    var fileName: String?

    init(id: String, url: String, storageId: String, fileName: String? = nil) {
        self.id = id
        self.url = url
        self.storageId = storageId
        self.fileName = fileName
    }
}

@Model
final class MessageDocument {
    var id: String
    var url: String
    var storageId: String
    var fileName: String?
    var fileType: String

    init(id: String, url: String, storageId: String, fileName: String? = nil, fileType: String) {
        self.id = id
        self.url = url
        self.storageId = storageId
        self.fileName = fileName
        self.fileType = fileType
    }
}

struct MessageResponse: Codable, Identifiable, Hashable {
    let id: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MessageResponse, rhs: MessageResponse) -> Bool {
        lhs.id == rhs.id
    }
    let conversationId: String
    let role: String
    let content: String
    let contentHtml: String?
    let modelId: String?
    let reasoning: String?
    let starred: Bool?
    let images: [MessageImageResponse]?
    let documents: [MessageDocumentResponse]?
    let createdAt: Date
    let updatedAt: Date?
    let followUpSuggestions: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId
        case role
        case content
        case contentHtml
        case modelId
        case reasoning
        case starred
        case images
        case documents
        case createdAt
        case updatedAt
        case followUpSuggestions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        role = try container.decode(String.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        contentHtml = try container.decodeIfPresent(String.self, forKey: .contentHtml)
        modelId = try container.decodeIfPresent(String.self, forKey: .modelId)
        reasoning = try container.decodeIfPresent(String.self, forKey: .reasoning)
        starred = try container.decodeIfPresent(Bool.self, forKey: .starred)
        images = try container.decodeIfPresent([MessageImageResponse].self, forKey: .images)
        documents = try container.decodeIfPresent(
            [MessageDocumentResponse].self, forKey: .documents)

        // Decode ISO 8601 date strings
        let createdAtString = try container.decode(String.self, forKey: .createdAt)

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let createdDate = dateFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt,
                in: container,
                debugDescription: "Cannot decode ISO 8601 date string"
            )
        }

        createdAt = createdDate

        // updatedAt is optional
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            guard let updatedDate = dateFormatter.date(from: updatedAtString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .updatedAt,
                    in: container,
                    debugDescription: "Cannot decode ISO 8601 date string"
                )
            }
            updatedAt = updatedDate
        } else {
            updatedAt = nil
        }

        followUpSuggestions = try container.decodeIfPresent(
            [String].self, forKey: .followUpSuggestions)
    }

    init(
        id: String,
        conversationId: String,
        role: String,
        content: String,
        contentHtml: String? = nil,
        modelId: String? = nil,
        reasoning: String? = nil,
        starred: Bool? = nil,
        images: [MessageImageResponse]? = nil,
        documents: [MessageDocumentResponse]? = nil,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        followUpSuggestions: [String]? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.contentHtml = contentHtml
        self.modelId = modelId
        self.reasoning = reasoning
        self.starred = starred
        self.images = images
        self.documents = documents
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.followUpSuggestions = followUpSuggestions
    }
}

struct MessageImageResponse: Codable {
    let url: String
    let storageId: String
    let fileName: String?

    enum CodingKeys: String, CodingKey {
        case url
        case storageId = "storage_id"
        case fileName
    }
}

struct MessageDocumentResponse: Codable {
    let url: String
    let storageId: String
    let fileName: String?
    let fileType: String

    enum CodingKeys: String, CodingKey {
        case url
        case storageId = "storage_id"
        case fileName
        case fileType
    }
}

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

// MARK: - Message Metadata

struct MessageMetadata: Codable, Equatable {
    let tokenCount: Int
    let costUsd: Double
    let responseTimeMs: Int
    let modelId: String?

    var tokensPerSecond: Double {
        guard responseTimeMs > 0 else { return 0 }
        return Double(tokenCount) / (Double(responseTimeMs) / 1000.0)
    }

    var formattedCost: String {
        if costUsd < 0.001 {
            return String(format: "$%.6f", costUsd)
        } else if costUsd < 0.01 {
            return String(format: "$%.5f", costUsd)
        } else {
            return String(format: "$%.4f", costUsd)
        }
    }

    var formattedTokens: String {
        return "\(tokenCount) tokens"
    }

    var formattedSpeed: String {
        let speed = tokensPerSecond
        if speed > 0 {
            return String(format: "%.1f t/s", speed)
        }
        return ""
    }
}
