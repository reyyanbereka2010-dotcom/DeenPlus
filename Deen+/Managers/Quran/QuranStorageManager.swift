//
//  QuranStorageManager.swift
//  Deen+
//

import Foundation


final class QuranStorageManager {

    static let shared = QuranStorageManager()

    private init() {}



    private var bookmarksFile: URL {

        let documents =
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]


        return documents.appendingPathComponent(
            "Bookmarks.json"
        )
    }



    // MARK: - Bookmarks


    func saveBookmarks(
        _ verses: [QuranVerse]
    ) {

        do {

            let data =
            try JSONEncoder()
                .encode(verses)


            try data.write(
                to: bookmarksFile,
                options: .atomic
            )


            #if DEBUG
            print(
                "Saved bookmarks:",
                verses.count
            )
            #endif

        } catch {
            // In debug, print error to help diagnose issues during development.
            #if DEBUG
            print(
                "Bookmark save error:",
                error
            )
            #endif
            // Errors are silently ignored in release builds to avoid crashing the app.
        }
    }



    func loadBookmarks() -> [QuranVerse] {

        guard let data =
                try? Data(
                    contentsOf: bookmarksFile
                )
        else {

            return []
        }


        do {
            let verses = try JSONDecoder().decode([QuranVerse].self, from: data)
            return verses
        } catch {
            // Decoding failed, possibly due to corrupted or malformed data.
            // Return empty array to avoid crashing.
            // In debug builds, print the error to assist debugging.
            #if DEBUG
            print("Bookmark load error: \(error). Data may be corrupted.")
            #endif
            return []
        }
    }



    func deleteAllBookmarks() {

        try? FileManager.default.removeItem(
            at: bookmarksFile
        )


        #if DEBUG
        print(
            "Deleted all bookmarks"
        )
        #endif
    }



    // MARK: - Downloads


    func saveSurah(
        _ surah: Int,
        verses: [QuranVerse]
    ) {

        QuranFileManager.shared.saveSurah(
            id: surah,
            verses: verses
        )
    }



    func getDownloadedSurahs() -> [DownloadedQuran] {

        QuranFileManager.shared
            .getDownloadedSurahs()
    }



    func isSurahDownloaded(
        _ surah: Int
    ) -> Bool {

        QuranFileManager.shared
            .isDownloaded(
                id: surah
            )
    }



    func deleteSurah(
        _ surah: Int
    ) {

        QuranFileManager.shared
            .deleteSurah(
                id: surah
            )


        #if DEBUG
        print(
            "Deleted offline Surah:",
            surah
        )
        #endif
    }



    func deleteAllDownloads() {

        QuranFileManager.shared
            .deleteAll()
    }
}

/*
 Error Handling Notes:

 - saveBookmarks catches encoding/writing errors and prints diagnostics in debug builds only.
   In release, errors are silently ignored to prevent crashes, but this could be improved with user feedback.

 - loadBookmarks returns an empty array if data is missing or corrupted.
   Decoding errors are logged in debug builds to help identify data corruption issues.
   Future improvements might include data validation, recovery, or notifying users of corrupted data.
*/
