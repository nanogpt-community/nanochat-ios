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
        role = try container.decodeIfPresent(String.self, forKey: .role) ?? "owner"
        isShared = try container.decodeIfPresent(Bool.self, forKey: .isShared) ?? false

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

struct AddProjectMemberRequest: Codable {
    let email: String
    let role: String
}

struct ProjectUserResponse: Codable {
    let id: String
    let name: String?
    let email: String?
    let image: String?
}

struct ProjectMemberResponse: Codable, Identifiable {
    let id: String
    let projectId: String?
    let userId: String
    let role: String
    let user: ProjectUserResponse
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case projectId
        case userId
        case role
        case user
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        projectId = try container.decodeIfPresent(String.self, forKey: .projectId)
        userId = try container.decode(String.self, forKey: .userId)
        role = try container.decodeIfPresent(String.self, forKey: .role) ?? "viewer"
        user = try container.decode(ProjectUserResponse.self, forKey: .user)

        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: createdAtString)
        } else {
            createdAt = nil
        }
    }
}

struct ProjectStorageResponse: Codable {
    let id: String
    let userId: String
    let filename: String
    let mimeType: String
    let size: Int
    let path: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case filename
        case mimeType
        case size
        case path
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        filename = try container.decode(String.self, forKey: .filename)
        mimeType = try container.decode(String.self, forKey: .mimeType)
        size = try container.decode(Int.self, forKey: .size)
        path = try container.decode(String.self, forKey: .path)

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let createdDate = formatter.date(from: createdAtString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt,
                in: container,
                debugDescription: "Cannot decode ISO 8601 date string"
            )
        }
        createdAt = createdDate
    }
}

struct ProjectFileResponse: Codable, Identifiable {
    let id: String
    let projectId: String
    let storageId: String
    let fileName: String
    let fileType: String
    let extractedContent: String?
    let createdAt: Date
    let storage: ProjectStorageResponse?

    enum CodingKeys: String, CodingKey {
        case id
        case projectId
        case storageId
        case fileName
        case fileType
        case extractedContent
        case createdAt
        case storage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        projectId = try container.decode(String.self, forKey: .projectId)
        storageId = try container.decode(String.self, forKey: .storageId)
        fileName = try container.decode(String.self, forKey: .fileName)
        fileType = try container.decode(String.self, forKey: .fileType)
        extractedContent = try container.decodeIfPresent(String.self, forKey: .extractedContent)
        storage = try container.decodeIfPresent(ProjectStorageResponse.self, forKey: .storage)

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let createdDate = formatter.date(from: createdAtString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt,
                in: container,
                debugDescription: "Cannot decode ISO 8601 date string"
            )
        }
        createdAt = createdDate
    }
}

struct UpdateProjectRequest: Encodable {
    let name: String
    let description: String?
    let systemPrompt: String?
    let color: String?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case systemPrompt
        case color
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)

        if let description {
            try container.encode(description, forKey: .description)
        } else {
            try container.encodeNil(forKey: .description)
        }

        if let systemPrompt {
            try container.encode(systemPrompt, forKey: .systemPrompt)
        } else {
            try container.encodeNil(forKey: .systemPrompt)
        }

        if let color {
            try container.encode(color, forKey: .color)
        } else {
            try container.encodeNil(forKey: .color)
        }
    }
}
