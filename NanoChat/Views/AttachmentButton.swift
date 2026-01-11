import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AttachmentButton: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isShowingImagePicker = false
    @State private var isShowingDocumentPicker = false
    let onImageSelected: (Data) -> Void
    let onDocumentSelected: ((URL) -> Void)?

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
                // TODO: Implement voice recording
            } label: {
                Label("Voice Input", systemImage: "mic")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.Colors.glassBackground)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                    )

                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
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

#Preview {
    AttachmentButton { imageData in
        print("Image selected: \(imageData.count) bytes")
    } onDocumentSelected: { url in
        print("Document selected: \(url)")
    }
    .padding()
    .background(Theme.Gradients.background)
}
