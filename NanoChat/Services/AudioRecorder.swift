import AVFoundation
import Foundation

@MainActor
final class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    static let shared = AudioRecorder()

    @Published var isRecording = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var lastRecordingURL: URL?

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var stopContinuation: CheckedContinuation<Bool, Never>?

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true, options: [])

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
        ]

        recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder?.delegate = self
        recorder?.prepareToRecord()
        recorder?.record()

        lastRecordingURL = fileURL
        elapsedTime = 0
        isRecording = true
        startTimer()
    }

    func stopRecording() async -> URL? {
        guard let recorder else {
            isRecording = false
            stopTimer()
            return lastRecordingURL
        }

        let didFinish = await withCheckedContinuation { continuation in
            stopContinuation = continuation
            recorder.stop()
        }

        self.recorder = nil
        isRecording = false
        stopTimer()
        return didFinish ? lastRecordingURL : nil
    }

    func reset() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        elapsedTime = 0
        lastRecordingURL = nil
        stopTimer()
    }

    nonisolated func audioRecorderDidFinishRecording(
        _ recorder: AVAudioRecorder,
        successfully flag: Bool
    ) {
        Task { @MainActor in
            stopContinuation?.resume(returning: flag)
            stopContinuation = nil
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.elapsedTime += 0.25
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
