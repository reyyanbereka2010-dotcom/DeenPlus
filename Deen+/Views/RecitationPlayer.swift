import Foundation
import AVFoundation
import Combine

// MARK: - Reciter and URL provider

enum Reciter: String, CaseIterable, Identifiable, Sendable {
    case alafasy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .alafasy: return "Mishary Alafasy"
        }
    }

    /// Base path for the reciter's surah MP3s (001.mp3 ... 114.mp3)
    var basePath: String {
        switch self {
        case .alafasy: return "https://everyayah.com/data/Alafasy_64kbps"
        }
    }
}

struct RecitationProvider {
    static func surahURL(surahId: Int, reciter: Reciter = .alafasy) -> URL? {
        guard (1...114).contains(surahId) else { return nil }
        let number = String(format: "%03d", surahId)
        return URL(string: "\(reciter.basePath)/\(number).mp3")
    }
}

// MARK: - Player

@MainActor
final class RecitationPlayer: ObservableObject {
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentSurahId: Int?

    private var player: AVPlayer?
    private var endObserver: Any?

    deinit {
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }

    func togglePlay(for surahId: Int, reciter: Reciter = .alafasy) {
        if isPlaying, currentSurahId == surahId {
            pause()
        } else {
            playSurah(surahId: surahId, reciter: reciter)
        }
    }

    func playSurah(surahId: Int, reciter: Reciter = .alafasy) {
        guard let url = RecitationProvider.surahURL(surahId: surahId, reciter: reciter) else { return }
        prepareSession()
        if currentSurahId != surahId || player == nil {
            player = AVPlayer(url: url)
            currentSurahId = surahId
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
            // Silently ignore session errors for now
        }
    }

    private func observeEnd() {
        guard let item = player?.currentItem else { return }
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            self?.isPlaying = false
        }
    }
}
