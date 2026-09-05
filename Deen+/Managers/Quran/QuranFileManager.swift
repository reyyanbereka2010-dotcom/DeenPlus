//
//  QuranFileManager.swift
//  Deen+
//

import Foundation

final class QuranFileManager {

    static let shared = QuranFileManager()

    // Serial queue to ensure file operations are thread-safe and off the main thread
    private let ioQueue = DispatchQueue(label: "com.deenplus.quranFileIO")

    private init() {}

    private var downloadsFolder: URL {

        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let folder = documents.appendingPathComponent(
            "QuranDownloads",
            isDirectory: true
        )

        if !FileManager.default.fileExists(atPath: folder.path) {

            try? FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true
            )
        }

        // Ensure the downloads folder is not backed up to iCloud
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        do {
            var mutableFolder = folder
            try mutableFolder.setResourceValues(resourceValues)
        } catch {
            #if DEBUG
            print("QuranFileManager: Failed to set do-not-backup attribute:", error)
            #endif
        }

        return folder
    }


    private func fileURL(for id: Int) -> URL {

        downloadsFolder.appendingPathComponent(
            "\(id).json"
        )
    }


    // MARK: - Save

    func saveSurah(
        id: Int,
        verses: [QuranVerse],
        completion: ((Bool) -> Void)? = nil
    ) {

        let name = SurahMetadata.get(id).englishName

        ioQueue.async { [name] in
            let surah = DownloadedQuran(
                id: id,
                name: name,
                verses: verses
            )
            var success = false
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.withoutEscapingSlashes]
                let data = try encoder.encode(surah)
                try data.write(
                    to: self.fileURL(for: id),
                    options: [.atomic, .completeFileProtection]
                )
                success = true
                #if DEBUG
                print("Successfully saved Surah \(id) (\(name)) to disk.")
                #endif
            } catch {
                #if DEBUG
                print("QuranFileManager Save Error for Surah \(id):", error)
                #endif
            }

            if let completion = completion {
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        }
    }


    // MARK: - Load

    func loadSurah(
        id: Int
    ) -> DownloadedQuran? {

        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        var result: DownloadedQuran?
        ioQueue.sync {
            do {
                let data = try Data(contentsOf: url)
                result = try JSONDecoder().decode(DownloadedQuran.self, from: data)
            } catch {
                #if DEBUG
                print("QuranFileManager Load Error for Surah \(id):", error)
                #endif
                result = nil
            }
        }
        return result
    }


    // MARK: - Get All Downloads

    func getDownloadedSurahs() -> [DownloadedQuran] {

        var items: [DownloadedQuran] = []
        ioQueue.sync {
            do {
                let files = try FileManager.default.contentsOfDirectory(
                    at: downloadsFolder,
                    includingPropertiesForKeys: nil
                )
                items = files
                    .filter { $0.pathExtension == "json" }
                    .compactMap { file in
                        guard let data = try? Data(contentsOf: file) else { return nil }
                        return try? JSONDecoder().decode(DownloadedQuran.self, from: data)
                    }
                    .sorted { $0.id < $1.id }
            } catch {
                #if DEBUG
                print("QuranFileManager Get Downloads Error:", error)
                #endif
                items = []
            }
        }
        return items
    }


    // MARK: - Delete One

    func deleteSurah(
        id: Int
    ) {

        let url = fileURL(for: id)
        ioQueue.async {
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                    #if DEBUG
                    print("Successfully deleted Surah ID \(id) from disk.")
                    #endif
                } else {
                    #if DEBUG
                    print("File already missing for Surah ID \(id).")
                    #endif
                }
            } catch {
                #if DEBUG
                print("QuranFileManager Delete Error for Surah \(id):", error)
                #endif
            }
        }
    }


    // MARK: - Delete All

    func deleteAllSurahs(completion: (() -> Void)? = nil) {
        deleteAll(completion: completion)
    }

    func deleteAll(completion: (() -> Void)? = nil) {

        ioQueue.async {
            do {
                let files = try FileManager.default.contentsOfDirectory(
                    at: self.downloadsFolder,
                    includingPropertiesForKeys: nil
                )
                for file in files {
                    try FileManager.default.removeItem(at: file)
                }
                #if DEBUG
                print("Successfully deleted all Quran downloads from disk.")
                #endif
            } catch {
                #if DEBUG
                print("QuranFileManager Delete All Error:", error)
                #endif
            }

            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }


    // MARK: - Check

    func isDownloaded(
        id: Int
    ) -> Bool {

        var exists = false
        ioQueue.sync {
            exists = FileManager.default.fileExists(atPath: fileURL(for: id).path)
        }
        return exists
    }


    // MARK: - Async variants (non-breaking additions)

    func saveSurahAsync(id: Int, verses: [QuranVerse]) async {
        await withCheckedContinuation { continuation in
            self.saveSurah(id: id, verses: verses)
            // Fire-and-forget; we resume immediately since saveSurah is async on queue
            continuation.resume()
        }
    }

    func loadSurahAsync(id: Int) async -> DownloadedQuran? {
        await withCheckedContinuation { continuation in
            let result = self.loadSurah(id: id)
            continuation.resume(returning: result)
        }
    }

    func getDownloadedSurahsAsync() async -> [DownloadedQuran] {
        await withCheckedContinuation { continuation in
            let items = self.getDownloadedSurahs()
            continuation.resume(returning: items)
        }
    }

    func deleteSurahAsync(id: Int) async {
        await withCheckedContinuation { continuation in
            self.deleteSurah(id: id)
            continuation.resume()
        }
    }

    func deleteAllAsync() async {
        await withCheckedContinuation { continuation in
            self.deleteAll()
            continuation.resume()
        }
    }

    func isDownloadedAsync(id: Int) async -> Bool {
        await withCheckedContinuation { continuation in
            let exists = self.isDownloaded(id: id)
            continuation.resume(returning: exists)
        }
    }
}
