import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct DocumentPreviewView: View {
    let document: MessageDocumentResponse
    let onClose: () -> Void

    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var documentContent: String?
    @State private var pdfDocument: PDFDocument?
    @State private var shareSheetPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(Theme.Colors.secondary)
                        .scaleEffect(1.5)
                } else if let error = errorMessage {
                    ContentUnavailableView {
                        Label("Document Error", systemImage: "doc.badge.exclamationmark")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    } description: {
                        Text(error)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    } actions: {
                        Button("Retry") {
                            Task {
                                await loadDocument()
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                } else if let pdf = pdfDocument {
                    PDFKitRepresentedView(pdfDocument: pdf)
                        .ignoresSafeArea()
                } else if let content = documentContent {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            Text(document.fileName ?? "Document")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.Colors.text)
                                .padding(.horizontal)

                            Divider()
                                .overlay(Theme.Colors.glassBorder)

                            Text(renderContent(content))
                                .font(.body)
                                .foregroundStyle(Theme.Colors.text)
                                .textSelection(.enabled)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(document.fileName ?? "Document")
            .navigationBarTitleDisplayMode(.inline)
            .liquidGlassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        HapticManager.shared.tap()
                        onClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        HapticManager.shared.tap()
                        shareSheetPresented = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body)
                    }
                    .foregroundStyle(Theme.Colors.secondary)
                }
            }
            .onAppear {
                Task {
                    await loadDocument()
                }
            }
            .sheet(isPresented: $shareSheetPresented) {
                if let content = documentContent {
                    ShareSheet(activityItems: [content])
                } else if let pdfURL = pdfDocumentURL {
                    ShareSheet(activityItems: [pdfURL])
                }
            }
        }
    }

    private var pdfDocumentURL: URL? {
        URL(string: document.url)
    }

    private func loadDocument() async {
        isLoading = true
        errorMessage = nil

        do {
            let content: String

            if document.fileType.lowercased() == "pdf" {
                // For PDF, we'll load it directly in PDFKitRepresentedView
                if let url = URL(string: document.url) {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let pdf = PDFDocument(data: data) {
                        pdfDocument = pdf
                        isLoading = false
                        return
                    }
                }
                errorMessage = "Failed to load PDF document"
            } else if document.fileType.lowercased() == "markdown" ||
                        document.fileType.lowercased() == "md" {
                content = try await fetchDocumentContent()
                documentContent = content
            } else {
                // For text and epub, fetch as plain text
                content = try await fetchDocumentContent()
                documentContent = content
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func fetchDocumentContent() async throws -> String {
        guard let url = URL(string: document.url) else {
            throw DocumentError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let content = String(data: data, encoding: .utf8) else {
            throw DocumentError.decodingFailed
        }

        return content
    }

    private func renderContent(_ content: String) -> AttributedString {
        if document.fileType.lowercased() == "markdown" ||
            document.fileType.lowercased() == "md" {
            // Simple markdown rendering
            let attributed = AttributedString(content)
            return attributed
        }
        return AttributedString(content)
    }
}

enum DocumentError: LocalizedError {
    case invalidURL
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid document URL"
        case .decodingFailed:
            return "Failed to decode document content"
        }
    }
}

// PDFKit wrapper for SwiftUI
struct PDFKitRepresentedView: UIViewRepresentable {
    let pdfDocument: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false, withViewOptions: nil)
        pdfView.backgroundColor = .clear
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = pdfDocument
    }
}

// ShareSheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    DocumentPreviewView(
        document: MessageDocumentResponse(
            url: "https://www.africau.edu/images/default/sample.pdf",
            storageId: "preview",
            fileName: "Sample PDF",
            fileType: "pdf"
        ),
        onClose: {}
    )
}
