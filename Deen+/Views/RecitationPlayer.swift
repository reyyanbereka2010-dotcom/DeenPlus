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

    /// EveryAyah CDN folder name for per-verse recitation
    var everyAyahFolder: String {
        switch self {
        case .alafasy: return "Alafasy_128kbps"
        case .sudais: return "Abdurrahmaan_As-Sudais_192kbps"
        case .abdulbaset: return "Abdul_Basit_Murattal_192kbps"
        case .ghamdi: return "Ghamadi_40kbps"
        case .muaiqly: return "Maher_AlMuaiqly_64kbps"
        case .husary: return "Husary_128kbps"
        case .minshawi: return "Minshawy_Murattal_128kbps"
        case .shatri: return "Abu_Bakr_Ash-Shaatree_128kbps"
        case .rifai: return "Hani_Rifai_192kbps"
        }
    }

    /// Base path for the reciter's full surah MP3 files
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

    /// Returns streaming audio URL for an individual Ayah (e.g. Surah 1, Ayah 1 -> 001001.mp3)
    func ayahURL(surahId: Int, ayahNumber: Int) -> URL? {
        guard (1...114).contains(surahId), ayahNumber > 0 else { return nil }
        let sss = String(format: "%03d", surahId)
        let aaa = String(format: "%03d", ayahNumber)
        return URL(string: "https://everyayah.com/data/\(everyAyahFolder)/\(sss)\(aaa).mp3")
    }
}

struct RecitationProvider {
    static func surahURL(surahId: Int, reciter: Reciter = .alafasy) -> URL? {
        reciter.surahURL(surahId: surahId)
    }

    static func ayahURL(surahId: Int, ayahNumber: Int, reciter: Reciter = .alafasy) -> URL? {
        reciter.ayahURL(surahId: surahId, ayahNumber: ayahNumber)
    }
}

// MARK: - Player

@MainActor
final class RecitationPlayer: ObservableObject {
    static let shared = RecitationPlayer()

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentSurahId: Int?
    @Published private(set) var currentAyahNumber: Int?
    @Published var activeReciter: Reciter = .alafasy

    private var player: AVPlayer?
    private var endObserver: Any?
    private var errorObserver: Any?
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
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        if let errorObserver {
            NotificationCenter.default.removeObserver(errorObserver)
        }
    }

    private func cleanupObservers() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if let errorObserver {
            NotificationCenter.default.removeObserver(errorObserver)
            self.errorObserver = nil
        }
    }

    func setReciter(_ reciter: Reciter) {
        guard reciter != activeReciter else { return }
        activeReciter = reciter
        UserDefaults.standard.set(reciter.rawValue, forKey: reciterStorageKey)
        if isPlaying {
            if let ayah = currentAyahNumber, let surah = currentSurahId {
                playAyah(surahId: surah, ayahNumber: ayah, reciter: reciter)
            } else if let surah = currentSurahId {
                playSurah(surahId: surah, reciter: reciter)
            }
        }
    }

    func isPlayingAyah(surahId: Int, ayahNumber: Int) -> Bool {
        isPlaying && currentSurahId == surahId && currentAyahNumber == ayahNumber
    }

    func isPlayingSurah(surahId: Int) -> Bool {
        isPlaying && currentSurahId == surahId && currentAyahNumber == nil
    }

    func togglePlayAyah(surahId: Int, ayahNumber: Int, reciter: Reciter? = nil) {
        if isPlayingAyah(surahId: surahId, ayahNumber: ayahNumber) {
            pause()
        } else {
            playAyah(surahId: surahId, ayahNumber: ayahNumber, reciter: reciter)
        }
    }

    func playAyah(surahId: Int, ayahNumber: Int, reciter: Reciter? = nil) {
        let chosen = reciter ?? activeReciter
        guard let url = RecitationProvider.ayahURL(surahId: surahId, ayahNumber: ayahNumber, reciter: chosen) else { return }
        prepareSession()
        cleanupObservers()

        currentSurahId = surahId
        currentAyahNumber = ayahNumber
        activeReciter = chosen

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.play()
        isPlaying = true
        observeEnd()
    }

    func togglePlay(for surahId: Int, reciter: Reciter? = nil) {
        let chosen = reciter ?? activeReciter
        if isPlayingSurah(surahId: surahId) {
            pause()
        } else {
            playSurah(surahId: surahId, reciter: chosen)
        }
    }

    func playSurah(surahId: Int, reciter: Reciter? = nil) {
        let chosen = reciter ?? activeReciter
        guard let url = RecitationProvider.surahURL(surahId: surahId, reciter: chosen) else { return }
        prepareSession()
        cleanupObservers()

        currentSurahId = surahId
        currentAyahNumber = nil
        activeReciter = chosen

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.play()
        isPlaying = true
        observeEnd()
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        currentAyahNumber = nil
        cleanupObservers()
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
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.isPlaying = false
            self.currentAyahNumber = nil
        }
        errorObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.isPlaying = false
            self.currentAyahNumber = nil
        }
    }
}
