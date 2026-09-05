//
//  QuranManager.swift
//  Deen+
//

import Foundation
import Combine

@MainActor
class QuranManager: ObservableObject {

    @Published var verses: [QuranVerse] = []
    @Published var isLoading = false
    @Published var offlineError = false

    func fetchVerses(
        for surah: Int,
        surahName: String = ""
    ) async {

        verses = []
        offlineError = false
        isLoading = true

        // Load downloaded Surah first
        if let saved = QuranFileManager.shared.loadSurah(id: surah) {
            verses = saved.verses
            isLoading = false
            #if DEBUG
            print("Loaded downloaded Surah:", saved.name)
            #endif
            return
        }

        let urlString = "https://api.quran.com/api/v4/verses/by_chapter/\(surah)?fields=text_uthmani&translations=20&per_page=300"

        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                offlineError = true
                isLoading = false
                return
            }

            let responseObj = try JSONDecoder().decode(QuranResponse.self, from: data)

            let name = surahName.isEmpty ? SurahMetadata.get(surah).englishName : surahName

            verses = responseObj.verses.map { verse in
                QuranVerse(
                    id: verse.id,
                    verseKey: verse.verseKey,
                    arabic: verse.textUthmani ?? "",
                    translation: verse.translations?.first?.text
                        .replacingOccurrences(
                            of: "<sup[^>]*>.*?</sup>",
                            with: "",
                            options: .regularExpression
                        ) ?? "",
                    surahName: name
                )
            }
        } catch {
            #if DEBUG
            print("Quran API error:", error)
            #endif
            offlineError = true
        }

        isLoading = false
    }

    func downloadSurah(_ surah: Int) async -> Bool {
        guard !verses.isEmpty else {
            return false
        }

        return await withCheckedContinuation { continuation in
            QuranFileManager.shared.saveSurah(id: surah, verses: verses) { success in
                continuation.resume(returning: success)
            }
        }
    }
}
