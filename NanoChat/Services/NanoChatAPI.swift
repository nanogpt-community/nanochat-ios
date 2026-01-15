import Foundation
import SwiftUI

final class NanoChatAPI: Sendable {
    static let shared = NanoChatAPI()
    private let config = APIConfiguration.shared
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Generic Request Methods

    private func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryParams: [String: String]? = nil
    ) async throws -> T {
        var urlComponents = URLComponents(string: "\(config.baseURL)\(endpoint)")

        if let queryParams = queryParams {
            urlComponents?.queryItems = queryParams.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }

        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add API key if available
        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        // Add body for POST/PATCH/DELETE
        if let body = body {
            request.httpBody = try? JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func requestWithoutResponse(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryParams: [String: String]? = nil
    ) async throws {
        var urlComponents = URLComponents(string: "\(config.baseURL)\(endpoint)")

        if let queryParams = queryParams {
            urlComponents?.queryItems = queryParams.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }

        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try? JSONEncoder().encode(body)
        }

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Conversations

    func getConversations(projectId: String? = nil, search: String? = nil) async throws
        -> [ConversationResponse]
    {
        var params: [String: String] = [:]
        if let projectId = projectId {
            params["projectId"] = projectId
        }
        if let search = search {
            params["search"] = search
        }
        return try await request(endpoint: "/api/db/conversations", queryParams: params)
    }

    func createConversation(title: String, projectId: String? = nil) async throws
        -> ConversationResponse
    {
        let request = CreateConversationRequest(
            action: "create", title: title, projectId: projectId)
        return try await self.request(
            endpoint: "/api/db/conversations", method: .post, body: request)
    }

    func branchConversation(conversationId: String, fromMessageId: String) async throws
        -> BranchConversationResponse
    {
        let request = BranchConversationRequest(
            action: "branch",
            conversationId: conversationId,
            fromMessageId: fromMessageId
        )
        return try await self.request(
            endpoint: "/api/db/conversations", method: .post, body: request)
    }

    func deleteConversation(id: String) async throws {
        try await requestWithoutResponse(
            endpoint: "/api/db/conversations?id=\(id)", method: .delete)
    }

    func setConversationProject(conversationId: String, projectId: String?) async throws {
        let request = SetConversationProjectRequest(
            action: "setProject",
            conversationId: conversationId,
            projectId: projectId
        )
        try await requestWithoutResponse(
            endpoint: "/api/db/conversations", method: .post, body: request)
    }

    func toggleConversationPin(conversationId: String) async throws -> TogglePinResponse {
        let request = ToggleConversationPinRequest(
            action: "togglePin",
            conversationId: conversationId
        )
        return try await self.request(
            endpoint: "/api/db/conversations", method: .post, body: request)
    }

    func updateConversationTitle(conversationId: String, title: String) async throws {
        let request = UpdateConversationTitleRequest(
            action: "updateTitle",
            conversationId: conversationId,
            title: title
        )
        try await requestWithoutResponse(
            endpoint: "/api/db/conversations", method: .post, body: request)
    }

    // MARK: - Messages

    func getMessages(conversationId: String) async throws -> [MessageResponse] {
        return try await request(endpoint: "/api/db/messages?conversationId=\(conversationId)")
    }

    func getStarredMessages() async throws -> [MessageResponse] {
        return try await request(endpoint: "/api/starred-messages")
    }

    func createMessage(
        conversationId: String,
        role: String,
        content: String,
        contentHtml: String? = nil
    ) async throws -> MessageResponse {
        let request = CreateMessageRequest(
            action: "create",
            conversationId: conversationId,
            role: role,
            content: content,
            contentHtml: contentHtml ?? content
        )
        return try await self.request(endpoint: "/api/db/messages", method: .post, body: request)
    }

    func updateMessageContent(
        messageId: String,
        content: String,
        contentHtml: String? = nil,
        reasoning: String? = nil
    ) async throws -> [String: Bool] {
        let request = UpdateMessageContentRequest(
            action: "updateContent",
            messageId: messageId,
            content: content,
            contentHtml: contentHtml,
            reasoning: reasoning
        )
        return try await self.request(endpoint: "/api/db/messages", method: .post, body: request)
    }

    func setMessageStarred(messageId: String, starred: Bool) async throws -> [String: Bool] {
        let request = SetMessageStarredRequest(
            action: "setStarred",
            messageId: messageId,
            starred: starred
        )
        return try await self.request(endpoint: "/api/db/messages", method: .post, body: request)
    }

    func rateMessage(messageId: String, thumbs: MessageThumbsRating?) async throws -> MessageRatingResponse {
        let request = MessageRatingRequest(
            messageId: messageId,
            thumbs: thumbs?.rawValue
        )
        return try await self.request(endpoint: "/api/db/message-ratings", method: .post, body: request)
    }

    // MARK: - Follow-Up Questions

    func generateFollowUpQuestions(conversationId: String, messageId: String) async throws
        -> [String]
    {
        let request = GenerateFollowUpQuestionsRequest(
            conversationId: conversationId,
            messageId: messageId
        )
        let response: GenerateFollowUpQuestionsResponse = try await self.request(
            endpoint: "/api/generate-follow-up-questions",
            method: .post,
            body: request
        )
        return response.suggestions
    }

    // MARK: - Generate Message

    func generateMessage(
        message: String,
        modelId: String,
        conversationId: String? = nil,
        assistantId: String? = nil,
        projectId: String? = nil,
        webSearchEnabled: Bool = false,
        webSearchMode: String? = nil,
        webSearchProvider: String? = nil,
        providerId: String? = nil,
        images: [ImageAttachment]? = nil,
        documents: [DocumentAttachment]? = nil,
        imageParams: [String: AnyCodable]? = nil,
        videoParams: [String: AnyCodable]? = nil
    ) async throws -> GenerateMessageResponse {
        let request = GenerateMessageRequest(
            message: message,
            model_id: modelId,
            conversation_id: conversationId,
            assistant_id: assistantId,
            project_id: projectId,
            web_search_enabled: webSearchEnabled,
            web_search_mode: webSearchMode,
            web_search_provider: webSearchProvider,
            provider_id: providerId,
            images: images,
            documents: documents,
            image_params: imageParams,
            video_params: videoParams
        )
        return try await self.request(
            endpoint: "/api/generate-message", method: .post, body: request)
    }

    // MARK: - Audio

    func textToSpeech(text: String, model: String, voice: String, speed: Double) async throws
        -> TTSResult
    {
        guard let url = URL(string: "\(config.baseURL)/api/tts") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let payload = TTSRequest(text: text, model: model, voice: voice, speed: speed)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 202 {
            let ticket = try JSONDecoder().decode(TTSPendingTicket.self, from: data)
            if let audioUrl = ticket.audioUrl, let url = URL(string: audioUrl) {
                return .audioUrl(url)
            }
            return .pending(ticket)
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        if httpResponse.value(forHTTPHeaderField: "Content-Type")?.contains("application/json")
            == true
        {
            let ticket = try JSONDecoder().decode(TTSPendingTicket.self, from: data)
            if let audioUrl = ticket.audioUrl, let url = URL(string: audioUrl) {
                return .audioUrl(url)
            }
            return .pending(ticket)
        }

        return .audioData(data)
    }

    func fetchTTSStatus(ticket: TTSPendingTicket) async throws -> TTSStatusResponse {
        guard let runId = ticket.runId, let model = ticket.model else {
            throw APIError.invalidResponse
        }

        var params: [String: String] = [
            "runId": runId,
            "model": model,
        ]

        if let cost = ticket.cost {
            params["cost"] = String(cost)
        }
        if let paymentSource = ticket.paymentSource {
            params["paymentSource"] = paymentSource
        }
        if let isApiRequest = ticket.isApiRequest {
            params["isApiRequest"] = String(isApiRequest)
        }

        return try await request(endpoint: "/api/tts/status", queryParams: params)
    }

    func fetchAudioData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        return data
    }

    func downloadStorageData(storageId: String) async throws -> Data {
        guard let url = URL(string: "\(config.baseURL)/api/storage/\(storageId)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        return data
    }

    func transcribeAudio(fileURL: URL, model: String, language: String) async throws
        -> SpeechToTextResponse
    {
        guard let url = URL(string: "\(config.baseURL)/api/stt") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue(config.baseURL, forHTTPHeaderField: "Origin")
        request.setValue(config.baseURL, forHTTPHeaderField: "Referer")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        request.httpBody = try buildTranscriptionBody(
            fileURL: fileURL,
            model: model,
            language: language,
            boundary: boundary
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            let fallbackMessage =
                String(data: data, encoding: .utf8)
                ?? "HTTP error: \(httpResponse.statusCode)"
            let errorMessage: String
            if let decoded = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                errorMessage =
                    decoded.error ?? decoded.details ?? decoded.message ?? fallbackMessage
            } else {
                errorMessage = fallbackMessage
            }
            throw NSError(
                domain: "NanoChatAPI",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }

        return try JSONDecoder().decode(SpeechToTextResponse.self, from: data)
    }

    private func buildTranscriptionBody(
        fileURL: URL,
        model: String,
        language: String,
        boundary: String
    ) throws -> Data {
        var body = Data()

        let filename = fileURL.lastPathComponent
        let mimeType = transcriptionMimeType(for: fileURL)
        let fileData = try Data(contentsOf: fileURL)

        body.appendString("--\(boundary)\r\n")
        body.appendString(
            "Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.appendString("\r\n")

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.appendString("\(model)\r\n")

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
        body.appendString("\(language)\r\n")

        body.appendString("--\(boundary)--\r\n")
        return body
    }

    private func transcriptionMimeType(for fileURL: URL) -> String {
        switch fileURL.pathExtension.lowercased() {
        case "m4a", "mp4", "m4v":
            return "audio/mp4"
        case "wav":
            return "audio/wav"
        case "mp3":
            return "audio/mpeg"
        case "ogg", "oga":
            return "audio/ogg"
        case "aac":
            return "audio/aac"
        default:
            return "application/octet-stream"
        }
    }

    private func projectFileMimeType(for fileURL: URL) -> String? {
        switch fileURL.pathExtension.lowercased() {
        case "pdf":
            return "application/pdf"
        case "md", "markdown":
            return "text/markdown"
        case "txt":
            return "text/plain"
        case "epub":
            return "application/epub+zip"
        default:
            return nil
        }
    }

    // MARK: - Assistants

    func getAssistants() async throws -> [AssistantResponse] {
        return try await request(endpoint: "/api/assistants")
    }

    func createAssistant(
        name: String,
        systemPrompt: String,
        defaultModelId: String? = nil,
        defaultWebSearchMode: String? = nil
    ) async throws -> AssistantResponse {
        let request = CreateAssistantRequest(
            name: name,
            systemPrompt: systemPrompt,
            defaultModelId: defaultModelId,
            defaultWebSearchMode: defaultWebSearchMode,
            defaultWebSearchProvider: nil
        )
        return try await self.request(endpoint: "/api/assistants", method: .post, body: request)
    }

    // MARK: - User Models

    func getUserModels() async throws -> [UserModel] {
        // Use the new endpoint that includes capabilities
        let urlComponents = URLComponents(string: "\(config.baseURL)/api/models")
        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Decode as array directly from the new endpoint
        let models = try JSONDecoder().decode([NanoGPTModelResponse].self, from: data)

        // Convert to UserModel format
        return models.map { model in
            UserModel(
                modelId: model.id,
                provider: "nanogpt",
                enabled: model.enabled,
                pinned: model.pinned,
                name: model.name,
                description: model.description,
                capabilities: model.capabilities,
                costEstimate: model.pricing?.prompt.flatMap { Double($0) },
                subscriptionIncluded: model.subscription?.included,
                resolutions: model.resolutions,
                additionalParams: {
                    guard let rawParams = model.additionalParams else { return nil }
                    var cleanParams: [String: ModelParamDefinition] = [:]

                    for (key, value) in rawParams {
                        // Skip if the value is a boolean (like requiresSwapImage)
                        if value.value is Bool { continue }

                        // Try to convert dictionary to ModelParamDefinition
                        if let dict = value.value as? [String: Any] {
                            do {
                                let jsonData = try JSONSerialization.data(withJSONObject: dict)
                                let paramDef = try JSONDecoder().decode(
                                    ModelParamDefinition.self, from: jsonData)
                                cleanParams[key] = paramDef
                            } catch {
                                // Failed to decode param
                            }
                        }
                    }
                    return cleanParams.isEmpty ? nil : cleanParams
                }(),
                maxImages: model.maxImages,
                defaultSettings: model.defaultSettings
            )
        }
    }

    func fetchModelProviders(modelId: String) async throws -> ModelProvidersResponse {
        return try await request(
            endpoint: "/api/model-providers", queryParams: ["modelId": modelId])
    }

    func fetchModelInfo(modelId: String) async throws -> ModelInfoResponse {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        guard let encodedId = modelId.addingPercentEncoding(withAllowedCharacters: allowed) else {
            throw APIError.invalidURL
        }
        return try await request(endpoint: "/api/models/\(encodedId)/info")
    }

    // Helper struct for decoding the raw API response
    private struct UserModelRaw: Codable {
        let id: String
        let modelId: String
        let provider: String
        let enabled: Bool?
        let pinned: Bool?
        let pinnedInt: Int?
        let userId: String
        let createdAt: Date
        let updatedAt: Date
        let name: String?
        let description: String?
        let capabilities: ModelCapabilities?
        let costEstimate: Double?

        enum CodingKeys: String, CodingKey {
            case id, modelId, provider, enabled, pinned, userId, name, description, capabilities,
                costEstimate
            case createdAt, updatedAt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            modelId = try container.decode(String.self, forKey: .modelId)
            provider = try container.decode(String.self, forKey: .provider)
            enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)

            // Try decoding pinned as both Int and Bool
            if let pinnedBool = try? container.decode(Bool.self, forKey: .pinned) {
                pinned = pinnedBool
                pinnedInt = nil
            } else if let pinnedIntValue = try? container.decode(Int.self, forKey: .pinned) {
                pinned = pinnedIntValue == 1
                pinnedInt = pinnedIntValue
            } else {
                pinned = nil
                pinnedInt = nil
            }

            userId = try container.decode(String.self, forKey: .userId)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            capabilities = try container.decodeIfPresent(
                ModelCapabilities.self, forKey: .capabilities)
            costEstimate = try container.decodeIfPresent(Double.self, forKey: .costEstimate)

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
    }

    // MARK: - Storage / File Upload

    struct StorageUploadResponse: Codable {
        let storageId: String
        let url: String
    }

    /// Uploads a file to the storage API
    /// - Parameters:
    ///   - data: The file data to upload
    ///   - filename: The original filename
    ///   - mimeType: The MIME type of the file (e.g., "image/jpeg", "application/pdf")
    /// - Returns: The storage response containing storageId and url
    func uploadFile(data: Data, filename: String, mimeType: String) async throws
        -> StorageUploadResponse
    {
        guard let url = URL(string: "\(config.baseURL)/api/storage") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        request.setValue(filename, forHTTPHeaderField: "x-filename")

        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = data

        let (responseData, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(StorageUploadResponse.self, from: responseData)
            return decoded
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Uploads an image and returns the storage info for use in generate-message
    func uploadImage(data: Data, filename: String? = nil) async throws -> ImageAttachment {
        // Detect image type from data
        let mimeType = detectImageMimeType(from: data) ?? "image/jpeg"
        let ext = mimeType == "image/png" ? "png" : (mimeType == "image/gif" ? "gif" : "jpg")
        let finalFilename = filename ?? "image-\(Int(Date().timeIntervalSince1970)).\(ext)"

        let response = try await uploadFile(data: data, filename: finalFilename, mimeType: mimeType)

        return ImageAttachment(
            url: response.url,
            storageId: response.storageId,
            fileName: finalFilename
        )
    }

    /// Uploads a document and returns the storage info for use in generate-message
    func uploadDocument(url: URL) async throws -> DocumentAttachment {
        // Start accessing security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let filename = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()

        let mimeType: String
        let fileType: DocumentFileType

        switch fileExtension {
        case "pdf":
            mimeType = "application/pdf"
            fileType = .pdf
        case "md", "markdown":
            mimeType = "text/markdown"
            fileType = .markdown
        case "txt":
            mimeType = "text/plain"
            fileType = .text
        case "epub":
            mimeType = "application/epub+zip"
            fileType = .epub
        default:
            mimeType = "text/plain"
            fileType = .text
        }

        let response = try await uploadFile(data: data, filename: filename, mimeType: mimeType)

        return DocumentAttachment(
            url: response.url,
            storageId: response.storageId,
            fileName: filename,
            fileType: fileType
        )
    }

    private func detectImageMimeType(from data: Data) -> String? {
        guard data.count >= 8 else { return nil }

        let bytes = [UInt8](data.prefix(8))

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return "image/png"
        }

        // JPEG: FF D8 FF
        if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return "image/jpeg"
        }

        // GIF: 47 49 46 38
        if bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38 {
            return "image/gif"
        }

        // WebP: RIFF....WEBP
        if bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 {
            return "image/webp"
        }

        // HEIC/HEIF: Check for ftyp box
        if data.count >= 12 {
            let ftypBytes = [UInt8](data[4..<8])
            if ftypBytes[0] == 0x66 && ftypBytes[1] == 0x74 && ftypBytes[2] == 0x79
                && ftypBytes[3] == 0x70
            {
                return "image/heic"
            }
        }

        return nil
    }

    // MARK: - Projects

    func getProjects() async throws -> [ProjectResponse] {
        return try await request(endpoint: "/api/projects")
    }

    func createProject(
        name: String,
        description: String? = nil,
        systemPrompt: String? = nil,
        color: String? = nil
    ) async throws -> ProjectResponse {
        let request = CreateProjectRequest(
            name: name,
            description: description,
            systemPrompt: systemPrompt,
            color: color
        )
        return try await self.request(endpoint: "/api/projects", method: .post, body: request)
    }

    func getProjectMembers(projectId: String) async throws -> [ProjectMemberResponse] {
        return try await request(endpoint: "/api/projects/\(projectId)/members")
    }

    func addProjectMember(
        projectId: String,
        email: String,
        role: String
    ) async throws -> ProjectMemberResponse {
        let request = AddProjectMemberRequest(email: email, role: role)
        return try await self.request(
            endpoint: "/api/projects/\(projectId)/members", method: .post, body: request)
    }

    func removeProjectMember(projectId: String, userId: String) async throws {
        try await requestWithoutResponse(
            endpoint: "/api/projects/\(projectId)/members",
            method: .delete,
            queryParams: ["userId": userId]
        )
    }

    func getProjectFiles(projectId: String) async throws -> [ProjectFileResponse] {
        return try await request(endpoint: "/api/projects/\(projectId)/files")
    }

    func uploadProjectFile(projectId: String, fileURL: URL) async throws -> ProjectFileResponse {
        guard let url = URL(string: "\(config.baseURL)/api/projects/\(projectId)/files") else {
            throw APIError.invalidURL
        }

        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let filename = fileURL.lastPathComponent
        guard let mimeType = projectFileMimeType(for: fileURL) else {
            throw NSError(
                domain: "NanoChatAPI",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Unsupported file type"]
            )
        }

        let fileData = try Data(contentsOf: fileURL)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString(
            "Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            let fallbackMessage =
                String(data: data, encoding: .utf8)
                ?? "HTTP error: \(httpResponse.statusCode)"
            let errorMessage: String
            if let decoded = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                errorMessage =
                    decoded.error ?? decoded.details ?? decoded.message ?? fallbackMessage
            } else {
                errorMessage = fallbackMessage
            }
            throw NSError(
                domain: "NanoChatAPI",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }

        return try JSONDecoder().decode(ProjectFileResponse.self, from: data)
    }

    func deleteProjectFile(projectId: String, fileId: String) async throws {
        try await requestWithoutResponse(
            endpoint: "/api/projects/\(projectId)/files",
            method: .delete,
            queryParams: ["fileId": fileId]
        )
    }

    func updateProject(
        id: String,
        name: String,
        description: String? = nil,
        systemPrompt: String? = nil,
        color: String? = nil
    ) async throws -> ProjectResponse {
        let request = UpdateProjectRequest(
            name: name,
            description: description,
            systemPrompt: systemPrompt,
            color: color
        )
        return try await self.request(
            endpoint: "/api/projects/\(id)", method: .patch, body: request)
    }

    func deleteProject(id: String) async throws {
        try await requestWithoutResponse(
            endpoint: "/api/projects/\(id)", method: .delete)
    }

    // MARK: - Analytics

    func getAnalytics(recalculate: Bool = true) async throws -> AnalyticsResponse {
        let params = ["recalculate": recalculate ? "true" : "false"]
        return try await request(endpoint: "/api/analytics", queryParams: params)
    }

    // MARK: - User Settings

    func getUserSettings() async throws -> UserSettings {
        let urlComponents = URLComponents(string: "\(config.baseURL)/api/db/user-settings")
        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(UserSettings.self, from: data)
            return decoded
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func updateUserSettings(
        privacyMode: Bool? = nil,
        contextMemoryEnabled: Bool? = nil,
        persistentMemoryEnabled: Bool? = nil,
        youtubeTranscriptsEnabled: Bool? = nil,
        webScrapingEnabled: Bool? = nil,
        mcpEnabled: Bool? = nil,
        followUpQuestionsEnabled: Bool? = nil,
        karakeepUrl: String? = nil,
        karakeepApiKey: String? = nil,
        theme: String? = nil,
        titleModelId: String? = nil,
        followUpModelId: String? = nil
    ) async throws -> UserSettings {
        let request = UpdateUserSettingsRequest(
            action: "update",
            privacyMode: privacyMode,
            contextMemoryEnabled: contextMemoryEnabled,
            persistentMemoryEnabled: persistentMemoryEnabled,
            youtubeTranscriptsEnabled: youtubeTranscriptsEnabled,
            webScrapingEnabled: webScrapingEnabled,
            mcpEnabled: mcpEnabled,
            followUpQuestionsEnabled: followUpQuestionsEnabled,
            karakeepUrl: karakeepUrl,
            karakeepApiKey: karakeepApiKey,
            theme: theme,
            titleModelId: titleModelId,
            followUpModelId: followUpModelId
        )
        return try await self.request(
            endpoint: "/api/db/user-settings", method: .post, body: request)
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case encodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        }
    }
}

enum TTSResult {
    case audioData(Data)
    case audioUrl(URL)
    case pending(TTSPendingTicket)
}

struct TTSRequest: Codable {
    let text: String
    let model: String
    let voice: String
    let speed: Double
}

struct TTSPendingTicket: Codable {
    let status: String?
    let runId: String?
    let model: String?
    let cost: Double?
    let paymentSource: String?
    let isApiRequest: Bool?
    let audioUrl: String?
    let contentType: String?
    let error: String?
}

struct TTSStatusResponse: Codable {
    let status: String
    let audioUrl: String?
    let contentType: String?
    let model: String?
    let error: String?
}

struct APIErrorResponse: Codable {
    let error: String?
    let details: String?
    let message: String?
}

struct SpeechToTextResponse: Codable {
    let transcription: String?
    let text: String?
    let metadata: SpeechToTextMetadata?
}

struct SpeechToTextMetadata: Codable {
    let cost: Double?
    let chargedDuration: Double?
}

extension Data {
    fileprivate mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

struct GenerateMessageResponse: Codable {
    let ok: Bool
    let conversationId: String

    enum CodingKeys: String, CodingKey {
        case ok
        case conversationId = "conversation_id"
    }
}

struct CreateMessageRequest: Codable {
    let action: String
    let conversationId: String
    let role: String
    let content: String
    let contentHtml: String
}

struct UpdateMessageContentRequest: Codable {
    let action: String
    let messageId: String
    let content: String
    let contentHtml: String?
    let reasoning: String?

    enum CodingKeys: String, CodingKey {
        case action
        case messageId = "messageId"
        case content
        case contentHtml
        case reasoning
    }
}

struct SetMessageStarredRequest: Codable {
    let action: String
    let messageId: String
    let starred: Bool

    enum CodingKeys: String, CodingKey {
        case action
        case messageId = "messageId"
        case starred
    }
}

struct GenerateMessageRequest: Codable {
    let message: String
    let model_id: String
    let conversation_id: String?
    let assistant_id: String?
    let project_id: String?
    let web_search_enabled: Bool
    let web_search_mode: String?
    let web_search_provider: String?
    let provider_id: String?
    let images: [ImageAttachment]?
    let documents: [DocumentAttachment]?
    let image_params: [String: AnyCodable]?
    let video_params: [String: AnyCodable]?
}

struct BranchConversationRequest: Codable {
    let action: String
    let conversationId: String
    let fromMessageId: String
}

struct BranchConversationResponse: Codable {
    let conversationId: String

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversationId"
    }
}

struct ToggleConversationPinRequest: Codable {
    let action: String
    let conversationId: String
}

struct TogglePinResponse: Codable {
    let pinned: Bool
}

struct UpdateConversationTitleRequest: Codable {
    let action: String
    let conversationId: String
    let title: String
}

// MARK: - Attachment Types

struct ImageAttachment: Codable {
    let url: String
    let storageId: String
    let fileName: String?

    enum CodingKeys: String, CodingKey {
        case url
        case storageId = "storage_id"
        case fileName
    }
}

struct DocumentAttachment: Codable {
    let url: String
    let storageId: String
    let fileName: String?
    let fileType: DocumentFileType

    enum CodingKeys: String, CodingKey {
        case url
        case storageId = "storage_id"
        case fileName
        case fileType
    }
}

enum DocumentFileType: String, Codable {
    case pdf
    case markdown
    case text
    case epub
}

// MARK: - Message Rating Types

enum MessageThumbsRating: String, Codable {
    case up
    case down
}

struct MessageRatingRequest: Codable {
    let messageId: String
    let thumbs: String?
}

struct MessageRatingResponse: Codable {
    let success: Bool
}

// MARK: - NanoGPT Model Types

struct NanoGPTModelResponse: Codable {
    let id: String
    let name: String
    let description: String
    let enabled: Bool
    let pinned: Bool
    let capabilities: ModelCapabilities?
    let pricing: NanoGPTPricing?
    let subscription: NanoGPTSubscription?
    let resolutions: [ModelResolution]?
    let additionalParams: [String: AnyCodable]?
    let maxImages: Int?
    let defaultSettings: ModelDefaultSettings?
}

struct NanoGPTPricing: Codable {
    let prompt: String?
    let completion: String?
    let image: String?
    let request: String?
}

struct NanoGPTSubscription: Codable {
    let included: Bool
    let note: String
}

// MARK: - User Settings Types

struct UpdateUserSettingsRequest: Codable {
    let action: String
    let privacyMode: Bool?
    let contextMemoryEnabled: Bool?
    let persistentMemoryEnabled: Bool?
    let youtubeTranscriptsEnabled: Bool?
    let webScrapingEnabled: Bool?
    let mcpEnabled: Bool?
    let followUpQuestionsEnabled: Bool?
    let karakeepUrl: String?
    let karakeepApiKey: String?
    let theme: String?
    let titleModelId: String?
    let followUpModelId: String?

    enum CodingKeys: String, CodingKey {
        case action
        case privacyMode = "privacyMode"
        case contextMemoryEnabled = "contextMemoryEnabled"
        case persistentMemoryEnabled = "persistentMemoryEnabled"
        case youtubeTranscriptsEnabled = "youtubeTranscriptsEnabled"
        case webScrapingEnabled = "webScrapingEnabled"
        case mcpEnabled = "mcpEnabled"
        case followUpQuestionsEnabled = "followUpQuestionsEnabled"
        case karakeepUrl = "karakeepUrl"
        case karakeepApiKey = "karakeepApiKey"
        case theme
        case titleModelId = "titleModelId"
        case followUpModelId = "followUpModelId"
    }

    init(
        action: String,
        privacyMode: Bool? = nil,
        contextMemoryEnabled: Bool? = nil,
        persistentMemoryEnabled: Bool? = nil,
        youtubeTranscriptsEnabled: Bool? = nil,
        webScrapingEnabled: Bool? = nil,
        mcpEnabled: Bool? = nil,
        followUpQuestionsEnabled: Bool? = nil,
        karakeepUrl: String? = nil,
        karakeepApiKey: String? = nil,
        theme: String? = nil,
        titleModelId: String? = nil,
        followUpModelId: String? = nil
    ) {
        self.action = action
        self.privacyMode = privacyMode
        self.contextMemoryEnabled = contextMemoryEnabled
        self.persistentMemoryEnabled = persistentMemoryEnabled
        self.youtubeTranscriptsEnabled = youtubeTranscriptsEnabled
        self.webScrapingEnabled = webScrapingEnabled
        self.mcpEnabled = mcpEnabled
        self.followUpQuestionsEnabled = followUpQuestionsEnabled
        self.karakeepUrl = karakeepUrl
        self.karakeepApiKey = karakeepApiKey
        self.theme = theme
        self.titleModelId = titleModelId
        self.followUpModelId = followUpModelId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)

        // Only include non-nil values
        if let privacyMode = privacyMode {
            try container.encode(privacyMode, forKey: .privacyMode)
        }
        if let contextMemoryEnabled = contextMemoryEnabled {
            try container.encode(contextMemoryEnabled, forKey: .contextMemoryEnabled)
        }
        if let persistentMemoryEnabled = persistentMemoryEnabled {
            try container.encode(persistentMemoryEnabled, forKey: .persistentMemoryEnabled)
        }
        if let youtubeTranscriptsEnabled = youtubeTranscriptsEnabled {
            try container.encode(youtubeTranscriptsEnabled, forKey: .youtubeTranscriptsEnabled)
        }
        if let webScrapingEnabled = webScrapingEnabled {
            try container.encode(webScrapingEnabled, forKey: .webScrapingEnabled)
        }
        if let mcpEnabled = mcpEnabled {
            try container.encode(mcpEnabled, forKey: .mcpEnabled)
        }
        if let followUpQuestionsEnabled = followUpQuestionsEnabled {
            try container.encode(followUpQuestionsEnabled, forKey: .followUpQuestionsEnabled)
        }
        if let karakeepUrl = karakeepUrl {
            try container.encode(karakeepUrl, forKey: .karakeepUrl)
        }
        if let karakeepApiKey = karakeepApiKey {
            try container.encode(karakeepApiKey, forKey: .karakeepApiKey)
        }
        if let theme = theme {
            try container.encode(theme, forKey: .theme)
        }
        if let titleModelId = titleModelId {
            try container.encode(titleModelId, forKey: .titleModelId)
        }
        if let followUpModelId = followUpModelId {
            try container.encode(followUpModelId, forKey: .followUpModelId)
        }
    }
}

// MARK: - Follow-Up Questions Types

struct GenerateFollowUpQuestionsRequest: Codable {
    let conversationId: String
    let messageId: String
}

struct GenerateFollowUpQuestionsResponse: Codable {
    let ok: Bool
    let suggestions: [String]
}
