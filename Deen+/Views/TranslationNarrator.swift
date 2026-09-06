//
//  TranslationNarrator.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/6/26.
//

import Foundation
import Combine
import AVFoundation

// MARK: - Available Translation Voices / Narrators

enum TranslationVoice: String, CaseIterable, Identifiable, Sendable {
    case ibrahimWalk = "ibrahim_walk"
    case samantha = "samantha"
    case daniel = "daniel"
    case karen = "karen"
    case oliver = "oliver"
    case arthur = "arthur"
    case system = "system"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ibrahimWalk:
            return "Ibrahim Walk (Sahih Int'l Studio Audio)"
        case .samantha:
            return "Samantha (American English, Female)"
        case .daniel:
            return "Daniel (British English, Male)"
        case .karen:
            return "Karen (Australian English, Female)"
        case .oliver:
            return "Oliver (British English, Male)"
        case .arthur:
            return "Arthur (British English, Male)"
        case .system:
            return "Default iOS System Voice"
        }
    }

    var shortName: String {
        switch self {
        case .ibrahimWalk: return "Ibrahim Walk"
        case .samantha: return "Samantha"
        case .daniel: return "Daniel"
        case .karen: return "Karen"
        case .oliver: return "Oliver"
        case .arthur: return "Arthur"
        case .system: return "System Voice"
        }
    }

    var subtitle: String {
        switch self {
        case .ibrahimWalk:
            return "Authentic studio voice recitation of Sahih International"
        case .samantha:
            return "Smooth American accent narration"
        case .daniel:
            return "Dignified British English narration"
        case .karen:
            return "Clear Australian English narration"
        case .oliver:
            return "Warm British English narration"
        case .arthur:
            return "Calm British English narration"
        case .system:
            return "Built-in device speech synthesis"
        }
    }

    var isStudioRecording: Bool {
        self == .ibrahimWalk
    }
}

// MARK: - Translation Narrator Engine

@MainActor
final class TranslationNarrator: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = TranslationNarrator()

    private let voiceKey = "selectedTranslationVoice"
    private let rateKey = "selectedTranslationRate"

    @Published var activeVoice: TranslationVoice = .ibrahimWalk {
        didSet {
            UserDefaults.standard.set(activeVoice.rawValue, forKey: voiceKey)
        }
    }

    @Published var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate {
        didSet {
            UserDefaults.standard.set(speechRate, forKey: rateKey)
        }
    }

    @Published var isPlaying: Bool = false
    @Published var currentAyahKey: String? = nil
    @Published var currentSurahId: Int? = nil
    @Published var currentAyahNumber: Int? = nil
    @Published var isPreviewing: Bool = false

    private var player: AVPlayer?
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var playerDidFinishObserver: Any?

    override private init() {
        super.init()

        if let savedVoiceId = UserDefaults.standard.string(forKey: voiceKey),
           let voice = TranslationVoice(rawValue: savedVoiceId) {
            self.activeVoice = voice
        } else {
            self.activeVoice = .ibrahimWalk
        }

        let savedRate = UserDefaults.standard.float(forKey: rateKey)
        if savedRate > 0 {
            self.speechRate = savedRate
        }

        speechSynthesizer.delegate = self
    }

    // MARK: - Public Methods

    func isSpeaking(surah: Int, ayah: Int) -> Bool {
        isPlaying && currentSurahId == surah && currentAyahNumber == ayah
    }

    func togglePlay(surah: Int, ayah: Int, text: String) {
        if isSpeaking(surah: surah, ayah: ayah) {
            stop()
        } else {
            speak(surah: surah, ayah: ayah, text: text)
        }
    }

    func speak(surah: Int, ayah: Int, text: String) {
        stop()

        // Pause Arabic recitation if playing to prevent collision
        RecitationPlayer.shared.pause()

        currentSurahId = surah
        currentAyahNumber = ayah
        currentAyahKey = "\(surah):\(ayah)"
        isPlaying = true
        isPreviewing = false

        configureAudioSession()

        if activeVoice == .ibrahimWalk {
            playIbrahimWalk(surah: surah, ayah: ayah)
        } else {
            speakWithTTS(text: text, voice: activeVoice)
        }
    }

    func preview(voice: TranslationVoice) {
        stop()
        activeVoice = voice
        isPreviewing = true
        isPlaying = true

        let sampleText = "In the name of Allah, the Entirely Merciful, the Especially Merciful."

        configureAudioSession()

        if voice == .ibrahimWalk {
            // Play Al-Fatihah Ayah 1 as studio sample
            playIbrahimWalk(surah: 1, ayah: 1)
        } else {
            speakWithTTS(text: sampleText, voice: voice)
        }
    }

    func stop() {
        if let observer = playerDidFinishObserver {
            NotificationCenter.default.removeObserver(observer)
            playerDidFinishObserver = nil
        }

        player?.pause()
        player = nil

        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        isPlaying = false
        currentAyahKey = nil
        currentSurahId = nil
        currentAyahNumber = nil
        isPreviewing = false
    }

    func setVoice(_ voice: TranslationVoice) {
        activeVoice = voice
    }

    // MARK: - Private Helpers

    private func configureAudioSession() {
        #if canImport(AVFoundation)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session for translation: \(error)")
        }
        #endif
    }

    private func playIbrahimWalk(surah: Int, ayah: Int) {
        let surahPad = String(format: "%03d", surah)
        let ayahPad = String(format: "%03d", ayah)
        let urlString = "https://everyayah.com/data/English/Sahih_Intnl_Ibrahim_Walk_192kbps/\(surahPad)\(ayahPad).mp3"

        guard let url = URL(string: urlString) else {
            stop()
            return
        }

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        playerDidFinishObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.stop()
        }

        player?.play()
    }

    private func speakWithTTS(text: String, voice: TranslationVoice) {
        guard !text.isEmpty else {
            stop()
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate

        if let selectedVoice = resolveVoice(for: voice) {
            utterance.voice = selectedVoice
        }

        speechSynthesizer.speak(utterance)
    }

    private func resolveVoice(for voice: TranslationVoice) -> AVSpeechSynthesisVoice? {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()

        switch voice {
        case .samantha:
            if let matched = allVoices.first(where: { $0.language.starts(with: "en-US") && $0.name.localizedCaseInsensitiveContains("Samantha") }) {
                return matched
            }
            return AVSpeechSynthesisVoice(language: "en-US")

        case .daniel:
            if let matched = allVoices.first(where: { $0.language.starts(with: "en-GB") && $0.name.localizedCaseInsensitiveContains("Daniel") }) {
                return matched
            }
            return AVSpeechSynthesisVoice(language: "en-GB")

        case .karen:
            if let matched = allVoices.first(where: { $0.language.starts(with: "en-AU") && $0.name.localizedCaseInsensitiveContains("Karen") }) {
                return matched
            }
            return AVSpeechSynthesisVoice(language: "en-AU")

        case .oliver:
            if let matched = allVoices.first(where: { $0.language.starts(with: "en-GB") && $0.name.localizedCaseInsensitiveContains("Oliver") }) {
                return matched
            }
            return AVSpeechSynthesisVoice(language: "en-GB")

        case .arthur:
            if let matched = allVoices.first(where: { $0.language.starts(with: "en-GB") && $0.name.localizedCaseInsensitiveContains("Arthur") }) {
                return matched
            }
            return AVSpeechSynthesisVoice(language: "en-GB")

        case .system, .ibrahimWalk:
            return AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier ?? "en") ?? AVSpeechSynthesisVoice(language: "en-US")
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.stop()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.stop()
        }
    }
}
