//
//  SettingsView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @EnvironmentObject var prayerManager: PrayerManager
    @ObservedObject private var translationNarrator = TranslationNarrator.shared
    @ObservedObject private var recitationPlayer = RecitationPlayer.shared
    @ObservedObject private var iconManager = AppIconManager.shared

    @State private var downloadedCount = 0
    @State private var bookmarkCount = 0

    @State private var showClearDownloads = false
    @State private var showClearBookmarks = false
    @State private var showOnboardingSheet = false

    // State for test notification
    @State private var isSendingTestNotification = false
    @State private var testNotificationScheduled = false
    @State private var testNotificationError: String? = nil
    @State private var showNotificationErrorAlert = false

    @AppStorage("appTheme") private var appTheme = "System"
    @AppStorage("appAccentColor") private var appAccentColor = "emerald"
    @AppStorage("menuBarStyle") private var menuBarStyle: String = "pill"
    @AppStorage("prayerNotificationsEnabled") private var prayerNotificationsEnabled: Bool = false
    @AppStorage("tasbih_haptic_feedback") private var tasbihHapticEnabled: Bool = true

    @AppStorage("quranArabicFontSize") private var quranArabicFontSize: Double = 26
    @AppStorage("quranTranslationFontSize") private var quranTranslationFontSize: Double = 16
    @AppStorage("quranShowTranslation") private var quranShowTranslation: Bool = true
    @AppStorage("quranReadingTheme") private var quranReadingTheme: String = "standard"
    @AppStorage("quranKeepScreenAwake") private var quranKeepScreenAwake: Bool = true
    @AppStorage("selectedQuranReciter") private var selectedQuranReciter: String = Reciter.alafasy.rawValue

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "11"
        return "\(version) (\(build))"
    }

    private var accent: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile / App Header Card
                Section {
                    HStack(spacing: 16) {
                        // Current App Icon Preview
                        AppIconPreviewBox(option: iconManager.selectedOption)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text("Deen+")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)

                                Text(appVersionString)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(accent.opacity(0.14), in: Capsule())
                                    .foregroundStyle(accent)
                            }

                            Text("Private on device and not shared with third party companies")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Appearance & Customization
                Section("Appearance & Icons") {
                    NavigationLink {
                        AppIconSelectionView()
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "app.gift.fill", color: .indigo)
                            Text("App Icon")
                            Spacer()
                            Text(iconManager.selectedOption.title)
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "paintbrush.fill", color: .purple)
                            Text("Theme & Styling")
                        }
                    }

                    // Direct Accent Color Row
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "paintpalette.fill", color: .pink)
                            Text("Accent Color")
                        }

                        HStack(spacing: 12) {
                            ForEach(AppAccentColor.allCases) { item in
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: appAccentColor == item.rawValue ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        triggerSelectionHaptic()
                                        appAccentColor = item.rawValue
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.leading, 42)
                    }

                    Picker(selection: $appTheme) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "circle.lefthalf.filled", color: .blue)
                            Text("Color Scheme")
                        }
                    }

                    Picker(selection: $menuBarStyle) {
                        Text("Modern Pill").tag("pill")
                        Text("Floating Capsule").tag("floating")
                        Text("Frosted Glass").tag("glass")
                        Text("Islamic Arch").tag("arch")
                        Text("Aurora Glow").tag("aurora")
                        Text("Elevated Dock").tag("dock")
                        Text("Minimalist Bar").tag("minimal")
                        Text("Compact Icons").tag("compact")
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "dock.rectangle", color: .teal)
                            Text("Menu Bar Style")
                        }
                    }
                }

                // MARK: - Prayers & Notifications
                Section("Prayers & Calculations") {
                    Toggle(isOn: $prayerNotificationsEnabled) {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "bell.fill", color: .red)
                            Text("Prayer Notifications")
                        }
                    }
                    .onChange(of: prayerNotificationsEnabled) { _, newValue in
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
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "speaker.wave.3.fill", color: .orange)
                            Text("Adhan Sound & Alerts")
                        }
                    }

                    Button {
                        triggerTestNotification()
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(
                                icon: isSendingTestNotification ? "hourglass" : "bell.badge.waveform.fill",
                                color: .green
                            )

                            Text(isSendingTestNotification ? "Scheduling Test in 3s..." : "Send Test Adhan Alert")
                                .foregroundStyle(isSendingTestNotification ? Color.secondary : Color.primary)

                            Spacer()

                            if testNotificationScheduled {
                                Text("Scheduled")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.14), in: Capsule())
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .disabled(isSendingTestNotification)

                    Toggle(isOn: $prayerManager.autoDetectSettings) {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "location.fill", color: .blue)
                            Text("Auto-Detect Coordinates")
                        }
                    }

                    if prayerManager.autoDetectSettings {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "sun.max.fill", color: .orange)
                            Text("Method")
                            Spacer()
                            Text(prayerManager.currentMethodDisplayName)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "calendar", color: .purple)
                            Text("Asr School")
                            Spacer()
                            Text(prayerManager.juristicMethod.displayName)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Picker(selection: $prayerManager.calculationMethod) {
                            ForEach(PrayTimes.availableMethodKeys, id: \.key) { item in
                                Text(item.name).tag(item.key)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                SettingsRowBadge(icon: "sun.max.fill", color: .orange)
                                Text("Calculation Method")
                            }
                        }

                        Picker(selection: $prayerManager.juristicMethod) {
                            ForEach(PrayTimes.AdjustmentMethod.allCases) { method in
                                Text(method.displayName).tag(method)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                SettingsRowBadge(icon: "calendar", color: .purple)
                                Text("Asr School")
                            }
                        }

                        Picker(selection: $prayerManager.highLatsMethod) {
                            ForEach(PrayTimes.ElavationMethod.allCases) { method in
                                Text(method.displayName).tag(method)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                SettingsRowBadge(icon: "globe.americas.fill", color: .blue)
                                Text("High Latitude Rule")
                            }
                        }
                    }
                }

                // MARK: - Holy Quran & Audio
                Section("Holy Quran & Audio") {
                    NavigationLink {
                        RecitationSettingsView()
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "waveform.and.mic", color: .green)
                            Text("Recitation & Voices")
                        }
                    }

                    Picker(selection: $selectedQuranReciter) {
                        ForEach(Reciter.allCases) { reciter in
                            Text(reciter.displayName).tag(reciter.rawValue)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "person.wave.2.fill", color: .teal)
                            Text("Sheikh (Arabic)")
                        }
                    }
                    .onChange(of: selectedQuranReciter) { _, newRaw in
                        if let rec = Reciter(rawValue: newRaw) {
                            recitationPlayer.setReciter(rec)
                        }
                    }

                    Picker(selection: $translationNarrator.activeVoice) {
                        ForEach(TranslationVoice.allCases) { voice in
                            Text(voice.displayName).tag(voice)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "person.wave.2", color: .mint)
                            Text("Translation Voice")
                        }
                    }

                    Button {
                        if translationNarrator.isPlaying && translationNarrator.isPreviewing {
                            translationNarrator.stop()
                        } else {
                            translationNarrator.preview(voice: translationNarrator.activeVoice)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(
                                icon: (translationNarrator.isPlaying && translationNarrator.isPreviewing) ? "stop.circle.fill" : "play.circle.fill",
                                color: .cyan
                            )
                            Text((translationNarrator.isPlaying && translationNarrator.isPreviewing) ? "Stop Voice Sample" : "Sample \(translationNarrator.activeVoice.shortName)'s Voice")
                                .foregroundStyle(.primary)

                            Spacer()

                            if translationNarrator.activeVoice.isStudioRecording {
                                Text("Studio")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.12), in: Capsule())
                            }
                        }
                    }

                    // Arabic Font Size
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "textformat.size", color: .blue)
                            Text("Arabic Font Size")
                            Spacer()
                            Text("\(Int(quranArabicFontSize)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $quranArabicFontSize, in: 18...38, step: 2)
                            .padding(.leading, 42)
                    }
                    .padding(.vertical, 2)

                    // English Translation Font Size
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "character.book.closed.fill", color: .indigo)
                            Text("Translation Font Size")
                            Spacer()
                            Text("\(Int(quranTranslationFontSize)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $quranTranslationFontSize, in: 13...24, step: 1)
                            .padding(.leading, 42)
                    }
                    .padding(.vertical, 2)

                    Picker(selection: $quranReadingTheme) {
                        ForEach(ReaderTheme.allCases) { theme in
                            Label(theme.displayName, systemImage: theme.icon).tag(theme.rawValue)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "book.pages.fill", color: .brown)
                            Text("Reader Theme")
                        }
                    }

                    Toggle(isOn: $quranShowTranslation) {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "character.bubble.fill", color: .teal)
                            Text("Show English Translation")
                        }
                    }

                    Toggle(isOn: $quranKeepScreenAwake) {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "sun.max.circle.fill", color: .yellow)
                            Text("Keep Screen Awake")
                        }
                    }

                    NavigationLink {
                        BookmarksView()
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "bookmark.fill", color: .blue)
                            Text("Saved Bookmarks")
                            Spacer()
                            Text("\(bookmarkCount)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        DownloadsView()
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "arrow.down.circle.fill", color: .green)
                            Text("Offline Downloads")
                            Spacer()
                            Text("\(downloadedCount)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Tools & Utilities
                Section("Tools & Utilities") {
                    NavigationLink {
                        QiblaCustomizationSheet()
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "location.north.circle.fill", color: .blue)
                            Text("Qibla Compass")
                        }
                    }

                    Toggle(isOn: $tasbihHapticEnabled) {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "circle.grid.cross.fill", color: .purple)
                            Text("Tasbih Tactile Feedback")
                        }
                    }
                }

                // MARK: - Storage & Cache
                Section("Storage & Cache") {
                    Button(role: .destructive) {
                        showClearDownloads = true
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "trash.fill", color: .red)
                            Text("Clear Downloaded Surahs")
                                .foregroundStyle(.red)
                            Spacer()
                            Text("\(downloadedCount) saved")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
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
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "bookmark.slash.fill", color: .orange)
                            Text("Clear All Bookmarks")
                                .foregroundStyle(.red)
                            Spacer()
                            Text("\(bookmarkCount) items")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
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
                }

                // MARK: - About & Support
                Section("About") {
                    Button {
                        showOnboardingSheet = true
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "sparkles", color: .yellow)
                            Text("Welcome Introduction")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2.bold())
                                .foregroundStyle(.tertiary)
                        }
                    }

                    HStack(spacing: 14) {
                        SettingsRowBadge(icon: "info.circle.fill", color: .gray)
                        Text("Version")
                        Spacer()
                        Text(appVersionString)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 14) {
                        SettingsRowBadge(icon: "person.fill", color: .blue)
                        Text("Developer")
                        Spacer()
                        Text("Reyyan Bereka")
                            .foregroundStyle(.secondary)
                    }

                    if let url = URL(string: "https://github.com/reyyanbereka2010-dotcom/DeenPlus") {
                        Link(destination: url) {
                            HStack(spacing: 14) {
                                SettingsRowBadge(icon: "chevron.left.forwardslash.chevron.right", color: .black)
                                Text("Source Code (GitHub)")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .safeAreaPadding(.bottom, 60)
            .sheet(isPresented: $showOnboardingSheet) {
                OnboardingSheetView(isPresented: $showOnboardingSheet)
            }
            .onAppear {
                if menuBarStyle == "standard" {
                    menuBarStyle = "pill"
                }
                refreshCounts()
            }
            .onDisappear {
                translationNarrator.stop()
            }
            .alert("Notification Permission", isPresented: $showNotificationErrorAlert) {
                Button("Open iOS Settings") { openSystemSettings() }
                Button("OK", role: .cancel) {}
            } message: {
                Text(testNotificationError ?? "Please enable notifications in iOS Settings.")
            }
        }
    }

    private func triggerSelectionHaptic() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
    }

    private func triggerTestNotification() {
        isSendingTestNotification = true
        testNotificationScheduled = false
        NotificationManager.shared.sendTestNotification(delay: 3) { success, errorMessage in
            isSendingTestNotification = false
            if success {
                testNotificationScheduled = true
                #if canImport(UIKit)
                #if !targetEnvironment(simulator)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
                #endif
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    testNotificationScheduled = false
                }
            } else if let error = errorMessage {
                testNotificationError = error
                showNotificationErrorAlert = true
            }
        }
    }

    private func openSystemSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    private func refreshCounts() {
        downloadedCount = QuranFileManager.shared.getDownloadedSurahs().count
        bookmarkCount = QuranStorageManager.shared.loadBookmarks().count
    }
}

// MARK: - Native iOS Settings Row Badge

struct SettingsRowBadge: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(color.gradient)
                .frame(width: 29, height: 29)

            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}
