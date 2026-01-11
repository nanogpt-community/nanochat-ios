import Foundation
import SwiftData

@Model
final class Project {
    var id: String
    var name: String
    var projectDescription: String?
    var systemPrompt: String?
    var color: String?
    var role: String
    var isShared: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        name: String,
        projectDescription: String? = nil,
        systemPrompt: String? = nil,
        color: String? = nil,
        role: String = "owner",
        isShared: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.projectDescription = projectDescription
        self.systemPrompt = systemPrompt
        self.color = color
        self.role = role
        self.isShared = isShared
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct ProjectResponse: Codable {
    let id: String
    let name: String
    let description: String?
    let systemPrompt: String?
    let color: String?
    let role: String
    let isShared: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case systemPrompt
        case color
        case role
        case isShared
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        systemPrompt = try container.decodeIfPresent(String.self, forKey: .systemPrompt)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        role = try container.decode(String.self, forKey: .role)
        isShared = try container.decode(Bool.self, forKey: .isShared)

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
        systemPrompt: String? = nil,
        color: String? = nil,
        role: String = "owner",
        isShared: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.systemPrompt = systemPrompt
        self.color = color
        self.role = role
        self.isShared = isShared
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct CreateProjectRequest: Codable {
    let name: String
    let description: String?
    let systemPrompt: String?
    let color: String?
}
