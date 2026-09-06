//
//  QuranVerse.swift
//  Deen+
//

import Foundation


struct QuranVerse: Identifiable, Codable, Equatable {

    let id: Int
    let verseKey: String
    let arabic: String
    let translation: String

    // New: saves the real Surah name for bookmarks
    var surahName: String?

    var surah: Int {
        Int(verseKey.split(separator: ":").first ?? "1") ?? 1
    }

    var ayah: Int {
        Int(verseKey.split(separator: ":").last ?? "1") ?? 1
    }

    init(
        id: Int,
        verseKey: String,
        arabic: String,
        translation: String,
        surahName: String? = nil
    ) {
        self.id = id
        self.verseKey = verseKey
        self.arabic = arabic
        self.translation = translation
        self.surahName = surahName
    }
}




struct QuranResponse: Codable {

    let verses: [QuranAPIVerse]

}



struct QuranAPIVerse: Codable {

    let id: Int
    let verseKey: String
    let textUthmani: String?
    let translations: [Translation]?

    enum CodingKeys: String, CodingKey {

        case id
        case verseKey = "verse_key"
        case textUthmani = "text_uthmani"
        case translations

    }

}



struct Translation: Codable {

    let text: String

}
