//
//  SettingsView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var prayerManager: PrayerManager
    @State private var downloadedCount = 0
    @State private var bookmarkCount = 0

    @State private var showClearDownloads = false
    @State private var showClearBookmarks = false

    @AppStorage("appTheme")
    private var appTheme = "System"

    @AppStorage("prayerNotificationsEnabled")
    private var prayerNotificationsEnabled: Bool = false

    @AppStorage("tasbih_haptic_feedback")
    private var tasbihHapticEnabled: Bool = true

    @AppStorage("quranArabicFontSize")
    private var quranArabicFontSize: Double = 26

    @AppStorage("quranShowTranslation")
    private var quranShowTranslation: Bool = true

    var body: some View {

        NavigationStack {

            Form {

                Section {

                    NavigationLink("Downloads") {

                        DownloadsView()

                    }

                    NavigationLink("Bookmarks") {

                        BookmarksView()

                    }

                } header: {
                    Text("Quran")
                }

                Section {
                    Toggle(
                        "Prayer Notifications",
                        isOn: $prayerNotificationsEnabled
                    )
                    .onChange(of: prayerNotificationsEnabled) { newValue in
                        if newValue {
                            NotificationManager.shared.requestPermission()
                            NotificationManager.shared.schedulePrayerNotifications(prayerTimes: prayerManager.prayerTimes)
                        } else {
                            NotificationManager.shared.cancelPrayerNotifications()
                        }
                    }

                    NavigationLink("Notification Settings") {
                        NotificationSettingsView()
                    }
                } header: {
                    Text("Prayer Notifications")
                } footer: {
                    PrayerNotifSummaryFooter()
                }

                Section {
                    Toggle("Auto-Select Settings", isOn: $prayerManager.autoDetectSettings)

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
                    Text("Prayer Calculation")
                } footer: {
                    if prayerManager.autoDetectSettings {
                        Text("Calculation method, Asr school, and high latitude rules are automatically chosen based on your location and region.")
                    } else {
                        Text("Calculated completely on-device using astronomical algorithms. Works anywhere without an internet connection.")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Default Arabic Font Size")
                            Spacer()
                            Text("\(Int(quranArabicFontSize)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $quranArabicFontSize, in: 18...38, step: 2)
                    }
                    .padding(.vertical, 4)

                    Toggle("Show English Translation", isOn: $quranShowTranslation)
                } header: {
                    Text("Quran Display")
                }

                Section {
                    Toggle("Vibration / Haptic Feedback", isOn: $tasbihHapticEnabled)
                } header: {
                    Text("Tasbih Counter")
                } footer: {
                    Text("Provide gentle tactile haptic feedback on every dhikr bead tap.")
                }

                Section {

                    Picker(
                        "Theme",
                        selection: $appTheme
                    ) {

                        Text("System")
                            .tag("System")

                        Text("Light")
                            .tag("Light")

                        Text("Dark")
                            .tag("Dark")

                    }

                } header: {
                    Text("Appearance")
                }

                Section {

                    HStack {

                        Label(
                            "Downloaded Surahs",
                            systemImage: "arrow.down.circle.fill"
                        )

                        Spacer()

                        Text(
                            "\(downloadedCount)"
                        )
                        .foregroundStyle(.secondary)

                    }

                    HStack {

                        Label(
                            "Bookmarked Verses",
                            systemImage: "bookmark.fill"
                        )

                        Spacer()

                        Text(
                            "\(bookmarkCount)"
                        )
                        .foregroundStyle(.secondary)

                    }

                    Button(
                        role: .destructive
                    ) {

                        showClearDownloads = true

                    } label: {

                        Label(
                            "Clear Downloads",
                            systemImage: "trash"
                        )

                    }
                    .confirmationDialog(
                        "Clear all downloaded Surahs?",
                        isPresented: $showClearDownloads,
                        titleVisibility: .visible
                    ) {

                        Button(
                            "Delete All",
                            role: .destructive
                        ) {

                            QuranFileManager.shared.deleteAll {
                                refreshCounts()
                            }

                        }

                        Button(
                            "Cancel",
                            role: .cancel
                        ) {}

                    } message: {

                        Text(
                            "This will remove all offline Quran files."
                        )

                    }

                    Button(
                        role: .destructive
                    ) {

                        showClearBookmarks = true

                    } label: {

                        Label(
                            "Clear Bookmarks",
                            systemImage: "bookmark.slash"
                        )

                    }
                    .confirmationDialog(
                        "Clear all bookmarks?",
                        isPresented: $showClearBookmarks,
                        titleVisibility: .visible
                    ) {

                        Button(
                            "Delete All",
                            role: .destructive
                        ) {

                            QuranStorageManager.shared
                                .deleteAllBookmarks()

                            refreshCounts()

                        }

                        Button(
                            "Cancel",
                            role: .cancel
                        ) {}

                    } message: {

                        Text(
                            "This action cannot be undone."
                        )

                    }

                } header: {
                    Text("Storage")
                }

                Section {

                    HStack {

                        Text("Version")

                        Spacer()

                        Text("1.1.2 (4)")
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
                                Label("Source Code & Releases", systemImage: "chevron.left.forwardslash.chevron.right")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                } header: {
                    Text("About")
                }

            }
            .navigationTitle(
                "Settings"
            )

            .onAppear {

                refreshCounts()

            }

        }

    }

    private func refreshCounts() {

        downloadedCount =
        QuranFileManager.shared
            .getDownloadedSurahs()
            .count

        bookmarkCount =
        QuranStorageManager.shared
            .loadBookmarks()
            .count

    }

}

struct PrayerNotifSummaryFooter: View {
    @AppStorage("prayerNotificationsEnabled") private var masterEnabled: Bool = false
    @AppStorage("notif_fajr") private var fajr: Bool = true
    @AppStorage("notif_dhuhr") private var dhuhr: Bool = true
    @AppStorage("notif_asr") private var asr: Bool = true
    @AppStorage("notif_maghrib") private var maghrib: Bool = true
    @AppStorage("notif_isha") private var isha: Bool = true

    var body: some View {
        let enabledCount = [fajr, dhuhr, asr, maghrib, isha].filter { $0 }.count
        Text(masterEnabled ? "Notifications enabled for \(enabledCount) prayer\(enabledCount == 1 ? "" : "s")." : "Notifications are disabled.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}
