//
//  QuranStorageManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import Foundation

final class QuranStorageManager {

    static let shared = QuranStorageManager()

    private let lock = NSLock()
    private var cachedBookmarks: [QuranVerse]? = nil
    private let ioQueue = DispatchQueue(label: "com.deenplus.bookmarks.io", qos: .utility)

    private init() {
        // Preload bookmarks into memory cache on initial access
        _ = loadBookmarks()
    }

    private var bookmarksFile: URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        return documents.appendingPathComponent("Bookmarks.json")
    }

    // MARK: - Bookmarks

    func saveBookmarks(_ verses: [QuranVerse]) {
        lock.lock()
        cachedBookmarks = verses
        lock.unlock()

        ioQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try JSONEncoder().encode(verses)
                try data.write(to: self.bookmarksFile, options: .atomic)
                #if DEBUG
                print("Saved bookmarks:", verses.count)
                #endif
            } catch {
                #if DEBUG
                print("Bookmark save error:", error)
                #endif
            }
        }
    }

    func loadBookmarks() -> [QuranVerse] {
        lock.lock()
        if let cached = cachedBookmarks {
            lock.unlock()
            return cached
        }
        lock.unlock()

        guard let data = try? Data(contentsOf: bookmarksFile) else {
            lock.lock()
            cachedBookmarks = []
            lock.unlock()
            return []
        }

        do {
            let verses = try JSONDecoder().decode([QuranVerse].self, from: data)
            lock.lock()
            cachedBookmarks = verses
            lock.unlock()
            return verses
        } catch {
            #if DEBUG
            print("Bookmark load error: \(error). Data may be corrupted.")
            #endif
            lock.lock()
            cachedBookmarks = []
            lock.unlock()
            return []
        }
    }

    func isBookmarked(surahId: Int, ayahNumber: Int) -> Bool {
        lock.lock()
        let bookmarks = cachedBookmarks ?? loadBookmarks()
        lock.unlock()
        return bookmarks.contains { $0.surah == surahId && $0.ayah == ayahNumber }
    }

    func removeBookmark(surahId: Int, ayahNumber: Int) {
        var bookmarks = loadBookmarks()
        bookmarks.removeAll { $0.surah == surahId && $0.ayah == ayahNumber }
        saveBookmarks(bookmarks)
    }

    func saveBookmark(_ verse: QuranVerse) {
        var bookmarks = loadBookmarks()
        if !bookmarks.contains(where: { $0.surah == verse.surah && $0.ayah == verse.ayah }) {
            bookmarks.append(verse)
            saveBookmarks(bookmarks)
        }
    }

    func deleteAllBookmarks() {
        lock.lock()
        cachedBookmarks = []
        lock.unlock()

        ioQueue.async { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.removeItem(at: self.bookmarksFile)
            #if DEBUG
            print("Deleted all bookmarks")
            #endif
        }
    }

    // MARK: - Downloads

    func saveSurah(_ surah: Int, verses: [QuranVerse]) {
        QuranFileManager.shared.saveSurah(
            id: surah,
            verses: verses
        )
    }

    func getDownloadedSurahs() -> [DownloadedQuran] {
        QuranFileManager.shared.getDownloadedSurahs()
    }

    func isSurahDownloaded(_ surah: Int) -> Bool {
        QuranFileManager.shared.isDownloaded(id: surah)
    }

    func deleteSurah(_ surah: Int) {
        QuranFileManager.shared.deleteSurah(id: surah)
        #if DEBUG
        print("Deleted offline Surah:", surah)
        #endif
    }

    func deleteAllDownloads() {
        QuranFileManager.shared.deleteAll()
    }
}
