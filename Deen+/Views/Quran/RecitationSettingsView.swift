//
//  RecitationSettingsView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/6/26.
//

import SwiftUI
import AVFoundation

struct RecitationSettingsView: View {
    @ObservedObject private var recitationPlayer = RecitationPlayer.shared
    @ObservedObject private var translationNarrator = TranslationNarrator.shared
    @ObservedObject private var downloadManager = VoiceDownloadManager.shared

    @AppStorage("quranContinuousAudio") private var continuousAudio: Bool = true
    @AppStorage("appAccentColor") private var appAccentColor: String = "emerald"

    @State private var samplePlayer: AVPlayer?
    @State private var playingSampleKey: String? = nil
    @State private var selectedSurahToDownload: Int = 1
    @State private var showDeleteAllConfirmation: Bool = false

    private var accent: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    var body: some View {
        Form {
            // MARK: - Hero Header
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [accent.opacity(0.85), Color.teal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: accent.opacity(0.3), radius: 8, x: 0, y: 3)

                        Image(systemName: "waveform.badge.mic")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }

                    Text("Recitation & Voices")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 4)
            }

            // MARK: - Arabic Reciters (Sheikhs)
            Section {
                ForEach(Reciter.allCases) { reciter in
                    let isSelected = recitationPlayer.activeReciter == reciter
                    let sampleKey = "reciter_\(reciter.rawValue)"
                    let isPlayingSample = playingSampleKey == sampleKey

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            recitationPlayer.setReciter(reciter)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Button {
                                toggleSample(key: sampleKey, url: reciter.ayahURL(surahId: 1, ayahNumber: 1))
                            } label: {
                                Image(systemName: isPlayingSample ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(isSelected ? accent : Color.secondary)
                            }
                            .buttonStyle(.plain)

                            Text(reciter.displayName)
                                .font(.subheadline.weight(isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? Color.primary : Color.secondary)

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(accent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Label("Arabic Sheikhs", systemImage: "person.wave.2.fill")
                    .foregroundStyle(accent)
            } footer: {
                Text("Tap play to preview Al-Fatihah, or tap the Sheikh name to set as your primary recitation voice.")
            }

            // MARK: - Authentic Muslim Translation Narrators
            Section {
                ForEach(TranslationVoice.allCases) { voice in
                    let isSelected = translationNarrator.activeVoice == voice
                    let sampleKey = "trans_\(voice.rawValue)"
                    let isPlayingSample = playingSampleKey == sampleKey

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            translationNarrator.setVoice(voice)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Button {
                                toggleSample(key: sampleKey, url: voice.audioUrl(surah: 1, ayah: 1))
                            } label: {
                                Image(systemName: isPlayingSample ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(isSelected ? Color.blue : Color.secondary)
                            }
                            .buttonStyle(.plain)

                            HStack(spacing: 6) {
                                Text(voice.displayName)
                                    .font(.subheadline.weight(isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)

                                Text(voice.languageName)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Color.blue.opacity(0.12), in: Capsule())
                                    .foregroundStyle(Color.blue)
                            }

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(Color.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Label("Translation Voices (100% Muslim Scholars)", systemImage: "person.crop.circle.badge.waveform")
                    .foregroundStyle(.blue)
            } footer: {
                Text("No synthetic robot text-to-speech. Features authentic human studio recordings from respected Muslim reciters.")
            }

            // MARK: - Offline Voice Audio Downloader
            Section {
                HStack {
                    Label("Downloaded Audio Size", systemImage: "internaldrive")
                    Spacer()
                    Text(downloadManager.totalDiskUsageFormatted)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Download Surah Audio for Offline Play")
                        .font(.subheadline.weight(.medium))

                    Picker("Select Surah", selection: $selectedSurahToDownload) {
                        ForEach(1...114, id: \.self) { num in
                            let meta = SurahMetadata.get(num)
                            Text("\(num). \(meta.englishName)").tag(num)
                        }
                    }
                    .pickerStyle(.menu)

                    let reciter = recitationPlayer.activeReciter
                    let isDownloaded = downloadManager.isReciterSurahDownloaded(reciter: reciter, surahId: selectedSurahToDownload)
                    let downloadKey = "reciter_\(reciter.rawValue)_\(selectedSurahToDownload)"
                    let isDownloading = downloadManager.isDownloading(key: downloadKey)

                    HStack {
                        if isDownloaded {
                            Label("Downloaded for \(reciter.shortName)", systemImage: "checkmark.circle.fill")
                                .font(.caption.bold())
                                .foregroundStyle(accent)

                            Spacer()

                            Button(role: .destructive) {
                                downloadManager.deleteReciterSurah(reciter: reciter, surahId: selectedSurahToDownload)
                            } label: {
                                Label("Delete", systemImage: "trash")
                                    .font(.caption)
                            }
                        } else if isDownloading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Downloading...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Button {
                                downloadManager.downloadReciterSurah(reciter: reciter, surahId: selectedSurahToDownload)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Download for \(reciter.shortName)")
                                }
                                .font(.caption.bold())
                                .foregroundStyle(accent)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 4)

                if downloadManager.downloadedSurahKeys.count > 0 {
                    Button(role: .destructive) {
                        showDeleteAllConfirmation = true
                    } label: {
                        Label("Delete All Offline Voice Audio", systemImage: "trash")
                    }
                    .confirmationDialog("Clear all voice downloads?", isPresented: $showDeleteAllConfirmation, titleVisibility: .visible) {
                        Button("Delete All Voice Audio", role: .destructive) {
                            downloadManager.deleteAllDownloadedVoices()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will remove all downloaded voice and recitation audio to reclaim disk space.")
                    }
                }
            } header: {
                Label("Offline Voice Audio Downloads", systemImage: "arrow.down.circle.fill")
                    .foregroundStyle(Color.indigo)
            } footer: {
                Text("Downloaded audio files play automatically without requiring WiFi or cellular data.")
            }

            // MARK: - Playback Settings
            Section {
                Toggle("Continuous Ayah Playback", isOn: $continuousAudio)
            } header: {
                Label("Playback Options", systemImage: "slider.horizontal.3")
            } footer: {
                Text("When enabled, audio automatically advances to the next verse after the current one completes.")
            }
        }
        .navigationTitle("Recitation & Voices")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            stopSample()
        }
    }

    // MARK: - Sample Audio Helpers

    private func toggleSample(key: String, url: URL?) {
        if playingSampleKey == key {
            stopSample()
            return
        }

        stopSample()
        guard let url = url else { return }

        playingSampleKey = key
        let item = AVPlayerItem(url: url)
        samplePlayer = AVPlayer(playerItem: item)

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [self] _ in
            self.stopSample()
        }

        samplePlayer?.play()
    }

    private func stopSample() {
        samplePlayer?.pause()
        samplePlayer = nil
        playingSampleKey = nil
    }
}
