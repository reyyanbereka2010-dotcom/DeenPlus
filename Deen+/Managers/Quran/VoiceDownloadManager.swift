//
//  VoiceDownloadManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/6/26.
//

import Foundation
import Combine

@MainActor
final class VoiceDownloadManager: ObservableObject {
    static let shared = VoiceDownloadManager()

    @Published var activeDownloads: Set<String> = []
    @Published var downloadProgress: [String: Double] = [:]
    @Published var downloadedSurahKeys: Set<String> = []
    @Published var totalDiskUsageFormatted: String = "0 MB"
    @Published var isBatchDownloading: Bool = false
    @Published var batchProgress: Double = 0.0
    @Published var batchCurrentSurah: Int = 0
    @Published var batchTotalSurahs: Int = 114
    @Published var batchReciterName: String = ""

    private var batchTask: Task<Void, Never>? = nil

    private let fileManager = FileManager.default

    private var baseDownloadsFolder: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("VoiceAudioDownloads", isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    private init() {
        cleanLegacyDownloadsIfNeeded()
        refreshDownloadedIndex()
    }

    /// Clean legacy monolithic surah MP3 files that prevented per-ayah playback
    private func cleanLegacyDownloadsIfNeeded() {
        let recitersFolder = baseDownloadsFolder.appendingPathComponent("reciters", isDirectory: true)
        if let reciterDirs = try? fileManager.contentsOfDirectory(at: recitersFolder, includingPropertiesForKeys: nil) {
            for dir in reciterDirs {
                if let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                    for file in files where file.pathExtension == "mp3" {
                        try? fileManager.removeItem(at: file)
                    }
                }
            }
        }
    }

    // MARK: - Local Path Helpers

    func reciterSurahFolder(reciter: Reciter, surahId: Int) -> URL {
        let folder = baseDownloadsFolder
            .appendingPathComponent("reciters", isDirectory: true)
            .appendingPathComponent(reciter.rawValue, isDirectory: true)
            .appendingPathComponent("\(surahId)", isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    func reciterAyahURL(reciter: Reciter, surahId: Int, ayahNumber: Int) -> URL {
        reciterSurahFolder(reciter: reciter, surahId: surahId)
            .appendingPathComponent("\(ayahNumber).mp3")
    }

    func localAyahAudioURL(reciter: Reciter, surahId: Int, ayahNumber: Int) -> URL? {
        let url = reciterAyahURL(reciter: reciter, surahId: surahId, ayahNumber: ayahNumber)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func translationAyahFolder(voice: TranslationVoice, surahId: Int) -> URL {
        let folder = baseDownloadsFolder
            .appendingPathComponent("translations", isDirectory: true)
            .appendingPathComponent(voice.rawValue, isDirectory: true)
            .appendingPathComponent("\(surahId)", isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    func translationAyahURL(voice: TranslationVoice, surahId: Int, ayahNumber: Int) -> URL {
        translationAyahFolder(voice: voice, surahId: surahId)
            .appendingPathComponent("\(ayahNumber).mp3")
    }

    func localTranslationAudioURL(voice: TranslationVoice, surahId: Int, ayahNumber: Int = 1) -> URL? {
        let url = translationAyahURL(voice: voice, surahId: surahId, ayahNumber: ayahNumber)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func isReciterSurahDownloaded(reciter: Reciter, surahId: Int) -> Bool {
        downloadedSurahKeys.contains("reciter_\(reciter.rawValue)_\(surahId)")
    }

    func isTranslationSurahDownloaded(voice: TranslationVoice, surahId: Int) -> Bool {
        downloadedSurahKeys.contains("translation_\(voice.rawValue)_\(surahId)")
    }

    func isDownloading(key: String) -> Bool {
        activeDownloads.contains(key)
    }

    // MARK: - Batch Download Operations

    func startDownloadAll(reciter: Reciter) {
        guard !isBatchDownloading else { return }
        isBatchDownloading = true
        batchProgress = 0.0
        batchCurrentSurah = 1
        batchTotalSurahs = 114
        batchReciterName = reciter.shortName

        batchTask = Task { @MainActor in
            for surahId in 1...114 {
                if Task.isCancelled { break }

                self.batchCurrentSurah = surahId
                self.batchProgress = Double(surahId - 1) / 114.0

                if self.isReciterSurahDownloaded(reciter: reciter, surahId: surahId) {
                    continue
                }

                let totalAyahs = SurahMetadata.get(surahId).totalAyahs
                guard totalAyahs > 0 else { continue }

                var successAyahs = 0
                for ayah in 1...totalAyahs {
                    if Task.isCancelled { break }
                    guard let remoteURL = reciter.ayahURL(surahId: surahId, ayahNumber: ayah) else { continue }
                    let destURL = self.reciterAyahURL(reciter: reciter, surahId: surahId, ayahNumber: ayah)

                    do {
                        let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)
                        if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                            if FileManager.default.fileExists(atPath: destURL.path) {
                                try? FileManager.default.removeItem(at: destURL)
                            }
                            try FileManager.default.moveItem(at: tempURL, to: destURL)
                            successAyahs += 1
                        }
                    } catch {
                        #if DEBUG
                        print("Error downloading \(surahId):\(ayah):", error)
                        #endif
                    }
                }

                if successAyahs > 0 {
                    self.downloadedSurahKeys.insert("reciter_\(reciter.rawValue)_\(surahId)")
                }
            }

            self.isBatchDownloading = false
            self.batchProgress = 1.0
            self.refreshDownloadedIndex()
        }
    }

    func cancelBatchDownload() {
        batchTask?.cancel()
        batchTask = nil
        isBatchDownloading = false
        refreshDownloadedIndex()
    }

    // MARK: - Download Operations

    func downloadReciterSurah(reciter: Reciter, surahId: Int) {
        let key = "reciter_\(reciter.rawValue)_\(surahId)"
        guard !activeDownloads.contains(key) else { return }

        activeDownloads.insert(key)
        downloadProgress[key] = 0.05

        let totalAyahs = SurahMetadata.get(surahId).totalAyahs
        Task.detached(priority: .userInitiated) {
            var successCount = 0
            for ayah in 1...totalAyahs {
                if Task.isCancelled { break }
                guard let remoteURL = reciter.ayahURL(surahId: surahId, ayahNumber: ayah) else { continue }
                let destURL = await self.reciterAyahURL(reciter: reciter, surahId: surahId, ayahNumber: ayah)

                do {
                    let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)
                    if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                        if FileManager.default.fileExists(atPath: destURL.path) {
                            try? FileManager.default.removeItem(at: destURL)
                        }
                        try FileManager.default.moveItem(at: tempURL, to: destURL)
                        successCount += 1
                    }
                } catch {
                    #if DEBUG
                    print("Error downloading surah \(surahId) ayah \(ayah):", error)
                    #endif
                }
                let progress = Double(ayah) / Double(totalAyahs)
                await MainActor.run {
                    self.downloadProgress[key] = progress
                }
            }
            await self.finishDownload(key: key, success: successCount > 0)
        }
    }

    func downloadTranslationSurah(voice: TranslationVoice, surahId: Int) {
        let key = "translation_\(voice.rawValue)_\(surahId)"
        guard !activeDownloads.contains(key) else { return }

        activeDownloads.insert(key)
        downloadProgress[key] = 0.05

        let totalAyahs = SurahMetadata.get(surahId).totalAyahs
        Task.detached(priority: .userInitiated) {
            var successCount = 0
            for ayah in 1...totalAyahs {
                if Task.isCancelled { break }
                guard let remoteURL = voice.audioUrl(surah: surahId, ayah: ayah) else { continue }
                let destURL = await self.translationAyahURL(voice: voice, surahId: surahId, ayahNumber: ayah)

                do {
                    let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)
                    if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                        if FileManager.default.fileExists(atPath: destURL.path) {
                            try? FileManager.default.removeItem(at: destURL)
                        }
                        try FileManager.default.moveItem(at: tempURL, to: destURL)
                        successCount += 1
                    }
                } catch {}
                let progress = Double(ayah) / Double(totalAyahs)
                await MainActor.run {
                    self.downloadProgress[key] = progress
                }
            }
            await self.finishDownload(key: key, success: successCount > 0)
        }
    }

