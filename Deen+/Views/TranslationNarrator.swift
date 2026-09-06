//
//  TranslationNarrator.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/6/26.
//

import Foundation
import Combine
import AVFoundation

// MARK: - Available Muslim Translation Voices / Narrators

enum TranslationVoice: String, CaseIterable, Identifiable, Sendable {
    case ibrahimWalk = "ibrahim_walk"
    case shamshadAliKhan = "shamshad_ali_khan"
    case farhatHashmi = "farhat_hashmi"
    case hedayatfar = "hedayatfar"
    case besimKorkut = "besim_korkut"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ibrahimWalk:
            return "Ibrahim Walk (Sahih Int'l • English)"
        case .shamshadAliKhan:
            return "Shamshad Ali Khan (Urdu)"
        case .farhatHashmi:
            return "Dr. Farhat Hashmi (Urdu)"
        case .hedayatfar:
            return "Hedayatfar (Persian • Farsi)"
        case .besimKorkut:
            return "Besim Korkut (Bosnian)"
        }
    }

    var shortName: String {
        switch self {
        case .ibrahimWalk: return "Ibrahim Walk (EN)"
        case .shamshadAliKhan: return "Shamshad Ali (UR)"
        case .farhatHashmi: return "Dr. Farhat Hashmi (UR)"
        case .hedayatfar: return "Hedayatfar (FA)"
        case .besimKorkut: return "Besim Korkut (BS)"
        }
    }

    var languageName: String {
        switch self {
        case .ibrahimWalk: return "English"
        case .shamshadAliKhan: return "Urdu"
        case .farhatHashmi: return "Urdu"
        case .hedayatfar: return "Persian"
        case .besimKorkut: return "Bosnian"
        }
    }

    var subtitle: String {
        switch self {
        case .ibrahimWalk:
            return "Authentic studio English recitation by Ibrahim Walk"
        case .shamshadAliKhan:
            return "Clear classical Urdu translation narration"
        case .farhatHashmi:
            return "Respected female Islamic scholar & educator"
        case .hedayatfar:
            return "Traditional Persian translation recitation"
        case .besimKorkut:
            return "Authoritative Bosnian translation narration"
        }
    }

    var isStudioRecording: Bool {
        true
    }

    func audioUrl(surah: Int, ayah: Int) -> URL? {
        let surahPad = String(format: "%03d", surah)
        let ayahPad = String(format: "%03d", ayah)
        let base: String
        switch self {
        case .ibrahimWalk:
            base = "https://everyayah.com/data/English/Sahih_Intnl_Ibrahim_Walk_192kbps"
        case .shamshadAliKhan:
            base = "https://everyayah.com/data/translations/urdu_shamshad_ali_khan_46kbps"
        case .farhatHashmi:
            base = "https://everyayah.com/data/translations/urdu_farhat_hashmi"
        case .hedayatfar:
            base = "https://everyayah.com/data/translations/Fooladvand_Hedayatfar_40Kbps"
        case .besimKorkut:
            base = "https://everyayah.com/data/translations/besim_korkut_ajet_po_ajet"
        }
        return URL(string: "\(base)/\(surahPad)\(ayahPad).mp3")
    }
}

// MARK: - Translation Narrator Engine

@MainActor
final class TranslationNarrator: NSObject, ObservableObject {
    static let shared = TranslationNarrator()

    private let voiceKey = "selectedTranslationVoice"

    @Published var activeVoice: TranslationVoice = .ibrahimWalk {
        didSet {
            UserDefaults.standard.set(activeVoice.rawValue, forKey: voiceKey)
        }
    }

    @Published var isPlaying: Bool = false
    @Published var currentAyahKey: String? = nil
    @Published var currentSurahId: Int? = nil
    @Published var currentAyahNumber: Int? = nil
    @Published var isPreviewing: Bool = false

    private var player: AVPlayer?
    private var playerDidFinishObserver: Any?

    override private init() {
        super.init()

        if let savedVoiceId = UserDefaults.standard.string(forKey: voiceKey),
           let voice = TranslationVoice(rawValue: savedVoiceId) {
            self.activeVoice = voice
        } else {
            self.activeVoice = .ibrahimWalk
        }
    }

    // MARK: - Public Methods

    func isSpeaking(surah: Int, ayah: Int) -> Bool {
        isPlaying && currentSurahId == surah && currentAyahNumber == ayah
    }

    func togglePlay(surah: Int, ayah: Int, text: String = "") {
        if isSpeaking(surah: surah, ayah: ayah) {
            stop()
        } else {
            speak(surah: surah, ayah: ayah, text: text)
        }
    }

    func speak(surah: Int, ayah: Int, text: String = "") {
        stop()

        // Pause Arabic recitation if playing to prevent audio conflict
        RecitationPlayer.shared.pause()

        guard let url = activeVoice.audioUrl(surah: surah, ayah: ayah) else {
            return
        }

        currentSurahId = surah
        currentAyahNumber = ayah
        currentAyahKey = "\(surah):\(ayah)"
        isPlaying = true
        isPreviewing = false

        configureAudioSession()
        playAudio(from: url)
    }

    func preview(voice: TranslationVoice) {
        stop()
        activeVoice = voice
        isPreviewing = true
        isPlaying = true

        guard let sampleUrl = voice.audioUrl(surah: 1, ayah: 1) else {
            stop()
            return
        }

        configureAudioSession()
        playAudio(from: sampleUrl)
    }

    func stop() {
        if let observer = playerDidFinishObserver {
            NotificationCenter.default.removeObserver(observer)
            playerDidFinishObserver = nil
        }

        player?.pause()
        player = nil

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

    private func playAudio(from url: URL) {
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
}
