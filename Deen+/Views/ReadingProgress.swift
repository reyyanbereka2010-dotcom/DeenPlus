import Foundation
import Combine

struct ReadingProgress: Codable, Equatable, Sendable {
    let surahId: Int
    let ayah: Int
}

@MainActor
final class ReadingProgressStore: ObservableObject {
    @Published private(set) var progress: ReadingProgress?

    private let surahKey = "lastSurahId"
    private let ayahKey = "lastAyah"

    init() {
        load()
    }

    func update(surahId: Int, ayah: Int) {
        let p = ReadingProgress(surahId: surahId, ayah: ayah)
        progress = p
        UserDefaults.standard.set(surahId, forKey: surahKey)
        UserDefaults.standard.set(ayah, forKey: ayahKey)
    }

    func clear() {
        progress = nil
        UserDefaults.standard.removeObject(forKey: surahKey)
        UserDefaults.standard.removeObject(forKey: ayahKey)
    }

    private func load() {
        let surahId = UserDefaults.standard.integer(forKey: surahKey)
        let ayah = UserDefaults.standard.integer(forKey: ayahKey)
        if surahId > 0, ayah > 0 {
            progress = ReadingProgress(surahId: surahId, ayah: ayah)
        }
    }
}

