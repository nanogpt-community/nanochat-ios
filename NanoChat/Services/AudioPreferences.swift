import Foundation
import SwiftUI

struct AudioOption: Identifiable, Hashable {
    let id: String
    let label: String
}

@MainActor
final class AudioPreferences: ObservableObject {
    static let shared = AudioPreferences()

    @Published var ttsModel: String {
        didSet {
            saveValue(ttsModel, key: Keys.ttsModel)
            ensureValidVoice()
        }
    }

    @Published var ttsVoice: String {
        didSet {
            saveValue(ttsVoice, key: Keys.ttsVoice)
        }
    }

    @Published var ttsSpeed: Double {
        didSet {
            saveValue(ttsSpeed, key: Keys.ttsSpeed)
        }
    }

    @Published var sttModel: String {
        didSet {
            saveValue(sttModel, key: Keys.sttModel)
        }
    }

    @Published var sttLanguage: String {
        didSet {
            saveValue(sttLanguage, key: Keys.sttLanguage)
        }
    }

    @Published var autoSendTranscription: Bool {
        didSet {
            saveValue(autoSendTranscription, key: Keys.autoSendTranscription)
        }
    }

    var availableVoices: [AudioOption] {
        if ttsModel.starts(with: "Eleven") {
            return Self.elevenLabsVoices
        }
        if ttsModel.starts(with: "Kokoro") {
            return Self.kokoroVoices
        }
        return Self.openAiVoices
    }

    private init() {
        let defaults = UserDefaults.standard
        ttsModel = defaults.string(forKey: Keys.ttsModel) ?? "tts-1"
        ttsVoice = defaults.string(forKey: Keys.ttsVoice) ?? "alloy"
        ttsSpeed = defaults.object(forKey: Keys.ttsSpeed) as? Double ?? 1.0
        sttModel = defaults.string(forKey: Keys.sttModel) ?? "Whisper-Large-V3"
        sttLanguage = defaults.string(forKey: Keys.sttLanguage) ?? "auto"
        autoSendTranscription = defaults.object(forKey: Keys.autoSendTranscription) as? Bool ?? false
        ensureValidVoice()
    }

    func updateTtsModel(_ model: String) {
        ttsModel = model
    }

    func updateVoice(_ voice: String) {
        ttsVoice = voice
    }

    private func ensureValidVoice() {
        let voices = availableVoices
        guard !voices.contains(where: { $0.id == ttsVoice }) else { return }

        if ttsModel.starts(with: "Eleven") {
            ttsVoice = "Rachel"
        } else if ttsModel.starts(with: "Kokoro") {
            ttsVoice = "af_bella"
        } else {
            ttsVoice = "alloy"
        }
    }

