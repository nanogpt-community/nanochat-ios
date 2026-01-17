import SwiftUI
import AVFoundation

struct PreviewDocumentItem: Identifiable {
    let id: String
    let document: MessageDocumentResponse
    
    init(document: MessageDocumentResponse) {
        self.id = document.storageId
        self.document = document
    }
}

struct SuggestionChip: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(text)
                    .foregroundStyle(Theme.Colors.text)
                    .font(Theme.Typography.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}

struct TypingIndicator: View {
    @State private var numberOfDots = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Theme.Colors.textSecondary)
                    .frame(width: 6, height: 6)
                    .opacity(numberOfDots == index ? 1 : 0.3)
            }
        }
        .padding(12)
        .background(Theme.Colors.glassPane)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever()) {
                numberOfDots = 2
            }
        }
    }
}

struct StreamingMessageBubble: View {
    let content: String
    let reasoning: String?
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.secondary, Theme.Colors.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32 * Theme.imageScaleFactor, height: 32 * Theme.imageScaleFactor)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(Theme.Typography.system(size: 14))
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Assistant")
                    .font(Theme.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.text)
                
                if let reasoning = reasoning, !reasoning.isEmpty {
                    Text(reasoning)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(8)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Text(content + " ▋") // Cursor effect
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

struct VoiceRecorderSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var audioPreferences: AudioPreferences
    let onTranscription: (String) -> Void
    let onError: (String) -> Void

    @ObservedObject private var audioRecorder = AudioRecorder.shared
    @State private var isTranscribing = false
    @State private var hasPermission = false

    var body: some View {
        VStack(spacing: 20) {
            if isTranscribing {
                Text("Transcribing...")
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.text)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                    .scaleEffect(1.5)
            } else {
                Text(audioRecorder.isRecording ? "Listening..." : "Tap to speak")
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.text)

                if audioRecorder.isRecording {
                    Text(formatTime(audioRecorder.elapsedTime))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Button {
                    Task {
                        await toggleRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(audioRecorder.isRecording ? Theme.Colors.error : Theme.Colors.primary)
                            .frame(width: 80, height: 80)

                        Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                }
                .disabled(!hasPermission)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.glassBackground)
        .task {
            hasPermission = await audioRecorder.requestPermission()
            if !hasPermission {
                onError("Microphone access is required for voice input. Please enable it in Settings.")
                dismiss()
            }
        }
    }

    private func toggleRecording() async {
        if audioRecorder.isRecording {
            isTranscribing = true
            guard let recordingURL = await audioRecorder.stopRecording() else {
                isTranscribing = false
                onError("Recording failed. Please try again.")
                dismiss()
                return
            }

            do {
                let response = try await NanoChatAPI.shared.transcribeAudio(
                    fileURL: recordingURL,
                    model: audioPreferences.sttModel,
                    language: audioPreferences.sttLanguage
                )

                if let transcription = response.transcription, !transcription.isEmpty {
                    onTranscription(transcription)
                } else {
                    onError("No speech detected. Please try again.")
                }
            } catch {
                onError("Transcription failed: \(error.localizedDescription)")
            }

            isTranscribing = false
            dismiss()
        } else {
            do {
                try audioRecorder.startRecording()
            } catch {
                onError("Could not start recording: \(error.localizedDescription)")
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
