import AVFoundation
import Foundation

@MainActor
final class AudioPlaybackManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioPlaybackManager()

    @Published var currentlyPlayingMessageId: String?
    @Published var isLoadingMessageId: String?

    private var player: AVAudioPlayer?
    
    // Computed property for compatibility
    var isPlaying: Bool {
        return player?.isPlaying ?? false
    }
    
    var currentMessageId: String? {
        return currentlyPlayingMessageId
    }

    func play(data: Data, messageId: String) throws {
        stopPlayback()

        player = try AVAudioPlayer(data: data)
        player?.delegate = self
        player?.prepareToPlay()
        player?.play()

        currentlyPlayingMessageId = messageId
    }
    
    func playAudio(url: URL, messageId: String) {
        do {
            let data = try Data(contentsOf: url)
            try play(data: data, messageId: messageId)
        } catch {
            print("Failed to play audio from URL: \(error)")
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        currentlyPlayingMessageId = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.currentlyPlayingMessageId = nil
        }
    }
}
