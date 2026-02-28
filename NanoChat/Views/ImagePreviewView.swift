import Photos
import SwiftUI
import UIKit

#if canImport(AppKit)
    import AppKit
#endif

struct ImagePreviewItem: Identifiable, Equatable {
    let url: URL
    let fileName: String
    let storageId: String?

    var id: String { url.absoluteString }

    init(url: URL, fileName: String, storageId: String? = nil) {
        self.url = url
        self.fileName = fileName
        self.storageId = storageId
    }
}

struct ImagePreviewView: View {
    let item: ImagePreviewItem

    @Environment(\.dismiss) private var dismiss
    @State private var imageData: Data?
    @State private var isLoadingImage = false
    @State private var isSaving = false
    @State private var saveAlertMessage: String?

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                headerBar

                Group {
                    if isLoadingImage {
                        ProgressView()
                            .tint(Theme.Colors.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let imageData {
                        loadedImageView(data: imageData)
                    } else {
                        VStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "photo")
                                .font(Theme.Typography.system(size: 36))
                                .foregroundStyle(Theme.Colors.textTertiary)
                            Text("Unable to load image")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.top, Theme.Spacing.lg)
        }
        .task {
            await loadPreviewImage()
        }
        .alert(
            "Image",
            isPresented: Binding(
                get: { saveAlertMessage != nil },
                set: { if !$0 { saveAlertMessage = nil } }
            )
        ) {
            Button("OK") {
                saveAlertMessage = nil
            }
        } message: {
            Text(saveAlertMessage ?? "")
        }
    }

    @ViewBuilder
    private func loadedImageView(data: Data) -> some View {
        #if canImport(UIKit)
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, Theme.Spacing.lg)
                    .transition(.opacity)
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "photo")
                        .font(Theme.Typography.system(size: 36))
                        .foregroundStyle(Theme.Colors.textTertiary)
                    Text("Unable to decode image")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        #elseif canImport(AppKit)
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, Theme.Spacing.lg)
                    .transition(.opacity)
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "photo")
                        .font(Theme.Typography.system(size: 36))
                        .foregroundStyle(Theme.Colors.textTertiary)
                    Text("Unable to decode image")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        #else
            EmptyView()
        #endif
    }

    private var headerBar: some View {
        GlassEffectContainer {
            HStack(spacing: Theme.Spacing.sm) {
                // File name badge
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "photo")
                        .font(Theme.Typography.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.accent)

                    Text(item.fileName.isEmpty ? "image" : item.fileName)
                        .font(Theme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Colors.text)
                        .lineLimit(1)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .glassEffect()

                Spacer()

                // Save button
                Button {
                    Task {
                        await saveImage()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(Theme.Colors.accent)
                            .frame(width: 36, height: 36)
                            .glassEffect(in: .circle)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(Theme.Typography.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.Colors.text)
                            .frame(width: 36, height: 36)
                            .glassEffect(in: .circle)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isSaving)

                // Close button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(Theme.Typography.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.text)
                        .frame(width: 36, height: 36)
                        .glassEffect(in: .circle)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    @MainActor
    private func saveImage() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            #if canImport(UIKit)
                let data: Data
                if let existingData = imageData {
                    data = existingData
                } else {
                    data = try await fetchImageData()
                }
                guard let image = UIImage(data: data) else {
                    throw ImageSaveError.invalidData
                }

                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    throw ImageSaveError.permissionDenied
                }

                try await saveToPhotos(image)
                HapticManager.shared.success()
                saveAlertMessage = "Saved to Photos"
            #else
                throw ImageSaveError.unknown
            #endif
        } catch {
            HapticManager.shared.error()
            saveAlertMessage = "Unable to save image"
        }
    }

    private func loadPreviewImage() async {
        guard imageData == nil else { return }

        isLoadingImage = true
        defer { isLoadingImage = false }

        do {
            imageData = try await fetchImageData()
        } catch {
            imageData = nil
        }
    }

    private func fetchImageData() async throws -> Data {
        if let storageId = item.storageId {
            do {
                return try await NanoChatAPI.shared.downloadStorageData(storageId: storageId)
            } catch {
                // Older/imported messages can carry a non-resolvable storageId; retry via URL.
                return try await NanoChatAPI.shared.downloadData(from: item.url)
            }
        }

        return try await NanoChatAPI.shared.downloadData(from: item.url)
    }

    private func saveToPhotos(_ image: UIImage) async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if success {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: ImageSaveError.unknown)
                    }
                }
            }
        }
    }
}

private enum ImageSaveError: Error {
    case invalidData
    case permissionDenied
    case unknown
}
