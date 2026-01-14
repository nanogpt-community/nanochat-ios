import AVFoundation
import Foundation

@MainActor
final class AudioPlaybackManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioPlaybackManager()

    @Published var currentlyPlayingMessageId: String?
    @Published var isLoadingMessageId: String?

    private var player: AVAudioPlayer?

    func play(data: Data, messageId: String) throws {
        stop()

        player = try AVAudioPlayer(data: data)
        player?.delegate = self
        player?.prepareToPlay()
        player?.play()

        currentlyPlayingMessageId = messageId
    }

    func stop() {
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
