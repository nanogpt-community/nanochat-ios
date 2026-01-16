import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AttachmentButton: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isShowingImagePicker = false
    @State private var isShowingDocumentPicker = false
    let onImageSelected: (Data) -> Void
    let onDocumentSelected: ((URL) -> Void)?
    let onVoiceInput: (() -> Void)?

    var body: some View {
        Menu {
            // Photo Library - using PhotosPicker
            Button {
                HapticManager.shared.lightTap()
                isShowingImagePicker = true
            } label: {
                Label("Choose photos", systemImage: "photo.on.rectangle")
            }

            // Document picker
            Button {
                HapticManager.shared.lightTap()
                isShowingDocumentPicker = true
            } label: {
                Label("Document", systemImage: "doc")
            }

            Divider()

            // Voice input (placeholder for now)
            Button {
                HapticManager.shared.lightTap()
                onVoiceInput?()
            } label: {
                Label("Voice Input", systemImage: "mic")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.text)
                .frame(width: 36, height: 36)
                .glassEffect(in: .circle)
        }
        .photosPicker(
            isPresented: $isShowingImagePicker,
            selection: $selectedItems,
            maxSelectionCount: 5,
            matching: .images
        )
        .onChange(of: selectedItems) { _, newItems in
            Task {
                await loadImages(from: newItems)
            }
        }
        .fileImporter(
            isPresented: $isShowingDocumentPicker,
            allowedContentTypes: [.pdf, .text, .rtf, .plainText],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                HapticManager.shared.success()
                for url in urls {
                    onDocumentSelected?(url)
                }
            case .failure(let error):
                HapticManager.shared.error()
                print("Document picker error: \(error)")
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    HapticManager.shared.success()
                }
                onImageSelected(data)
            }
        }
        // Clear selection after loading
        await MainActor.run {
            selectedItems = []
        }
    }
}

// MARK: - Expanded Attachment Bar (Alternative horizontal layout)

struct AttachmentBar: View {
    let onImageSelected: (Data) -> Void
    let onDocumentSelected: ((URL) -> Void)?
    let onVoiceInput: (() -> Void)?

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isShowingImagePicker = false
    @State private var isShowingDocumentPicker = false

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: Theme.Spacing.md) {
                // Photo button
                Button {
                    HapticManager.shared.lightTap()
                    isShowingImagePicker = true
                } label: {
                    Image(systemName: "photo")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.Colors.text)
                        .frame(width: 44, height: 44)
                        .glassEffect(in: .circle)
                }
                .buttonStyle(.plain)

                // Document button
                Button {
                    HapticManager.shared.lightTap()
                    isShowingDocumentPicker = true
                } label: {
                    Image(systemName: "doc")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.Colors.text)
                        .frame(width: 44, height: 44)
                        .glassEffect(in: .circle)
                }
                .buttonStyle(.plain)

                // Voice input button
                if let onVoiceInput {
                    Button {
                        HapticManager.shared.lightTap()
                        onVoiceInput()
                    } label: {
                        Image(systemName: "mic")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 44, height: 44)
                            .tint(Theme.Colors.accent)
                            .glassEffect(in: .circle)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .photosPicker(
            isPresented: $isShowingImagePicker,
            selection: $selectedItems,
            maxSelectionCount: 5,
            matching: .images
        )
        .onChange(of: selectedItems) { _, newItems in
            Task {
                await loadImages(from: newItems)
            }
        }
        .fileImporter(
            isPresented: $isShowingDocumentPicker,
            allowedContentTypes: [.pdf, .text, .rtf, .plainText],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                HapticManager.shared.success()
                for url in urls {
                    onDocumentSelected?(url)
                }
            case .failure(let error):
                HapticManager.shared.error()
                print("Document picker error: \(error)")
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    HapticManager.shared.success()
                }
                onImageSelected(data)
            }
        }
        await MainActor.run {
            selectedItems = []
        }
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.xl) {
        AttachmentButton { imageData in
            print("Image selected: \(imageData.count) bytes")
        } onDocumentSelected: { url in
            print("Document selected: \(url)")
        } onVoiceInput: {
            print("Voice input")
        }

        AttachmentBar { imageData in
            print("Image selected: \(imageData.count) bytes")
        } onDocumentSelected: { url in
            print("Document selected: \(url)")
        } onVoiceInput: {
            print("Voice input")
        }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.Gradients.background)
}
