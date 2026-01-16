import Foundation
import SwiftUI

/// Manager for exporting conversations to various formats
@MainActor
final class ExportManager {
    static let shared = ExportManager()

    private init() {}

    // MARK: - Export Formats

    enum ExportFormat {
        case markdown
        case text
        case json

        var fileExtension: String {
            switch self {
            case .markdown: return "md"
            case .text: return "txt"
            case .json: return "json"
            }
        }

        var mimeType: String {
            switch self {
            case .markdown: return "text/markdown"
            case .text: return "text/plain"
            case .json: return "application/json"
            }
        }
    }

    // MARK: - Export Conversation

    /// Export a single conversation to Markdown format
    /// - Parameters:
    ///   - conversation: The conversation to export
    ///   - messages: Array of messages in the conversation
    /// - Returns: The exported markdown string
    func exportConversationToMarkdown(
        conversation: ConversationResponse,
        messages: [MessageResponse]
    ) -> String {
        var markdown = "# \(conversation.title)\n\n"
        markdown += "**Exported on:** \(formatDate(Date()))\n"

        markdown += "**Last updated:** \(formatDate(conversation.updatedAt))\n"

        if let projectId = conversation.projectId {
            markdown += "**Project ID:** \(projectId)\n"
        }

        markdown += "\n---\n\n"

        for message in messages {
            let role = message.role == "user" ? "**You**" : "**Assistant**"
            let modelInfo = message.modelId.map { " *(\($0))*" } ?? ""

            // Header with role and model info
            markdown += "### \(role)\(modelInfo)\n\n"

            // Timestamp
            markdown += "*\(formatDate(message.createdAt))*\n\n"

            // Add images if present
            if let images = message.images, !images.isEmpty {
                for image in images {
                    let fileName = image.fileName ?? "image"
                    markdown += "![\(fileName)](\(image.url))\n\n"
                }
            }

            // Add reasoning if present (collapsed)
            if let reasoning = message.reasoning, !reasoning.isEmpty {
                markdown += "<details>\n"
                markdown += "<summary>💭 Reasoning</summary>\n\n"
                markdown += "\(reasoning)\n\n"
                markdown += "</details>\n\n"
            }

            // Add main content
            markdown += "\(message.content)\n\n"

            // Add document attachments if present
            if let documents = message.documents, !documents.isEmpty {
                markdown += "**Attachments:**\n"
                for doc in documents {
                    let fileName = doc.fileName ?? "document"
                    markdown += "- [\(fileName)](\(doc.url))\n"
                }
                markdown += "\n"
            }

            markdown += "---\n\n"
        }

        return markdown
    }

    /// Export multiple conversations to Markdown
    /// - Parameters:
    ///   - conversations: Array of (conversation, messages) tuples
    /// - Returns: Combined markdown string
    func exportMultipleConversationsToMarkdown(
        items: [(conversation: ConversationResponse, messages: [MessageResponse])]
    ) -> String {
        var markdown = "# NanoChat Export\n\n"
        markdown += "**Exported on:** \(formatDate(Date()))\n"
        markdown += "**Conversations:** \(items.count)\n\n"
        markdown += "---\n\n"

        for (index, item) in items.enumerated() {
            markdown += "## \(index + 1). \(item.conversation.title)\n\n"
            markdown += exportConversationToMarkdown(
                conversation: item.conversation,
                messages: item.messages
            )
        }

        return markdown
    }

    /// Export conversation to plain text
    func exportConversationToText(
        conversation: ConversationResponse,
        messages: [MessageResponse]
    ) -> String {
        var text = "\(conversation.title)\n"
        text += String(repeating: "=", count: conversation.title.count) + "\n\n"
        text += "Exported: \(formatDate(Date()))\n\n"

        for message in messages {
            let role = message.role == "user" ? "You" : "Assistant"
            text += "[\(role)]:\n\(message.content)\n\n"
        }

        return text
    }

    // MARK: - Share Export

    /// Present share sheet with exported content
    /// - Parameters:
    ///   - content: The content to share
    ///   - fileName: Suggested filename
    ///   - format: Export format
    func presentShareSheet(
        content: String,
        fileName: String,
        format: ExportFormat = .markdown
    ) {
        guard let data = content.data(using: .utf8) else { return }

        // Create temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(fileName).\(format.fileExtension)")

        do {
            try data.write(to: fileURL)

            // Present share sheet
            let activityViewController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityViewController, animated: true)
            }
        } catch {
            print("Failed to write file: \(error)")
        }
    }

    /// Present share sheet with multiple exported conversations
    func presentShareSheetForMultiple(
        items: [(conversation: ConversationResponse, messages: [MessageResponse])],
        format: ExportFormat = .markdown
    ) {
        let content = exportMultipleConversationsToMarkdown(items: items)
        let fileName = "nanochat-export-\(Date().timeIntervalSince1970)"
        presentShareSheet(content: content, fileName: fileName, format: format)
    }

    // MARK: - Sanitize Filename

    /// Sanitize conversation title for use as filename
    func sanitizeFilename(_ title: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?*|<>\"")
        let sanitized = title
            .components(separatedBy: invalidCharacters)
            .joined(separator: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Limit length and replace spaces with hyphens
        let processed = sanitized
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()

        return String(processed.prefix(50))
    }

    // MARK: - Helper Functions

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
