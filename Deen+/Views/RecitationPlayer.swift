import Foundation
import AVFoundation
import Combine

// MARK: - Reciter and URL provider

enum Reciter: String, CaseIterable, Identifiable, Sendable {
    case alafasy = "alafasy"
    case sudais = "sudais"
    case abdulbaset = "abdulbaset"
    case ghamdi = "ghamdi"
    case muaiqly = "muaiqly"
    case husary = "husary"
    case minshawi = "minshawi"
    case shatri = "shatri"
    case rifai = "rifai"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .alafasy: return "Mishary Rashid Alafasy"
        case .sudais: return "Abdur-Rahman As-Sudais"
        case .abdulbaset: return "AbdulBaset AbdulSamad"
        case .ghamdi: return "Saad Al-Ghamdi"
        case .muaiqly: return "Maher Al-Muaiqly"
        case .husary: return "Mahmoud Khalil Al-Husary"
        case .minshawi: return "Mohamed Siddiq Al-Minshawi"
        case .shatri: return "Abu Bakr Al-Shatri"
        case .rifai: return "Hani Ar-Rifai"
        }
    }

    var shortName: String {
        switch self {
        case .alafasy: return "Alafasy"
        case .sudais: return "As-Sudais"
        case .abdulbaset: return "AbdulBaset"
        case .ghamdi: return "Al-Ghamdi"
        case .muaiqly: return "Al-Muaiqly"
        case .husary: return "Al-Husary"
        case .minshawi: return "Al-Minshawi"
        case .shatri: return "Al-Shatri"
        case .rifai: return "Ar-Rifai"
        }
    }

    /// Base path for the reciter's surah MP3 files
    var basePath: String {
        switch self {
        case .alafasy: return "https://download.quranicaudio.com/qdc/mishari_al_afasy/murattal"
        case .sudais: return "https://download.quranicaudio.com/qdc/abdurrahmaan_as_sudais/murattal"
        case .abdulbaset: return "https://download.quranicaudio.com/qdc/abdul_baset/murattal"
        case .ghamdi: return "https://server7.mp3quran.net/s_gmd"
        case .muaiqly: return "https://server12.mp3quran.net/maher"
        case .husary: return "https://download.quranicaudio.com/qdc/khalil_al_husary/murattal"
        case .minshawi: return "https://download.quranicaudio.com/qdc/siddiq_minshawi/murattal"
        case .shatri: return "https://download.quranicaudio.com/qdc/abu_bakr_shatri/murattal"
        case .rifai: return "https://download.quranicaudio.com/qdc/hani_ar_rifai/murattal"
        }
    }

    /// Returns streaming audio URL for full Surah (1...114)
    func surahURL(surahId: Int) -> URL? {
        guard (1...114).contains(surahId) else { return nil }
        switch self {
        case .ghamdi, .muaiqly:
            let num = String(format: "%03d", surahId)
            return URL(string: "\(basePath)/\(num).mp3")
        default:
            return URL(string: "\(basePath)/\(surahId).mp3")
        }
    }
}

struct RecitationProvider {
    static func surahURL(surahId: Int, reciter: Reciter = .alafasy) -> URL? {
        reciter.surahURL(surahId: surahId)
    }
}

// MARK: - Player

@MainActor
final class RecitationPlayer: ObservableObject {
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentSurahId: Int?
    @Published var activeReciter: Reciter = .alafasy

    private var player: AVPlayer?
    private var endObserver: Any?
    private let reciterStorageKey = "selectedQuranReciter"

    init() {
        if let saved = UserDefaults.standard.string(forKey: reciterStorageKey),
           let reciter = Reciter(rawValue: saved) {
            self.activeReciter = reciter
        } else {
            self.activeReciter = .alafasy
        }
    }

    deinit {
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }

    func setReciter(_ reciter: Reciter) {
        guard reciter != activeReciter else { return }
        activeReciter = reciter
        UserDefaults.standard.set(reciter.rawValue, forKey: reciterStorageKey)
        if isPlaying, let current = currentSurahId {
            playSurah(surahId: current, reciter: reciter)
        }
    }

    func togglePlay(for surahId: Int, reciter: Reciter? = nil) {
        let chosen = reciter ?? activeReciter
        if isPlaying, currentSurahId == surahId {
            pause()
        } else {
            playSurah(surahId: surahId, reciter: chosen)
        }
    }

    func playSurah(surahId: Int, reciter: Reciter? = nil) {
        let chosen = reciter ?? activeReciter
        guard let url = RecitationProvider.surahURL(surahId: surahId, reciter: chosen) else { return }
        prepareSession()
        if currentSurahId != surahId || activeReciter != chosen || player == nil {
            player = AVPlayer(url: url)
            currentSurahId = surahId
            activeReciter = chosen
        }
        player?.play()
        isPlaying = true
        observeEnd()
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    private func prepareSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            // Silently ignore session errors
        }
    }

    private func observeEnd() {
        guard let item = player?.currentItem else { return }
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            self?.isPlaying = false
        }
    }
}