    private func saveValue(_ value: Any, key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private enum Keys {
        static let ttsModel = "audio_tts_model"
        static let ttsVoice = "audio_tts_voice"
        static let ttsSpeed = "audio_tts_speed"
        static let sttModel = "audio_stt_model"
        static let sttLanguage = "audio_stt_language"
        static let autoSendTranscription = "audio_auto_send_transcription"
    }

    static let ttsModels: [AudioOption] = [
        AudioOption(id: "gpt-4o-mini-tts", label: "GPT-4o Mini (OpenAI) - $0.0006/1k"),
        AudioOption(id: "tts-1", label: "TTS-1 (Standard) - $0.015/1k"),
        AudioOption(id: "tts-1-hd", label: "TTS-1 HD (High Def) - $0.030/1k"),
        AudioOption(id: "Kokoro-82m", label: "Kokoro (Multilingual) - $0.001/1k"),
        AudioOption(id: "Elevenlabs-Turbo-V2.5", label: "ElevenLabs Turbo - $0.06/1k"),
    ]

    static let sttModels: [AudioOption] = [
        AudioOption(id: "Whisper-Large-V3", label: "Whisper Large V3 (OpenAI) - $0.01/min"),
        AudioOption(id: "Wizper", label: "Wizper (Fast) - $0.01/min"),
        AudioOption(id: "Elevenlabs-STT", label: "ElevenLabs STT - $0.03/min"),
    ]

    static let openAiVoices: [AudioOption] = [
        AudioOption(id: "alloy", label: "Alloy"),
        AudioOption(id: "echo", label: "Echo"),
        AudioOption(id: "fable", label: "Fable"),
        AudioOption(id: "onyx", label: "Onyx"),
        AudioOption(id: "nova", label: "Nova"),
        AudioOption(id: "shimmer", label: "Shimmer"),
        AudioOption(id: "ash", label: "Ash"),
        AudioOption(id: "ballad", label: "Ballad"),
        AudioOption(id: "coral", label: "Coral"),
        AudioOption(id: "sage", label: "Sage"),
        AudioOption(id: "verse", label: "Verse"),
    ]

    static let kokoroVoices: [AudioOption] = [
        AudioOption(id: "af_alloy", label: "Alloy (US F)"),
        AudioOption(id: "af_aoede", label: "Aoede (US F)"),
        AudioOption(id: "af_bella", label: "Bella (US F)"),
        AudioOption(id: "af_jessica", label: "Jessica (US F)"),
        AudioOption(id: "af_nova", label: "Nova (US F)"),
        AudioOption(id: "am_adam", label: "Adam (US M)"),
        AudioOption(id: "am_echo", label: "Echo (US M)"),
        AudioOption(id: "am_eric", label: "Eric (US M)"),
        AudioOption(id: "am_liam", label: "Liam (US M)"),
        AudioOption(id: "am_onyx", label: "Onyx (US M)"),
        AudioOption(id: "bf_alice", label: "Alice (UK F)"),
        AudioOption(id: "bf_emma", label: "Emma (UK F)"),
        AudioOption(id: "bf_isabella", label: "Isabella (UK F)"),
        AudioOption(id: "bf_lily", label: "Lily (UK F)"),
        AudioOption(id: "bm_daniel", label: "Daniel (UK M)"),
        AudioOption(id: "bm_fable", label: "Fable (UK M)"),
        AudioOption(id: "bm_george", label: "George (UK M)"),
        AudioOption(id: "bm_lewis", label: "Lewis (UK M)"),
        AudioOption(id: "jf_alpha", label: "Alpha (Japanese F)"),
        AudioOption(id: "jf_gongitsune", label: "Gongitsune (Japanese F)"),
        AudioOption(id: "jf_nezumi", label: "Nezumi (Japanese F)"),
        AudioOption(id: "jf_tebukuro", label: "Tebukuro (Japanese F)"),
        AudioOption(id: "zf_xiaoxiao", label: "Xiaoxiao (Chinese F)"),
        AudioOption(id: "ff_siwis", label: "Siwis (French F)"),
        AudioOption(id: "im_nicola", label: "Nicola (Italian M)"),
        AudioOption(id: "hf_alpha", label: "Alpha (Hindi F)"),
    ]

    static let elevenLabsVoices: [AudioOption] = [
        "Adam",
        "Alice",
        "Antoni",
        "Aria",
        "Arnold",
        "Bella",
        "Bill",
        "Brian",
        "Callum",
        "Charlie",
        "Charlotte",
        "Chris",
        "Daniel",
        "Domi",
        "Dorothy",
        "Drew",
        "Elli",
        "Emily",
        "Eric",
        "Ethan",
        "Fin",
        "Freya",
        "George",
        "Gigi",
        "Giovanni",
        "Grace",
        "James",
        "Jeremy",
        "Jessica",
        "Joseph",
        "Josh",
        "Laura",
        "Liam",
        "Lily",
        "Matilda",
        "Matthew",
        "Michael",
        "Nicole",
        "Rachel",
        "River",
        "Roger",
        "Ryan",
        "Sam",
        "Sarah",
        "Thomas",
        "Will",
    ].map { AudioOption(id: $0, label: $0) }

    static let sttLanguages: [AudioOption] = [
        AudioOption(id: "auto", label: "Auto"),
        AudioOption(id: "en", label: "English"),
        AudioOption(id: "es", label: "Spanish"),
        AudioOption(id: "fr", label: "French"),
        AudioOption(id: "de", label: "German"),
        AudioOption(id: "it", label: "Italian"),
        AudioOption(id: "pt", label: "Portuguese"),
        AudioOption(id: "ja", label: "Japanese"),
        AudioOption(id: "zh", label: "Chinese"),
        AudioOption(id: "ko", label: "Korean"),
    ]
}