    private func finishDownload(key: String, success: Bool) {
        activeDownloads.remove(key)
        downloadProgress.removeValue(forKey: key)
        if success {
            downloadedSurahKeys.insert(key)
        }
        refreshDownloadedIndex()
    }

    // MARK: - Deletion & Storage Management

    func deleteReciterSurah(reciter: Reciter, surahId: Int) {
        let url = reciterSurahFolder(reciter: reciter, surahId: surahId)
        try? fileManager.removeItem(at: url)
        downloadedSurahKeys.remove("reciter_\(reciter.rawValue)_\(surahId)")
        refreshDownloadedIndex()
    }

    func deleteTranslationSurah(voice: TranslationVoice, surahId: Int) {
        let url = translationAyahFolder(voice: voice, surahId: surahId)
        try? fileManager.removeItem(at: url)
        downloadedSurahKeys.remove("translation_\(voice.rawValue)_\(surahId)")
        refreshDownloadedIndex()
    }

    func deleteAllDownloadedVoices() {
        try? fileManager.removeItem(at: baseDownloadsFolder)
        downloadedSurahKeys.removeAll()
        refreshDownloadedIndex()
    }

    func refreshDownloadedIndex() {
        var keys = Set<String>()
        var totalBytes: Int64 = 0

        // Scan reciters
        let recitersFolder = baseDownloadsFolder.appendingPathComponent("reciters", isDirectory: true)
        if let reciterDirs = try? fileManager.contentsOfDirectory(at: recitersFolder, includingPropertiesForKeys: nil) {
            for dir in reciterDirs {
                let reciterId = dir.lastPathComponent
                if let surahDirs = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                    for surahDir in surahDirs {
                        let surahStr = surahDir.lastPathComponent
                        if let files = try? fileManager.contentsOfDirectory(at: surahDir, includingPropertiesForKeys: [.fileSizeKey]), !files.isEmpty {
                            keys.insert("reciter_\(reciterId)_\(surahStr)")
                            for file in files {
                                if let attrs = try? fileManager.attributesOfItem(atPath: file.path),
                                   let size = attrs[.size] as? Int64 {
                                    totalBytes += size
                                }
                            }
                        }
                    }
                }
            }
        }

        // Scan translations
        let transFolder = baseDownloadsFolder.appendingPathComponent("translations", isDirectory: true)
        if let transDirs = try? fileManager.contentsOfDirectory(at: transFolder, includingPropertiesForKeys: nil) {
            for dir in transDirs {
                let voiceId = dir.lastPathComponent
                if let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey]) {
                    for file in files where file.pathExtension == "mp3" {
                        let surahStr = file.deletingPathExtension().lastPathComponent
                        keys.insert("translation_\(voiceId)_\(surahStr)")
                        if let attrs = try? fileManager.attributesOfItem(atPath: file.path),
                           let size = attrs[.size] as? Int64 {
                            totalBytes += size
                        }
                    }
                }
            }
        }

        self.downloadedSurahKeys = keys

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .file
        self.totalDiskUsageFormatted = formatter.string(fromByteCount: totalBytes)
    }
}
