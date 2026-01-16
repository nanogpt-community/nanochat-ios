import Photos
import SwiftUI
import UIKit

struct ImagePreviewItem: Identifiable, Equatable {
    let url: URL
    let fileName: String

    var id: String { url.absoluteString }
}

struct ImagePreviewView: View {
    let item: ImagePreviewItem

    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @State private var saveAlertMessage: String?

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                headerBar

                AsyncImage(url: item.url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(Theme.Colors.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                    .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                            )
                            .padding(.horizontal, Theme.Spacing.lg)
                            .transition(.opacity)
                    case .failure:
                        VStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "photo")
                                .font(.system(size: 36))
                                .foregroundStyle(Theme.Colors.textTertiary)
                            Text("Unable to load image")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        EmptyView()
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.top, Theme.Spacing.lg)
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

    private var headerBar: some View {
        GlassEffectContainer {
            HStack(spacing: Theme.Spacing.sm) {
                // File name badge
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "photo")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.accent)

                    Text(item.fileName.isEmpty ? "image" : item.fileName)
                        .font(.subheadline)
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
                            .font(.system(size: 16, weight: .semibold))
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
                        .font(.system(size: 14, weight: .semibold))
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
            let (data, _) = try await URLSession.shared.data(from: item.url)
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
        } catch {
            HapticManager.shared.error()
            saveAlertMessage = "Unable to save image"
        }
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
