import Foundation
import SwiftData

@Model
final class Conversation {
    var id: String
    var title: String
    var userId: String
    var projectId: String?
    var pinned: Bool
    var generating: Bool
    var costUsd: Double?
    var createdAt: Date
    var updatedAt: Date
    var isPublic: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    var messages: [Message] = []

    init(
        id: String,
        title: String,
        userId: String,
        projectId: String? = nil,
        pinned: Bool = false,
        generating: Bool = false,
        costUsd: Double? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isPublic: Bool = false
    ) {
        self.id = id
        self.title = title
        self.userId = userId
        self.projectId = projectId
        self.pinned = pinned
        self.generating = generating
        self.costUsd = costUsd
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPublic = isPublic
    }
}

struct ConversationResponse: Codable, Hashable {
    let id: String
    let title: String
    let userId: String
    let projectId: String?
    let pinned: Bool
    let generating: Bool
    let costUsd: Double?
    let createdAt: Date
    let updatedAt: Date
    let isPublic: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case userId
        case projectId
        case pinned
        case generating
        case costUsd
        case createdAt
        case updatedAt
        case isPublic
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        userId = try container.decode(String.self, forKey: .userId)
        projectId = try container.decodeIfPresent(String.self, forKey: .projectId)
        pinned = try container.decode(Bool.self, forKey: .pinned)
        generating = try container.decode(Bool.self, forKey: .generating)
        costUsd = try container.decodeIfPresent(Double.self, forKey: .costUsd)
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic)

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
        title: String,
        userId: String,
        projectId: String? = nil,
        pinned: Bool = false,
        generating: Bool = false,
        costUsd: Double? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isPublic: Bool = false
    ) {
        self.id = id
        self.title = title
        self.userId = userId
        self.projectId = projectId
        self.pinned = pinned
        self.generating = generating
        self.costUsd = costUsd
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPublic = isPublic
    }
}

struct CreateConversationRequest: Codable {
    let action: String
    let title: String
    let projectId: String?
}
