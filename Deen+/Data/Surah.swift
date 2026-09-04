import Foundation

struct Surah: Identifiable, Codable {

    let id: Int
    let name: String
    let arabicName: String
    let versesCount: Int
    let revelationPlace: String

    enum CodingKeys: String, CodingKey {
        case id
        case name = "name_simple"
        case arabicName = "name_arabic"
        case versesCount = "verses_count"
        case revelationPlace = "revelation_place"
    }
}

struct SurahResponse: Codable {
    let chapters: [Surah]
}
