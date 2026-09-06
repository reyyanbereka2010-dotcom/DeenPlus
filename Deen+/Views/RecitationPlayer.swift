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
    @Published private(set) var isContinuousPlayback: Bool = false
    @Published var activeReciter: Reciter = .alafasy
    @Published var playbackSpeed: Float = 1.0
    @Published var repeatCount: Int = 1
    @Published var sleepTimerRemainingMinutes: Int = 0

    private var currentAyahPlayCount: Int = 1
    private var sleepTimerTask: Task<Void, Never>? = nil

    private(set) var totalAyahsForCurrentSurah: Int = 0
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
        let speed = UserDefaults.standard.float(forKey: "quranAudioPlaybackSpeed")
        if speed >= 0.5 && speed <= 2.0 {
            self.playbackSpeed = speed
        }
        let repeats = UserDefaults.standard.integer(forKey: "quranAudioRepeatCount")
        if repeats > 0 {
            self.repeatCount = repeats
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

    func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        UserDefaults.standard.set(speed, forKey: "quranAudioPlaybackSpeed")
        if isPlaying {
            player?.rate = speed
        }
    }

    func setRepeatCount(_ count: Int) {
        repeatCount = count
        UserDefaults.standard.set(count, forKey: "quranAudioRepeatCount")
    }

    func setSleepTimer(minutes: Int) {
        sleepTimerTask?.cancel()
        sleepTimerRemainingMinutes = minutes
        guard minutes > 0 else { return }

        sleepTimerTask = Task { @MainActor in
            var remaining = minutes * 60
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                remaining -= 1
                self.sleepTimerRemainingMinutes = max(0, (remaining + 59) / 60)
            }
            self.pause()
            self.sleepTimerRemainingMinutes = 0
        }
    }

    func setReciter(_ reciter: Reciter) {
        guard reciter != activeReciter else { return }
        activeReciter = reciter
        UserDefaults.standard.set(reciter.rawValue, forKey: reciterStorageKey)
        if isPlaying, let surah = currentSurahId, let ayah = currentAyahNumber {
            playAyahInternal(surahId: surah, ayahNumber: ayah, continuous: isContinuousPlayback, reciter: reciter)
        }
    }

    func isPlayingAyah(surahId: Int, ayahNumber: Int) -> Bool {
        isPlaying && currentSurahId == surahId && currentAyahNumber == ayahNumber
    }

    func isPlayingSurah(surahId: Int) -> Bool {
        isPlaying && currentSurahId == surahId && isContinuousPlayback
    }

    func togglePlayAyah(surahId: Int, ayahNumber: Int, reciter: Reciter? = nil) {
        if isPlayingAyah(surahId: surahId, ayahNumber: ayahNumber) {
            pause()
        } else if !isPlaying && currentSurahId == surahId && currentAyahNumber == ayahNumber, let player = player {
            player.play()
            isPlaying = true
        } else {
            playAyah(surahId: surahId, ayahNumber: ayahNumber, reciter: reciter)
        }
    }

    func playAyah(surahId: Int, ayahNumber: Int, reciter: Reciter? = nil) {
        isContinuousPlayback = false
        playAyahInternal(surahId: surahId, ayahNumber: ayahNumber, continuous: false, reciter: reciter)
    }

    func togglePlay(for surahId: Int, startAyah: Int = 1, totalAyahs: Int? = nil, reciter: Reciter? = nil) {
        let chosen = reciter ?? activeReciter
        if isPlaying && currentSurahId == surahId && isContinuousPlayback {
            pause()
        } else if !isPlaying && currentSurahId == surahId && isContinuousPlayback, let player = player {
            player.play()
            isPlaying = true
        } else {
            playSurah(surahId: surahId, startAyah: startAyah, totalAyahs: totalAyahs, reciter: chosen)
        }
    }

    func playSurah(surahId: Int, startAyah: Int = 1, totalAyahs: Int? = nil, reciter: Reciter? = nil) {
        let chosen = reciter ?? activeReciter
        let total = totalAyahs ?? SurahMetadata.get(surahId).totalAyahs
        totalAyahsForCurrentSurah = total > 0 ? total : 286
        isContinuousPlayback = true
        playAyahInternal(surahId: surahId, ayahNumber: startAyah, continuous: true, reciter: chosen)
    }

    func nextAyah() {
        guard let surah = currentSurahId, let current = currentAyahNumber else { return }
        if current < totalAyahsForCurrentSurah {
            playAyahInternal(surahId: surah, ayahNumber: current + 1, continuous: isContinuousPlayback, reciter: activeReciter)
        }
    }

    func previousAyah() {
        guard let surah = currentSurahId, let current = currentAyahNumber else { return }
        if current > 1 {
            playAyahInternal(surahId: surah, ayahNumber: current - 1, continuous: isContinuousPlayback, reciter: activeReciter)
        }
    }

    private func playAyahInternal(surahId: Int, ayahNumber: Int, continuous: Bool, reciter: Reciter? = nil) {
        let chosen = reciter ?? activeReciter
        let audioUrl: URL?
        if let local = VoiceDownloadManager.shared.localAyahAudioURL(reciter: chosen, surahId: surahId, ayahNumber: ayahNumber) {
            audioUrl = local
        } else {
            audioUrl = RecitationProvider.ayahURL(surahId: surahId, ayahNumber: ayahNumber, reciter: chosen)
        }
        guard let url = audioUrl else {
            stop()
            return
        }
        prepareSession()
        cleanupObservers()

        currentSurahId = surahId
        currentAyahNumber = ayahNumber
        isContinuousPlayback = continuous
        activeReciter = chosen

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.playImmediately(atRate: playbackSpeed)
        isPlaying = true
        observeEnd()
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.playImmediately(atRate: playbackSpeed)
        isPlaying = true
    }

    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        isContinuousPlayback = false
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
            if self.repeatCount == 0 || self.currentAyahPlayCount < self.repeatCount {
                self.currentAyahPlayCount += 1
                self.player?.seek(to: .zero)
                self.player?.playImmediately(atRate: self.playbackSpeed)
                return
            }
            self.currentAyahPlayCount = 1

            if self.isContinuousPlayback,
               let surah = self.currentSurahId,
               let currentAyah = self.currentAyahNumber,
               currentAyah < self.totalAyahsForCurrentSurah {
                let nextAyah = currentAyah + 1
                self.playAyahInternal(surahId: surah, ayahNumber: nextAyah, continuous: true, reciter: self.activeReciter)
            } else {
                self.isPlaying = false
                self.isContinuousPlayback = false
                self.currentAyahNumber = nil
            }
        }
        errorObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.isPlaying = false
            self.isContinuousPlayback = false
            self.currentAyahNumber = nil
        }
    }
}
