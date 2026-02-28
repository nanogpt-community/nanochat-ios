import Foundation
import SwiftUI

final class NanoChatAPI: Sendable {
    static let shared = NanoChatAPI()
    private let config = APIConfiguration.shared
    private let session: URLSession
    private let streamingSession: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)

        // Dedicated session for SSE streaming with longer timeouts
        let streamingConfig = URLSessionConfiguration.default
        streamingConfig.timeoutIntervalForRequest = 300
        streamingConfig.timeoutIntervalForResource = 600
        streamingConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.streamingSession = URLSession(configuration: streamingConfig)
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

    func getConversations(projectId: String? = nil) async throws -> [ConversationResponse] {
        var params: [String: String] = [:]
        if let projectId = projectId {
            params["projectId"] = projectId
        }
        return try await request(endpoint: "/api/db/conversations", queryParams: params)
    }

    func searchConversations(search: String, mode: ConversationSearchMode = .fuzzy) async throws
        -> [ConversationSearchResult]
    {
        return try await request(
            endpoint: "/api/db/conversations",
            queryParams: [
                "search": search,
                "mode": mode.rawValue,
            ]
        )
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

    func setConversationPublic(conversationId: String, isPublic: Bool) async throws {
        let request = SetConversationPublicRequest(
            action: "setPublic",
            conversationId: conversationId,
            isPublic: isPublic
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

    func deleteMessage(messageId: String) async throws -> [String: Bool] {
        let request = DeleteMessageRequest(
            action: "delete",
            messageId: messageId
        )
        return try await self.request(endpoint: "/api/db/messages", method: .post, body: request)
    }

    func rateMessage(messageId: String, thumbs: MessageThumbsRating?) async throws
        -> MessageRatingResponse
    {
        let request = MessageRatingRequest(
            messageId: messageId,
            thumbs: thumbs?.rawValue
        )
        return try await self.request(
            endpoint: "/api/db/message-ratings", method: .post, body: request)
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
        webSearchExaDepth: String? = nil,
        webSearchContextSize: String? = nil,
        webSearchKagiSource: String? = nil,
        webSearchValyuSearchType: String? = nil,
        providerId: String? = nil,
        images: [ImageAttachment]? = nil,
        documents: [DocumentAttachment]? = nil,
        imageParams: [String: AnyCodable]? = nil,
        videoParams: [String: AnyCodable]? = nil,
        temporary: Bool? = nil
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
            web_search_exa_depth: webSearchExaDepth,
            web_search_context_size: webSearchContextSize,
            web_search_kagi_source: webSearchKagiSource,
            web_search_valyu_search_type: webSearchValyuSearchType,
            provider_id: providerId,
            images: images,
            documents: documents,
            image_params: imageParams,
            video_params: videoParams,
            temporary: temporary
        )
        return try await self.request(
            endpoint: "/api/generate-message", method: .post, body: request)
    }

    // MARK: - SSE Streaming

    /// Generates a message using SSE streaming for real-time token delivery
    /// - Returns: An AsyncThrowingStream of SSEEvent that yields events as they arrive
    func generateMessageStream(
        message: String?,
        modelId: String,
        conversationId: String? = nil,
        assistantId: String? = nil,
        projectId: String? = nil,
        webSearchEnabled: Bool = false,
        webSearchMode: String? = nil,
        webSearchProvider: String? = nil,
        webSearchExaDepth: String? = nil,
        webSearchContextSize: String? = nil,
        webSearchKagiSource: String? = nil,
        webSearchValyuSearchType: String? = nil,
        providerId: String? = nil,
        documents: [DocumentAttachment]? = nil,
        reasoningEffort: String? = nil,
        temporary: Bool? = nil
    ) -> AsyncThrowingStream<SSEEvent, Error> {
        let baseURL = config.baseURL
        let apiKey = config.apiKey
        let streamSession = streamingSession

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let url = URL(string: "\(baseURL)/api/generate-message/stream")
                    else {
                        continuation.finish(throwing: APIError.invalidURL)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

                    if let apiKey = apiKey {
                        request.setValue(
                            "Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    }

                    let payload = GenerateMessageStreamRequest(
                        message: message,
                        model_id: modelId,
                        conversation_id: conversationId,
                        assistant_id: assistantId,
                        project_id: projectId,
                        web_search_enabled: webSearchEnabled,
                        web_search_mode: webSearchMode,
                        web_search_provider: webSearchProvider,
                        web_search_exa_depth: webSearchExaDepth,
                        web_search_context_size: webSearchContextSize,
                        web_search_kagi_source: webSearchKagiSource,
                        web_search_valyu_search_type: webSearchValyuSearchType,
                        provider_id: providerId,
                        documents: documents,
                        reasoning_effort: reasoningEffort,
                        temporary: temporary
                    )
                    request.httpBody = try JSONEncoder().encode(payload)

                    // Use streaming session for SSE with raw bytes
                    let (bytes, response) = try await streamSession.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }

                    guard 200...299 ~= httpResponse.statusCode else {
                        continuation.finish(
                            throwing: APIError.httpError(statusCode: httpResponse.statusCode))
                        return
                    }

                    // Parse SSE events from raw bytes
                    var buffer = Data()

                    for try await byte in bytes {
                        // Check for cancellation
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }

                        buffer.append(byte)

                        // Check if we have a complete event (ends with double newline)
                        if buffer.count >= 2 {
                            // Look for \n\n which marks end of an SSE event
                            if let bufferString = String(data: buffer, encoding: .utf8),
                                bufferString.hasSuffix("\n\n")
                            {
                                // Parse the event
                                let eventString = bufferString.trimmingCharacters(
                                    in: .whitespacesAndNewlines)
                                if let event = parseSSEEventFromString(eventString) {
                                    continuation.yield(event)

                                    // If it's an error or complete event, we're done
                                    if case .error = event {
                                        continuation.finish()
                                        return
                                    }
                                    if case .messageComplete = event {
                                        continuation.finish()
                                        return
                                    }
                                }
                                // Clear buffer for next event
                                buffer = Data()
                            }
                        }
                    }

                    // Process any remaining buffer
                    if !buffer.isEmpty,
                        let bufferString = String(data: buffer, encoding: .utf8)
                    {
                        let eventString = bufferString.trimmingCharacters(
                            in: .whitespacesAndNewlines)
                        if !eventString.isEmpty, let event = parseSSEEventFromString(eventString) {
                            continuation.yield(event)
                        }
                    }

                    continuation.finish()
                } catch {
                    if !Task.isCancelled {
                        continuation.finish(throwing: error)
                    } else {
                        continuation.finish()
                    }
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Parse a complete SSE event string into an SSEEvent
    private func parseSSEEventFromString(_ eventString: String) -> SSEEvent? {
        let lines = eventString.components(separatedBy: "\n")
        var eventType: String?
        var dataLines: [String] = []

        for line in lines {
            if line.hasPrefix("event:") {
                eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                dataLines.append(String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces))
            }
        }

        guard let type = eventType, !dataLines.isEmpty else {
            return nil
        }

        let data = dataLines.joined(separator: "\n")
        return parseSSEEvent(type: type, data: data)
    }

    private func parseSSEEvent(type: String, data: String) -> SSEEvent? {
        guard let jsonData = data.data(using: .utf8) else {
            return nil
        }

        switch type {
        case "message_start":
            if let decoded = try? JSONDecoder().decode(SSEMessageStartData.self, from: jsonData) {
                return .messageStart(
                    conversationId: decoded.conversationId, messageId: decoded.messageId)
            }
            return nil

        case "delta":
            if let decoded = try? JSONDecoder().decode(SSEDeltaData.self, from: jsonData) {
                return .delta(content: decoded.content, reasoning: decoded.reasoning)
            }
            return nil

        case "message_complete":
            if let decoded = try? JSONDecoder().decode(SSEMessageCompleteData.self, from: jsonData)
            {
                return .messageComplete(
                    tokenCount: decoded.tokenCount,
                    costUsd: decoded.costUsd,
                    responseTimeMs: decoded.responseTimeMs
                )
            }
            return nil

        case "error":
            if let decoded = try? JSONDecoder().decode(SSEErrorData.self, from: jsonData) {
                return .error(message: decoded.error)
            }
            return nil

        default:
            return nil
        }
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

    func downloadData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if shouldAttachAuthorizationHeader(to: url), let apiKey = config.apiKey {
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

    func downloadStorageData(storageId: String) async throws -> Data {
        guard let url = URL(string: "\(config.baseURL)/api/storage/\(storageId)") else {
            throw APIError.invalidURL
        }

        return try await downloadData(from: url)
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
        defaultWebSearchMode: String? = nil,
        defaultWebSearchProvider: String? = nil,
        defaultWebSearchExaDepth: String? = nil,
        defaultWebSearchContextSize: String? = nil,
        defaultWebSearchKagiSource: String? = nil,
        defaultWebSearchValyuSearchType: String? = nil
    ) async throws -> AssistantResponse {
        let request = CreateAssistantRequest(
            name: name,
            systemPrompt: systemPrompt,
            defaultModelId: defaultModelId,
            defaultWebSearchMode: defaultWebSearchMode,
            defaultWebSearchProvider: defaultWebSearchProvider,
            defaultWebSearchExaDepth: defaultWebSearchExaDepth,
            defaultWebSearchContextSize: defaultWebSearchContextSize,
            defaultWebSearchKagiSource: defaultWebSearchKagiSource,
            defaultWebSearchValyuSearchType: defaultWebSearchValyuSearchType
        )
        return try await self.request(endpoint: "/api/assistants", method: .post, body: request)
    }

    func updateAssistant(
        id: String,
        name: String? = nil,
        systemPrompt: String? = nil,
        defaultModelId: String? = nil,
        defaultWebSearchMode: String? = nil,
        defaultWebSearchProvider: String? = nil,
        defaultWebSearchExaDepth: String? = nil,
        defaultWebSearchContextSize: String? = nil,
        defaultWebSearchKagiSource: String? = nil,
        defaultWebSearchValyuSearchType: String? = nil
    ) async throws {
        let request = UpdateAssistantRequest(
            name: name,
            systemPrompt: systemPrompt,
            defaultModelId: defaultModelId,
            defaultWebSearchMode: defaultWebSearchMode,
            defaultWebSearchProvider: defaultWebSearchProvider,
            defaultWebSearchExaDepth: defaultWebSearchExaDepth,
            defaultWebSearchContextSize: defaultWebSearchContextSize,
            defaultWebSearchKagiSource: defaultWebSearchKagiSource,
            defaultWebSearchValyuSearchType: defaultWebSearchValyuSearchType
        )
        try await requestWithoutResponse(
            endpoint: "/api/assistants/\(id)", method: .patch, body: request)
    }

    func deleteAssistant(id: String) async throws {
        try await requestWithoutResponse(
            endpoint: "/api/assistants/\(id)", method: .delete)
    }

    func setDefaultAssistant(id: String) async throws {
        let request = AssistantSetDefaultRequest(action: "setDefault")
        try await requestWithoutResponse(
            endpoint: "/api/assistants/\(id)", method: .post, body: request)
    }

    // MARK: - Prompt Templates

    func getPrompts() async throws -> [PromptTemplate] {
        return try await request(endpoint: "/api/prompts")
    }

    func createPrompt(_ request: CreatePromptTemplateRequest) async throws -> PromptTemplate {
        return try await self.request(endpoint: "/api/prompts", method: .post, body: request)
    }

    func updatePrompt(id: String, request: UpdatePromptTemplateRequest) async throws {
        try await requestWithoutResponse(
            endpoint: "/api/prompts/\(id)", method: .patch, body: request)
    }

    func deletePrompt(id: String) async throws {
        try await requestWithoutResponse(endpoint: "/api/prompts/\(id)", method: .delete)
    }

    func enhancePrompt(_ prompt: String) async throws -> String {
        let request = EnhancePromptRequest(prompt: prompt)
        let response: EnhancePromptResponse = try await self.request(
            endpoint: "/api/enhance-prompt", method: .post, body: request)
        return response.enhancedPrompt
    }

    // MARK: - Scheduled Tasks

    func getScheduledTasks() async throws -> [ScheduledTask] {
        return try await request(endpoint: "/api/scheduled-tasks")
    }

    func createScheduledTask(request: CreateScheduledTaskRequest) async throws -> ScheduledTask {
        return try await self.request(
            endpoint: "/api/scheduled-tasks", method: .post, body: request)
    }

    func updateScheduledTask(id: String, request: UpdateScheduledTaskRequest) async throws
        -> ScheduledTask
    {
        return try await self.request(
            endpoint: "/api/scheduled-tasks/\(id)", method: .patch, body: request)
    }

    func deleteScheduledTask(id: String) async throws {
        try await requestWithoutResponse(endpoint: "/api/scheduled-tasks/\(id)", method: .delete)
    }

    func runScheduledTaskNow(id: String) async throws -> ScheduledTaskRunResponse {
        return try await self.request(endpoint: "/api/scheduled-tasks/\(id)/run", method: .post)
    }

    // MARK: - User Rules

    func getUserRules() async throws -> [UserRule] {
        return try await request(endpoint: "/api/db/user-rules")
    }

    func createUserRule(name: String, attach: UserRuleAttachMode, rule: String) async throws
        -> UserRule
    {
        let request = CreateUserRuleRequest(
            action: "create", name: name, attach: attach, rule: rule)
        return try await self.request(endpoint: "/api/db/user-rules", method: .post, body: request)
    }

    func updateUserRule(id: String, attach: UserRuleAttachMode, rule: String) async throws
        -> UserRule
    {
        let request = UpdateUserRuleRequest(
            action: "update", ruleId: id, attach: attach, rule: rule)
        return try await self.request(endpoint: "/api/db/user-rules", method: .post, body: request)
    }

    func renameUserRule(id: String, name: String) async throws -> UserRule {
        let request = RenameUserRuleRequest(action: "rename", ruleId: id, name: name)
        return try await self.request(endpoint: "/api/db/user-rules", method: .post, body: request)
    }

    func deleteUserRule(id: String) async throws {
        try await requestWithoutResponse(endpoint: "/api/db/user-rules?id=\(id)", method: .delete)
    }

    // MARK: - Gallery / Storage

    func getGalleryFiles() async throws -> [GalleryFile] {
        return try await request(endpoint: "/api/storage/gallery")
    }

    func deleteStorageFile(id: String) async throws {
        try await requestWithoutResponse(endpoint: "/api/storage?id=\(id)", method: .delete)
    }

    func clearAllUploads() async throws -> ClearUploadsResponse {
        return try await self.request(endpoint: "/api/storage/clear", method: .delete)
    }

    // MARK: - Developer API Keys

    func getDeveloperAPIKeys() async throws -> [DeveloperAPIKey] {
        let response: DeveloperAPIKeysResponse = try await request(endpoint: "/api/api-keys")
        return response.keys
    }

    func createDeveloperAPIKey(name: String) async throws -> CreateDeveloperAPIKeyResponse {
        let request = CreateDeveloperAPIKeyRequest(name: name)
        return try await self.request(endpoint: "/api/api-keys", method: .post, body: request)
    }

    func deleteDeveloperAPIKey(id: String) async throws {
        let request = DeleteDeveloperAPIKeyRequest(id: id)
        try await requestWithoutResponse(endpoint: "/api/api-keys", method: .delete, body: request)
    }

    // MARK: - Provider API Keys (BYOK)

    func getProviderKey(provider: String) async throws -> String? {
        return try await request(endpoint: "/api/db/user-keys", queryParams: ["provider": provider])
    }

    func setProviderKey(provider: String, key: String) async throws {
        let request = SetProviderKeyRequest(provider: provider, key: key)
        try await requestWithoutResponse(
            endpoint: "/api/db/user-keys", method: .post, body: request)
    }

    func deleteProviderKey(provider: String) async throws {
        try await requestWithoutResponse(
            endpoint: "/api/db/user-keys?provider=\(provider)",
            method: .delete
        )
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

    func setUserModelEnabled(provider: String, modelId: String, enabled: Bool) async throws {
        let request = SetUserModelEnabledRequest(
            action: "set",
            provider: provider,
            modelId: modelId,
            enabled: enabled
        )
        try await requestWithoutResponse(
            endpoint: "/api/db/user-models", method: .post, body: request)
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
        timezone: String? = nil,
        privacyMode: Bool? = nil,
        contextMemoryEnabled: Bool? = nil,
        persistentMemoryEnabled: Bool? = nil,
        youtubeTranscriptsEnabled: Bool? = nil,
        webScrapingEnabled: Bool? = nil,
        mcpEnabled: Bool? = nil,
        followUpQuestionsEnabled: Bool? = nil,
        suggestedPromptsEnabled: Bool? = nil,
        karakeepUrl: String? = nil,
        karakeepApiKey: String? = nil,
        theme: String? = nil,
        titleModelId: String? = nil,
        titleProviderId: String? = nil,
        followUpModelId: String? = nil,
        followUpProviderId: String? = nil
    ) async throws -> UserSettings {
        let request = UpdateUserSettingsRequest(
            action: "update",
            timezone: timezone,
            privacyMode: privacyMode,
            contextMemoryEnabled: contextMemoryEnabled,
            persistentMemoryEnabled: persistentMemoryEnabled,
            youtubeTranscriptsEnabled: youtubeTranscriptsEnabled,
            webScrapingEnabled: webScrapingEnabled,
            mcpEnabled: mcpEnabled,
            followUpQuestionsEnabled: followUpQuestionsEnabled,
            suggestedPromptsEnabled: suggestedPromptsEnabled,
            karakeepUrl: karakeepUrl,
            karakeepApiKey: karakeepApiKey,
            theme: theme,
            titleModelId: titleModelId,
            titleProviderId: titleProviderId,
            followUpModelId: followUpModelId,
            followUpProviderId: followUpProviderId
        )
        return try await self.request(
            endpoint: "/api/db/user-settings", method: .post, body: request)
    }

    private func shouldAttachAuthorizationHeader(to url: URL) -> Bool {
        guard let baseURL = URL(string: config.baseURL) else { return false }
        guard
            baseURL.scheme?.lowercased() == url.scheme?.lowercased(),
            baseURL.host?.lowercased() == url.host?.lowercased()
        else {
            return false
        }

        let basePort = baseURL.port ?? defaultPort(for: baseURL.scheme)
        let urlPort = url.port ?? defaultPort(for: url.scheme)
        return basePort == urlPort
    }

    private func defaultPort(for scheme: String?) -> Int? {
        switch scheme?.lowercased() {
        case "http":
            return 80
        case "https":
            return 443
        default:
            return nil
        }
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

struct DeleteMessageRequest: Codable {
    let action: String
    let messageId: String

    enum CodingKeys: String, CodingKey {
        case action
        case messageId = "messageId"
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
    let web_search_exa_depth: String?
    let web_search_context_size: String?
    let web_search_kagi_source: String?
    let web_search_valyu_search_type: String?
    let provider_id: String?
    let images: [ImageAttachment]?
    let documents: [DocumentAttachment]?
    let image_params: [String: AnyCodable]?
    let video_params: [String: AnyCodable]?
    let temporary: Bool?
}

/// Request body for the SSE streaming endpoint (no image_params/video_params/images as streaming doesn't support image generation)
struct GenerateMessageStreamRequest: Codable {
    let message: String?  // Optional for regeneration (when conversation_id exists)
    let model_id: String
    let conversation_id: String?
    let assistant_id: String?
    let project_id: String?
    let web_search_enabled: Bool
    let web_search_mode: String?
    let web_search_provider: String?
    let web_search_exa_depth: String?
    let web_search_context_size: String?
    let web_search_kagi_source: String?
    let web_search_valyu_search_type: String?
    let provider_id: String?
    let documents: [DocumentAttachment]?
    let reasoning_effort: String?
    let temporary: Bool?
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

struct SetConversationPublicRequest: Codable {
    let action: String
    let conversationId: String
    let isPublic: Bool

    enum CodingKeys: String, CodingKey {
        case action
        case conversationId
        case isPublic = "public"
    }
}

struct UpdateAssistantRequest: Codable {
    let name: String?
    let systemPrompt: String?
    let defaultModelId: String?
    let defaultWebSearchMode: String?
    let defaultWebSearchProvider: String?
    let defaultWebSearchExaDepth: String?
    let defaultWebSearchContextSize: String?
    let defaultWebSearchKagiSource: String?
    let defaultWebSearchValyuSearchType: String?
}

struct AssistantSetDefaultRequest: Codable {
    let action: String
}

// MARK: - Prompt Template Types

struct PromptVariable: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let defaultValue: String?
    let description: String?
}

enum PromptAppendMode: String, Codable, CaseIterable, Identifiable {
    case replace
    case append
    case prepend

    var id: String { rawValue }
}

struct PromptTemplate: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let content: String
    let description: String?
    let variables: [PromptVariable]?
    let defaultModelId: String?
    let defaultWebSearchMode: String?
    let defaultWebSearchProvider: String?
    let appendMode: PromptAppendMode?
    let createdAt: String?
    let updatedAt: String?
}

struct CreatePromptTemplateRequest: Codable {
    let name: String
    let content: String
    let description: String?
    let variables: [PromptVariable]?
    let defaultModelId: String?
    let defaultWebSearchMode: String?
    let defaultWebSearchProvider: String?
    let appendMode: PromptAppendMode?
}

struct UpdatePromptTemplateRequest: Codable {
    let name: String?
    let content: String?
    let description: String?
    let variables: [PromptVariable]?
    let defaultModelId: String?
    let defaultWebSearchMode: String?
    let defaultWebSearchProvider: String?
    let appendMode: PromptAppendMode?
}

struct EnhancePromptRequest: Codable {
    let prompt: String
}

struct EnhancePromptResponse: Codable {
    let ok: Bool
    let enhancedPrompt: String

    enum CodingKeys: String, CodingKey {
        case ok
        case enhancedPrompt = "enhanced_prompt"
    }
}

// MARK: - Scheduled Task Types

struct ScheduledTaskPayload: Codable, Hashable {
    let message: String?
    let modelId: String
    let assistantId: String?
    let projectId: String?
    let conversationId: String?
    let webSearchEnabled: Bool?
    let webSearchMode: String?
    let webSearchProvider: String?
    let webSearchExaDepth: String?
    let webSearchContextSize: String?
    let webSearchKagiSource: String?
    let webSearchValyuSearchType: String?
    let reasoningEffort: String?
    let providerId: String?
    let temporary: Bool?

    enum CodingKeys: String, CodingKey {
        case message
        case modelId = "model_id"
        case assistantId = "assistant_id"
        case projectId = "project_id"
        case conversationId = "conversation_id"
        case webSearchEnabled = "web_search_enabled"
        case webSearchMode = "web_search_mode"
        case webSearchProvider = "web_search_provider"
        case webSearchExaDepth = "web_search_exa_depth"
        case webSearchContextSize = "web_search_context_size"
        case webSearchKagiSource = "web_search_kagi_source"
        case webSearchValyuSearchType = "web_search_valyu_search_type"
        case reasoningEffort = "reasoning_effort"
        case providerId = "provider_id"
        case temporary
    }
}

struct ScheduledTaskSchedule: Codable, Hashable {
    let type: String
    let cron: String?
    let intervalSeconds: Int?
    let runAt: String?

    enum CodingKeys: String, CodingKey {
        case type
        case cron
        case intervalSeconds
        case runAt
    }
}

struct ScheduledTask: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let enabled: Bool
    let scheduleType: String
    let cronExpression: String?
    let intervalSeconds: Int?
    let runAt: String?
    let payload: ScheduledTaskPayload
    let nextRunAt: String?
    let lastRunAt: String?
    let lastRunStatus: String?
    let lastRunError: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case enabled
        case scheduleType
        case cronExpression
        case intervalSeconds
        case runAt
        case payload
        case nextRunAt
        case lastRunAt
        case lastRunStatus
        case lastRunError
        case createdAt
        case updatedAt
    }
}

struct CreateScheduledTaskRequest: Codable {
    let name: String
    let description: String?
    let enabled: Bool?
    let schedule: ScheduledTaskSchedule
    let payload: ScheduledTaskPayload
}

struct UpdateScheduledTaskRequest: Codable {
    let name: String?
    let description: String?
    let enabled: Bool?
    let schedule: ScheduledTaskSchedule?
    let payload: ScheduledTaskPayload?
}

struct ScheduledTaskRunResponse: Codable {
    let success: Bool?
    let error: String?
    let message: String?
}

// MARK: - User Rules Types

enum UserRuleAttachMode: String, Codable, CaseIterable, Identifiable {
    case always
    case manual

    var id: String { rawValue }
}

struct UserRule: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let name: String
    let attach: UserRuleAttachMode
    let rule: String
    let createdAt: String?
    let updatedAt: String?
}

struct CreateUserRuleRequest: Codable {
    let action: String
    let name: String
    let attach: UserRuleAttachMode
    let rule: String
}

struct UpdateUserRuleRequest: Codable {
    let action: String
    let ruleId: String
    let attach: UserRuleAttachMode
    let rule: String
}

struct RenameUserRuleRequest: Codable {
    let action: String
    let ruleId: String
    let name: String
}

// MARK: - Gallery / Storage Types

struct GalleryFile: Codable, Identifiable, Hashable {
    let id: String
    let filename: String
    let mimeType: String
    let size: Int
    let createdAt: String
    let url: String
    let source: String
    let conversationId: String?
    let conversationTitle: String?
    let projectId: String?
    let projectName: String?
}

struct ClearUploadsResponse: Codable {
    let ok: Bool
    let deletedCount: Int
    let errorCount: Int
}

// MARK: - Developer API Key Types

struct DeveloperAPIKey: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let lastUsedAt: String?
    let createdAt: String
}

struct DeveloperAPIKeysResponse: Codable {
    let keys: [DeveloperAPIKey]
}

struct CreateDeveloperAPIKeyRequest: Codable {
    let name: String
}

struct CreateDeveloperAPIKeyResponse: Codable {
    let id: String
    let key: String
    let name: String
    let createdAt: String?
}

struct DeleteDeveloperAPIKeyRequest: Codable {
    let id: String
}

struct SetProviderKeyRequest: Codable {
    let provider: String
    let key: String
}

struct SetUserModelEnabledRequest: Codable {
    let action: String
    let provider: String
    let modelId: String
    let enabled: Bool
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
    let timezone: String?
    let privacyMode: Bool?
    let contextMemoryEnabled: Bool?
    let persistentMemoryEnabled: Bool?
    let youtubeTranscriptsEnabled: Bool?
    let webScrapingEnabled: Bool?
    let mcpEnabled: Bool?
    let followUpQuestionsEnabled: Bool?
    let suggestedPromptsEnabled: Bool?
    let karakeepUrl: String?
    let karakeepApiKey: String?
    let theme: String?
    let titleModelId: String?
    let titleProviderId: String?
    let followUpModelId: String?
    let followUpProviderId: String?

    enum CodingKeys: String, CodingKey {
        case action
        case timezone
        case privacyMode = "privacyMode"
        case contextMemoryEnabled = "contextMemoryEnabled"
        case persistentMemoryEnabled = "persistentMemoryEnabled"
        case youtubeTranscriptsEnabled = "youtubeTranscriptsEnabled"
        case webScrapingEnabled = "webScrapingEnabled"
        case mcpEnabled = "mcpEnabled"
        case followUpQuestionsEnabled = "followUpQuestionsEnabled"
        case suggestedPromptsEnabled = "suggestedPromptsEnabled"
        case karakeepUrl = "karakeepUrl"
        case karakeepApiKey = "karakeepApiKey"
        case theme
        case titleModelId = "titleModelId"
        case titleProviderId = "titleProviderId"
        case followUpModelId = "followUpModelId"
        case followUpProviderId = "followUpProviderId"
    }

    init(
        action: String,
        timezone: String? = nil,
        privacyMode: Bool? = nil,
        contextMemoryEnabled: Bool? = nil,
        persistentMemoryEnabled: Bool? = nil,
        youtubeTranscriptsEnabled: Bool? = nil,
        webScrapingEnabled: Bool? = nil,
        mcpEnabled: Bool? = nil,
        followUpQuestionsEnabled: Bool? = nil,
        suggestedPromptsEnabled: Bool? = nil,
        karakeepUrl: String? = nil,
        karakeepApiKey: String? = nil,
        theme: String? = nil,
        titleModelId: String? = nil,
        titleProviderId: String? = nil,
        followUpModelId: String? = nil,
        followUpProviderId: String? = nil
    ) {
        self.action = action
        self.timezone = timezone
        self.privacyMode = privacyMode
        self.contextMemoryEnabled = contextMemoryEnabled
        self.persistentMemoryEnabled = persistentMemoryEnabled
        self.youtubeTranscriptsEnabled = youtubeTranscriptsEnabled
        self.webScrapingEnabled = webScrapingEnabled
        self.mcpEnabled = mcpEnabled
        self.followUpQuestionsEnabled = followUpQuestionsEnabled
        self.suggestedPromptsEnabled = suggestedPromptsEnabled
        self.karakeepUrl = karakeepUrl
        self.karakeepApiKey = karakeepApiKey
        self.theme = theme
        self.titleModelId = titleModelId
        self.titleProviderId = titleProviderId
        self.followUpModelId = followUpModelId
        self.followUpProviderId = followUpProviderId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)

        // Only include non-nil values
        if let timezone = timezone {
            try container.encode(timezone, forKey: .timezone)
        }
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
        if let suggestedPromptsEnabled = suggestedPromptsEnabled {
            try container.encode(suggestedPromptsEnabled, forKey: .suggestedPromptsEnabled)
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
        if let titleProviderId = titleProviderId {
            try container.encode(titleProviderId, forKey: .titleProviderId)
        }
        if let followUpModelId = followUpModelId {
            try container.encode(followUpModelId, forKey: .followUpModelId)
        }
        if let followUpProviderId = followUpProviderId {
            try container.encode(followUpProviderId, forKey: .followUpProviderId)
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

// MARK: - SSE Streaming Types

/// Represents the different SSE events from the streaming endpoint
enum SSEEvent {
    case messageStart(conversationId: String, messageId: String)
    case delta(content: String, reasoning: String)
    case messageComplete(tokenCount: Int, costUsd: Double, responseTimeMs: Int)
    case error(message: String)
}

/// Raw decoded types for SSE event data
struct SSEMessageStartData: Codable {
    let conversationId: String
    let messageId: String

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case messageId = "message_id"
    }
}

struct SSEDeltaData: Codable {
    let content: String
    let reasoning: String
}

struct SSEMessageCompleteData: Codable {
    let tokenCount: Int
    let costUsd: Double
    let responseTimeMs: Int

    enum CodingKeys: String, CodingKey {
        case tokenCount = "token_count"
        case costUsd = "cost_usd"
        case responseTimeMs = "response_time_ms"
    }
}

struct SSEErrorData: Codable {
    let error: String
}
