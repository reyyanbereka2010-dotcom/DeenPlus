import Foundation

// MARK: - RevelationPlace

enum RevelationPlace: String, Codable, CaseIterable, Sendable {
    case meccan
    case medinan

    var localizedName: String {
        switch self {
        case .meccan: return "Meccan"
        case .medinan: return "Medinan"
        }
    }

    /// A simple symbol hint that can be used in UI
    var symbol: String { "circle.fill" }
}

// MARK: - SurahMeta

struct SurahMeta: Identifiable, Hashable, Codable, Sendable {
    let id: Int
    let arabicName: String
    let englishName: String
    let transliteration: String
    let ayahCount: Int
    let revelationPlace: RevelationPlace

    // MARK: Derived UI helpers

    var badgeText: String { revelationPlace.localizedName }

    /// SFSymbol name for use in SwiftUI/Image
    var systemImage: String { revelationPlace.symbol }

    /// A display title combining number and English name
    var displayTitle: String { "\(id). \(englishName)" }

    /// A short subtitle commonly shown under the title
    var subtitle: String { "\(transliteration) • \(badgeText) • \(ayahCount) ayahs" }
}

// MARK: - QuranData

struct QuranData: Sendable {
    /// Primary source: JSON resource bundled with the app
    private static let resourceFileName = "QuranSurahs"
    private static let resourceFileExtension = "json"

    /// In-memory fallback (subset) used only if the JSON resource is missing or fails to decode
    private static let fallbackSurahs: [SurahMeta] = [
        SurahMeta(id: 1, arabicName: "الفاتحة", englishName: "The Opening", transliteration: "Al-Fātiḥah", ayahCount: 7, revelationPlace: .meccan),
        SurahMeta(id: 2, arabicName: "البقرة", englishName: "The Cow", transliteration: "Al-Baqarah", ayahCount: 286, revelationPlace: .medinan),
        SurahMeta(id: 3, arabicName: "آل عمران", englishName: "The Family of Imran", transliteration: "Āl ‘Imrān", ayahCount: 200, revelationPlace: .medinan),
        SurahMeta(id: 4, arabicName: "النساء", englishName: "The Women", transliteration: "An-Nisā’", ayahCount: 176, revelationPlace: .medinan),
        SurahMeta(id: 5, arabicName: "المائدة", englishName: "The Table Spread", transliteration: "Al-Mā’idah", ayahCount: 120, revelationPlace: .medinan),
        SurahMeta(id: 6, arabicName: "الأنعام", englishName: "The Cattle", transliteration: "Al-An‘ām", ayahCount: 165, revelationPlace: .meccan),
        SurahMeta(id: 7, arabicName: "الأعراف", englishName: "The Heights", transliteration: "Al-A‘rāf", ayahCount: 206, revelationPlace: .meccan),
        SurahMeta(id: 8, arabicName: "الأنفال", englishName: "The Spoils of War", transliteration: "Al-Anfāl", ayahCount: 75, revelationPlace: .medinan),
        SurahMeta(id: 9, arabicName: "التوبة", englishName: "The Repentance", transliteration: "At-Tawbah", ayahCount: 129, revelationPlace: .medinan),
        SurahMeta(id: 10, arabicName: "يونس", englishName: "Jonah", transliteration: "Yūnus", ayahCount: 109, revelationPlace: .meccan)
    ]

    /// Lazily loaded catalog. Reads JSON once and caches it.
    private static let _allSurahs: [SurahMeta] = {
        guard let url = Bundle.main.url(forResource: resourceFileName, withExtension: resourceFileExtension) else {
            return fallbackSurahs
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([SurahMeta].self, from: data)
            // Validate count and ordering
            if decoded.count == 114, decoded.map({ $0.id }) == Array(1...114) {
                return decoded
            } else {
                return decoded.isEmpty ? fallbackSurahs : decoded.sorted { $0.id < $1.id }
            }
        } catch {
            return fallbackSurahs
        }
    }()

    /// Public accessor for the catalog
    static var allSurahs: [SurahMeta] { _allSurahs }

    // MARK: - Lookup

    static func surah(by id: Int) -> SurahMeta? {
        allSurahs.first { $0.id == id }
    }

    static func surah(byEnglishName name: String) -> SurahMeta? {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allSurahs.first { $0.englishName.lowercased() == key || $0.transliteration.lowercased() == key }
    }

    static func search(_ query: String) -> [SurahMeta] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return allSurahs }
        let key = q.lowercased()
        return allSurahs.filter { surah in
            surah.englishName.lowercased().contains(key)
            || surah.transliteration.lowercased().contains(key)
            || surah.arabicName.contains(q)
            || String(surah.id) == key
        }
    }

    // MARK: - Filters

    static func meccanSurahs() -> [SurahMeta] { allSurahs.filter { $0.revelationPlace == .meccan } }
    static func medinanSurahs() -> [SurahMeta] { allSurahs.filter { $0.revelationPlace == .medinan } }

    // MARK: - Safe access

    static func contains(surahId: Int) -> Bool { allSurahs.contains { $0.id == surahId } }

    static func index(of surahId: Int) -> Int? { allSurahs.firstIndex { $0.id == surahId } }

    // MARK: - Placeholder Ayahs

    /// Placeholder function returning ayah text placeholders for a given surahId.
    /// Replace with real Quran text fetch logic later.
    static func placeholderAyahs(for surahId: Int) -> [String] {
        guard let surah = surah(by: surahId), surah.ayahCount > 0 else { return [] }
        return (1...surah.ayahCount).map { ayah in
            "\(surah.id):\(ayah) — \(surah.transliteration) • Ayah \(ayah)"
        }
    }

    /// A concise preview snippet for a surah
    static func previewLine(for surahId: Int) -> String? {
        guard let surah = surah(by: surahId) else { return nil }
        return "\(surah.displayTitle) — \(surah.subtitle)"
    }
}

// MARK: - Sample/Preview helpers

extension QuranData {
    /// A small subset of surahs for previews or unit tests
    static var sample: [SurahMeta] { Array(allSurahs.prefix(3)) }
}
