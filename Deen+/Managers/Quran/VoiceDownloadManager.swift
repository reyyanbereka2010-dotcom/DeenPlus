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
        refreshDownloadedIndex()
    }

    // MARK: - Local Path Helpers

    func reciterSurahURL(reciter: Reciter, surahId: Int) -> URL {
        let folder = baseDownloadsFolder
            .appendingPathComponent("reciters", isDirectory: true)
            .appendingPathComponent(reciter.rawValue, isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent("\(surahId).mp3")
    }

    func translationSurahURL(voice: TranslationVoice, surahId: Int) -> URL {
        let folder = baseDownloadsFolder
            .appendingPathComponent("translations", isDirectory: true)
            .appendingPathComponent(voice.rawValue, isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent("\(surahId).mp3")
    }

    func localSurahAudioURL(reciter: Reciter, surahId: Int) -> URL? {
        let url = reciterSurahURL(reciter: reciter, surahId: surahId)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func localTranslationAudioURL(voice: TranslationVoice, surahId: Int) -> URL? {
        let url = translationSurahURL(voice: voice, surahId: surahId)
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

                guard let remoteURL = reciter.surahURL(surahId: surahId) else { continue }
                let destURL = self.reciterSurahURL(reciter: reciter, surahId: surahId)

                do {
                    let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)
                    if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                        if FileManager.default.fileExists(atPath: destURL.path) {
                            try? FileManager.default.removeItem(at: destURL)
                        }
                        try FileManager.default.moveItem(at: tempURL, to: destURL)
                        self.downloadedSurahKeys.insert("reciter_\(reciter.rawValue)_\(surahId)")
                    }
                } catch {
                    #if DEBUG
                    print("Download error for surah \(surahId):", error)
                    #endif
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
        guard !activeDownloads.contains(key),
              let remoteURL = reciter.surahURL(surahId: surahId) else { return }

        activeDownloads.insert(key)
        downloadProgress[key] = 0.05

        let destURL = reciterSurahURL(reciter: reciter, surahId: surahId)

        Task.detached(priority: .userInitiated) {
            do {
                let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    await self.finishDownload(key: key, success: false)
                    return
                }

                if FileManager.default.fileExists(atPath: destURL.path) {
                    try? FileManager.default.removeItem(at: destURL)
                }

                try FileManager.default.moveItem(at: tempURL, to: destURL)
                await self.finishDownload(key: key, success: true)
            } catch {
                await self.finishDownload(key: key, success: false)
            }
        }
    }

    func downloadTranslationSurah(voice: TranslationVoice, surahId: Int) {
        let key = "translation_\(voice.rawValue)_\(surahId)"
        // Fall back to Ayah 1 or remote audio stream
        guard !activeDownloads.contains(key),
              let remoteURL = voice.audioUrl(surah: surahId, ayah: 1) else { return }

        activeDownloads.insert(key)
        downloadProgress[key] = 0.05

        let destURL = translationSurahURL(voice: voice, surahId: surahId)

        Task.detached(priority: .userInitiated) {
            do {
                let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    await self.finishDownload(key: key, success: false)
                    return
                }

                if FileManager.default.fileExists(atPath: destURL.path) {
                    try? FileManager.default.removeItem(at: destURL)
                }

                try FileManager.default.moveItem(at: tempURL, to: destURL)
                await self.finishDownload(key: key, success: true)
            } catch {
                await self.finishDownload(key: key, success: false)
            }
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
        let url = reciterSurahURL(reciter: reciter, surahId: surahId)
        try? fileManager.removeItem(at: url)
        downloadedSurahKeys.remove("reciter_\(reciter.rawValue)_\(surahId)")
        refreshDownloadedIndex()
    }

    func deleteTranslationSurah(voice: TranslationVoice, surahId: Int) {
        let url = translationSurahURL(voice: voice, surahId: surahId)
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
                if let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey]) {
                    for file in files where file.pathExtension == "mp3" {
                        let surahStr = file.deletingPathExtension().lastPathComponent
                        keys.insert("reciter_\(reciterId)_\(surahStr)")
                        if let attrs = try? fileManager.attributesOfItem(atPath: file.path),
                           let size = attrs[.size] as? Int64 {
                            totalBytes += size
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
