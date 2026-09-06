//
//  SettingsView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var prayerManager: PrayerManager
    @ObservedObject private var translationNarrator = TranslationNarrator.shared
    @ObservedObject private var recitationPlayer = RecitationPlayer.shared

    @State private var downloadedCount = 0
    @State private var bookmarkCount = 0

    @State private var showClearDownloads = false
    @State private var showClearBookmarks = false

    @AppStorage("appTheme")
    private var appTheme = "System"
    @AppStorage("menuBarStyle")
    private var menuBarStyle: String = "pill"

    @AppStorage("prayerNotificationsEnabled")
    private var prayerNotificationsEnabled: Bool = false

    @AppStorage("tasbih_haptic_feedback")
    private var tasbihHapticEnabled: Bool = true

    @AppStorage("quranArabicFontSize")
    private var quranArabicFontSize: Double = 26

    @AppStorage("quranTranslationFontSize")
    private var quranTranslationFontSize: Double = 16

    @AppStorage("quranShowTranslation")
    private var quranShowTranslation: Bool = true

    @AppStorage("quranReadingTheme")
    private var quranReadingTheme: String = "standard"

    @AppStorage("quranKeepScreenAwake")
    private var quranKeepScreenAwake: Bool = true

    @AppStorage("selectedQuranReciter")
    private var selectedQuranReciter: String = Reciter.alafasy.rawValue

    var body: some View {
        NavigationStack {
            Form {
                // Header Hero Brand Banner
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.8), Color.teal],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 58, height: 58)
                                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 3)

                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text("Deen+")
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)

                                Text("v1.1.7")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.14), in: Capsule())
                                    .foregroundStyle(.green)
                            }

                            Text("Your Daily Islamic Companion & Quran Reader")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // MARK: - Quran & Audio
                Section {
                    // Sheikh Selection
                    Picker(selection: $selectedQuranReciter) {
                        ForEach(Reciter.allCases) { reciter in
                            Text(reciter.displayName).tag(reciter.rawValue)
                        }
                    } label: {
                        Label("Sheikh (Arabic)", systemImage: "person.wave.2.fill")
                    }
                    .onChange(of: selectedQuranReciter) { newRaw in
                        if let rec = Reciter(rawValue: newRaw) {
                            recitationPlayer.setReciter(rec)
                        }
                    }

                    // Translation Voice Selection
                    Picker(selection: $translationNarrator.activeVoice) {
                        ForEach(TranslationVoice.allCases) { voice in
                            Text(voice.displayName).tag(voice)
                        }
                    } label: {
                        Label("Translation Voice", systemImage: "person.crop.circle.badge.waveform")
                    }

                    // Translation Voice Preview Button
                    Button {
                        if translationNarrator.isPlaying && translationNarrator.isPreviewing {
                            translationNarrator.stop()
                        } else {
                            translationNarrator.preview(voice: translationNarrator.activeVoice)
                        }
                    } label: {
                        HStack {
                            Image(systemName: (translationNarrator.isPlaying && translationNarrator.isPreviewing) ? "stop.circle.fill" : "play.circle.fill")
                                .foregroundStyle(.blue)
                            Text((translationNarrator.isPlaying && translationNarrator.isPreviewing) ? "Stop Voice Sample" : "Sample \(translationNarrator.activeVoice.shortName)'s Voice")
                                .foregroundStyle(.blue)
                            Spacer()
                            if translationNarrator.activeVoice.isStudioRecording {
                                Text("Studio Recitation")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.12), in: Capsule())
                            }
                        }
                    }

                    // Arabic Font Size
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Arabic Font Size")
                            Spacer()
                            Text("\(Int(quranArabicFontSize)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $quranArabicFontSize, in: 18...38, step: 2)
                    }
                    .padding(.vertical, 4)

                    // English Translation Font Size
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Translation Font Size")
                            Spacer()
                            Text("\(Int(quranTranslationFontSize)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $quranTranslationFontSize, in: 13...24, step: 1)
                    }
                    .padding(.vertical, 4)

                    // Reading Theme
                    Picker("Reader Theme", selection: $quranReadingTheme) {
                        Text("Standard").tag("standard")
                        Text("Warm Sepia").tag("sepia")
                        Text("AMOLED Night").tag("black")
                    }

                    Toggle("Show English Translation", isOn: $quranShowTranslation)
                    Toggle("Keep Screen Awake in Reader", isOn: $quranKeepScreenAwake)

                    NavigationLink {
                        BookmarksView()
                    } label: {
                        HStack {
                            Label("Saved Bookmarks", systemImage: "bookmark.fill")
                            Spacer()
                            Text("\(bookmarkCount)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        DownloadsView()
                    } label: {
                        HStack {
                            Label("Offline Downloads", systemImage: "arrow.down.circle.fill")
                            Spacer()
                            Text("\(downloadedCount)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    SettingsIconLabel(title: "Holy Quran & Recitation", icon: "book.fill", color: .green)
                } footer: {
                    Text("Includes studio recordings by Sheikhs and authentic Sahih International translation narration by Ibrahim Walk.")
                }

                // MARK: - Prayer Notifications
                Section {
                    Toggle("Prayer Notifications", isOn: $prayerNotificationsEnabled)
                        .onChange(of: prayerNotificationsEnabled) { newValue in
                            if newValue {
                                NotificationManager.shared.requestPermission()
                                NotificationManager.shared.schedulePrayerNotifications(prayerTimes: prayerManager.prayerTimes)
                            } else {
                                NotificationManager.shared.cancelPrayerNotifications()
                            }
                        }

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Adhan Sound & Alerts", systemImage: "speaker.wave.3.fill")
                    }
                } header: {
                    SettingsIconLabel(title: "Prayer Notifications", icon: "bell.badge.fill", color: .red)
                } footer: {
                    PrayerNotifSummaryFooter()
                }

                // MARK: - Prayer Calculation
                Section {
                    Toggle("Auto-Detect by Location", isOn: $prayerManager.autoDetectSettings)

                    if prayerManager.autoDetectSettings {
                        HStack {
                            Text("Method")
                            Spacer()
                            Text(prayerManager.currentMethodDisplayName)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text("Asr School")
                            Spacer()
                            Text(prayerManager.juristicMethod.displayName)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text("High Latitude Rule")
                            Spacer()
                            Text(prayerManager.highLatsMethod.displayName)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    } else {
                        Picker("Calculation Method", selection: $prayerManager.calculationMethod) {
                            ForEach(PrayTimes.availableMethodKeys, id: \.key) { item in
                                Text(item.name).tag(item.key)
                            }
                        }

                        Picker("Asr School", selection: $prayerManager.juristicMethod) {
                            ForEach(PrayTimes.AdjustmentMethod.allCases) { method in
                                Text(method.displayName).tag(method)
                            }
                        }

                        Picker("High Latitude Rule", selection: $prayerManager.highLatsMethod) {
                            ForEach(PrayTimes.ElavationMethod.allCases) { method in
                                Text(method.displayName).tag(method)
                            }
                        }
                    }
                } header: {
                    SettingsIconLabel(title: "Prayer Calculation", icon: "sun.max.fill", color: .orange)
                } footer: {
                    if prayerManager.autoDetectSettings {
                        Text("Calculation method, Asr school, and high latitude rules are automatically optimized for your coordinates.")
                    } else {
                        Text("Calculated completely on-device using astronomical algorithms. Works anywhere without internet.")
                    }
                }

                // MARK: - Tasbih Counter
                Section {
                    Toggle("Tactile Haptic Feedback", isOn: $tasbihHapticEnabled)
                } header: {
                    SettingsIconLabel(title: "Tasbih Counter", icon: "circle.grid.cross.fill", color: .indigo)
                } footer: {
                    Text("Provides a subtle physical pulse on each bead tap.")
                }

                // MARK: - Appearance
                Section {
                    Picker("Theme", selection: $appTheme) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }

                    Picker("Menu Bar Style", selection: $menuBarStyle) {
                        Text("Modern Pill / Rectangle").tag("pill")
                        Text("Floating Capsule").tag("floating")
                        Text("Standard Tab Bar").tag("standard")
                    }
                } header: {
                    SettingsIconLabel(title: "Appearance", icon: "paintbrush.fill", color: .purple)
                }

                // MARK: - Storage & Cache
                Section {
                    HStack {
                        Label("Downloaded Surahs", systemImage: "internaldrive")
                        Spacer()
                        Text("\(downloadedCount) saved")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Total Bookmarks", systemImage: "bookmark")
                        Spacer()
                        Text("\(bookmarkCount) items")
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        showClearDownloads = true
                    } label: {
                        Label("Clear Downloaded Surahs", systemImage: "trash")
                    }
                    .confirmationDialog("Clear all downloads?", isPresented: $showClearDownloads, titleVisibility: .visible) {
                        Button("Delete All Downloads", role: .destructive) {
                            QuranFileManager.shared.deleteAllSurahs()
                            refreshCounts()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will remove all offline Quran files to free up disk space.")
                    }

                    Button(role: .destructive) {
                        showClearBookmarks = true
                    } label: {
                        Label("Clear All Bookmarks", systemImage: "bookmark.slash")
                    }
                    .confirmationDialog("Clear all bookmarks?", isPresented: $showClearBookmarks, titleVisibility: .visible) {
                        Button("Delete All Bookmarks", role: .destructive) {
                            QuranStorageManager.shared.deleteAllBookmarks()
                            refreshCounts()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This action cannot be undone.")
                    }
                } header: {
                    SettingsIconLabel(title: "Storage & Cache", icon: "internaldrive.fill", color: .teal)
                }

                // MARK: - About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.1.7 (9)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Reyyan Bereka")
                            .foregroundStyle(.secondary)
                    }

                    if let url = URL(string: "https://github.com/reyyanbereka2010-dotcom/DeenPlus") {
                        Link(destination: url) {
                            HStack {
                                Label("Source Code & GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    SettingsIconLabel(title: "About & Community", icon: "info.circle.fill", color: .gray)
                } footer: {
                    Text("100% Private • On-Device Prayer Computations • No Ads • Free & Open Source")
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .safeAreaPadding(.bottom, 60)
            .onAppear {
                refreshCounts()
            }
            .onDisappear {
                translationNarrator.stop()
            }
        }
    }

    private func refreshCounts() {
        downloadedCount = QuranFileManager.shared.getDownloadedSurahs().count
        bookmarkCount = QuranStorageManager.shared.loadBookmarks().count
    }
}

// MARK: - Reusable Settings Icon Label

struct SettingsIconLabel: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color.gradient)
                    .frame(width: 22, height: 22)

                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
        }
    }
}

// MARK: - Prayer Notification Summary Footer

struct PrayerNotifSummaryFooter: View {
    @AppStorage("prayerNotificationsEnabled") private var masterEnabled: Bool = false
    @AppStorage("notif_fajr") private var fajr: Bool = true
    @AppStorage("notif_dhuhr") private var dhuhr: Bool = true
    @AppStorage("notif_asr") private var asr: Bool = true
    @AppStorage("notif_maghrib") private var maghrib: Bool = true
    @AppStorage("notif_isha") private var isha: Bool = true

    var body: some View {
        let enabledCount = [fajr, dhuhr, asr, maghrib, isha].filter { $0 }.count
        Text(masterEnabled ? "Notifications active for \(enabledCount) of 5 daily prayers." : "Prayer notifications are currently disabled.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}
