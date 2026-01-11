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
    var createdAt: Date
    var updatedAt: Date?

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
        createdAt: Date = .now,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.contentHtml = contentHtml
        self.modelId = modelId
        self.reasoning = reasoning
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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

struct MessageResponse: Codable {
    let id: String
    let conversationId: String
    let role: String
    let content: String
    let contentHtml: String?
    let modelId: String?
    let reasoning: String?
    let images: [MessageImageResponse]?
    let documents: [MessageDocumentResponse]?
    let createdAt: Date
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId
        case role
        case content
        case contentHtml
        case modelId
        case reasoning
        case images
        case documents
        case createdAt
        case updatedAt
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
        images = try container.decodeIfPresent([MessageImageResponse].self, forKey: .images)
        documents = try container.decodeIfPresent([MessageDocumentResponse].self, forKey: .documents)

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
    }

    init(
        id: String,
        conversationId: String,
        role: String,
        content: String,
        contentHtml: String? = nil,
        modelId: String? = nil,
        reasoning: String? = nil,
        images: [MessageImageResponse]? = nil,
        documents: [MessageDocumentResponse]? = nil,
        createdAt: Date = .now,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.contentHtml = contentHtml
        self.modelId = modelId
        self.reasoning = reasoning
        self.images = images
        self.documents = documents
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
