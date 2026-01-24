import SwiftUI

/// A view that renders markdown text with proper styling
struct MarkdownText: View {
    let content: String
    let textColor: Color
    let codeBackgroundColor: Color

    init(
        _ content: String,
        textColor: Color = Theme.Colors.text,
        codeBackgroundColor: Color = Theme.Colors.glassSurface
    ) {
        self.content = content
        self.textColor = textColor
        self.codeBackgroundColor = codeBackgroundColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseBlocks(content), id: \.id) { block in
                switch block.type {
                case .codeBlock(let language):
                    CodeBlockView(code: block.content, language: language)
                case .text:
                    renderInlineMarkdown(block.content)
                }
            }
        }
    }

    // MARK: - Block Parsing

    private struct ContentBlock: Identifiable {
        let id = UUID()
        let type: BlockType
        let content: String
    }

    private enum BlockType {
        case text
        case codeBlock(language: String?)
    }

    private func parseBlocks(_ text: String) -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        var currentText = ""
        var inCodeBlock = false
        var codeBlockContent = ""
        var codeBlockLanguage: String?

        let lines = text.components(separatedBy: "\n")

        for line in lines {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End of code block
                    blocks.append(
                        ContentBlock(
                            type: .codeBlock(language: codeBlockLanguage),
                            content: codeBlockContent.trimmingCharacters(in: .newlines)))
                    codeBlockContent = ""
                    codeBlockLanguage = nil
                    inCodeBlock = false
                } else {
                    // Start of code block
                    if !currentText.isEmpty {
                        blocks.append(
                            ContentBlock(
                                type: .text, content: currentText.trimmingCharacters(in: .newlines))
                        )
                        currentText = ""
                    }
                    // Extract language if specified
                    let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    codeBlockLanguage = lang.isEmpty ? nil : lang
                    inCodeBlock = true
                }
            } else if inCodeBlock {
                codeBlockContent += (codeBlockContent.isEmpty ? "" : "\n") + line
            } else {
                currentText += (currentText.isEmpty ? "" : "\n") + line
            }
        }

        // Add any remaining text
        if !currentText.isEmpty {
            blocks.append(
                ContentBlock(type: .text, content: currentText.trimmingCharacters(in: .newlines)))
        }

        // Handle unclosed code block
        if inCodeBlock && !codeBlockContent.isEmpty {
            blocks.append(
                ContentBlock(
                    type: .codeBlock(language: codeBlockLanguage),
                    content: codeBlockContent.trimmingCharacters(in: .newlines)))
        }

        return blocks
    }

    // MARK: - Inline Markdown Rendering

    @ViewBuilder
    private func renderInlineMarkdown(_ text: String) -> some View {
        if let attributedString = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace))
        {
            Text(attributedString)
                .font(Theme.Typography.body)
                .foregroundStyle(textColor)
                .textSelection(.enabled)
        } else {
            // Fallback to plain text if markdown parsing fails
            Text(text)
                .font(Theme.Typography.body)
                .foregroundStyle(textColor)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Code Block View

struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language and copy button
            HStack {
                if let language = language, !language.isEmpty {
                    Text(language)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                Spacer()

                Button {
                    UIPasteboard.general.string = code
                    isCopied = true
                    HapticManager.shared.success()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                        Text(isCopied ? "Copied" : "Copy")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.Colors.insetBackground)

            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(Theme.Colors.text)
                    .textSelection(.enabled)
                    .padding(12)
            }
        }
        .background(Theme.Colors.glassSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            MarkdownText("This is **bold** and *italic* text.")

            MarkdownText("Here is some `inline code` in a sentence.")

            MarkdownText(
                """
                Here is a code block:

                ```swift
                func hello() {
                    print("Hello, World!")
                }
                ```

                And more text after.
                """)

            MarkdownText("Check out [this link](https://example.com) for more info.")
        }
        .padding()
    }
    .background(Theme.Colors.backgroundStart)
}
