//
//  NotificationSettingsView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/22/26.
//

import SwiftUI
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

struct NotificationSettingsView: View {
    @EnvironmentObject var prayerManager: PrayerManager
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined

    @AppStorage("prayerNotificationsEnabled")
    private var masterEnabled: Bool = false

    @AppStorage("notif_fajr") private var fajrEnabled: Bool = true
    @AppStorage("notif_dhuhr") private var dhuhrEnabled: Bool = true
    @AppStorage("notif_asr") private var asrEnabled: Bool = true
    @AppStorage("notif_maghrib") private var maghribEnabled: Bool = true
    @AppStorage("notif_isha") private var ishaEnabled: Bool = true

    // Selected notification sound
    @AppStorage("notificationSoundOption")
    private var notificationSoundOption: String = NotificationSoundOption.adhanTakbeer.rawValue

    // Toggle for in-app Athan haptic feedback
    @AppStorage("athaanHapticEnabled") private var athaanHapticEnabled: Bool = false

    // State for audio previewing
    @State private var previewingOption: NotificationSoundOption? = nil

    // State for test notification
    @State private var isSendingTest = false
    @State private var testSent = false
    @State private var testErrorMessage: String? = nil
    @State private var showTestErrorAlert = false

    var body: some View {
        Form {
            statusSection
            testNotificationSection
            soundSection
            prayerSection
            athanHapticSection
            actionsSection
        }
        .navigationTitle("Notifications")
        .safeAreaPadding(.bottom, 60)
        .onAppear { refreshAuthorizationStatus() }
        .onDisappear {
            NotificationManager.shared.stopPreview()
            previewingOption = nil
        }
        .alert("Notification Permission", isPresented: $showTestErrorAlert) {
            Button("Open iOS Settings") { openSystemSettings() }
            Button("OK", role: .cancel) {}
        } message: {
            Text(testErrorMessage ?? "Please enable notifications in iOS Settings.")
        }
    }

    private var statusSection: some View {
        Section {
            HStack {
                Label("Authorization", systemImage: iconNameForStatus(permissionStatus))
                    .foregroundStyle(colorForStatus(permissionStatus))
                Spacer()
                Text(textForStatus(permissionStatus))
                    .foregroundStyle(.secondary)
            }
            Toggle("Enable Prayer Notifications", isOn: $masterEnabled)
                .onChange(of: masterEnabled) { newValue in
                    if newValue {
                        NotificationManager.shared.requestPermission()
                        NotificationManager.shared.schedulePrayerNotifications(prayerTimes: prayerManager.prayerTimes)
                        refreshAuthorizationStatus()
                    } else {
                        NotificationManager.shared.cancelPrayerNotifications()
                    }
                }
        } header: {
            Text("Status")
        }
    }

    private var testNotificationSection: some View {
        Section {
            Button {
                triggerTestNotification()
            } label: {
                HStack {
                    Label(
                        isSendingTest ? "Scheduling Test in 3s..." : "Send Test Notification (3s)",
                        systemImage: isSendingTest ? "hourglass" : "bell.and.waveform.fill"
                    )
                    .foregroundStyle(isSendingTest ? Color.secondary : Color.green)

                    Spacer()

                    if testSent {
                        Text("Scheduled!")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.14), in: Capsule())
                    }
                }
            }
            .disabled(isSendingTest)
        } header: {
            Text("Test Notifications")
        }
    }

    private var soundSection: some View {
        Section {
            ForEach(NotificationSoundOption.allCases) { option in
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Text(option.displayName)
                            .font(.body)
                            .fontWeight(notificationSoundOption == option.rawValue ? .semibold : .regular)
                        if notificationSoundOption == option.rawValue {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }

                    Spacer()

                    if option.soundFileName != nil || option == .defaultChime {
                        Button {
                            togglePreview(for: option)
                        } label: {
                            Image(systemName: previewingOption == option ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title3)
                                .foregroundStyle(previewingOption == option ? .red : .green)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(previewingOption == option ? "Stop audio preview" : "Play preview for \(option.displayName)")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    notificationSoundOption = option.rawValue
                    updateNotifications()
                }
            }
        } header: {
            Text("Notification Sound")
        }
    }

    private var prayerSection: some View {
        Section {
            Toggle("Fajr", isOn: $fajrEnabled)
            Toggle("Dhuhr", isOn: $dhuhrEnabled)
            Toggle("Asr", isOn: $asrEnabled)
            Toggle("Maghrib", isOn: $maghribEnabled)
            Toggle("Isha", isOn: $ishaEnabled)
        } header: {
            Text("Prayers")
        }
        .disabled(!masterEnabled)
        .onChange(of: fajrEnabled) { _ in updateNotifications() }
        .onChange(of: dhuhrEnabled) { _ in updateNotifications() }
        .onChange(of: asrEnabled) { _ in updateNotifications() }
        .onChange(of: maghribEnabled) { _ in updateNotifications() }
        .onChange(of: ishaEnabled) { _ in updateNotifications() }
    }

    private var athanHapticSection: some View {
        Section {
            Toggle("Athan Vibration/Haptic (in-app)", isOn: $athaanHapticEnabled)
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                NotificationManager.shared.requestPermission()
                refreshAuthorizationStatus()
            } label: {
                Label("Enable Notifications", systemImage: "bell.fill")
            }

            Button {
                NotificationManager.shared.cancelPrayerNotifications()
            } label: {
                Label("Reset Pending Notifications", systemImage: "bell.slash.fill")
            }

            Button {
                openSystemSettings()
            } label: {
                Label("Open System Settings", systemImage: "gear")
            }
        } header: {
            Text("Actions")
        }
    }

    private func triggerTestNotification() {
        isSendingTest = true
        testSent = false
        NotificationManager.shared.sendTestNotification(delay: 3) { success, errorMessage in
            isSendingTest = false
            if success {
                testSent = true
                #if canImport(UIKit)
                #if !targetEnvironment(simulator)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
                #endif
                refreshAuthorizationStatus()
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    testSent = false
                }
            } else if let error = errorMessage {
                testErrorMessage = error
                showTestErrorAlert = true
            }
        }
    }

    private func togglePreview(for option: NotificationSoundOption) {
        if previewingOption == option {
            NotificationManager.shared.stopPreview()
            previewingOption = nil
        } else {
            previewingOption = option
            NotificationManager.shared.playPreview(for: option)
        }
    }

    private func updateNotifications() {
        if masterEnabled {
            NotificationManager.shared.schedulePrayerNotifications(prayerTimes: prayerManager.prayerTimes)
        }
    }

    private func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                permissionStatus = settings.authorizationStatus
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

    private func textForStatus(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    private func colorForStatus(_ status: UNAuthorizationStatus) -> Color {
        switch status {
        case .authorized, .provisional: return .green
        case .denied: return .red
        default: return .secondary
        }
    }

    private func iconNameForStatus(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized, .provisional: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
            .environmentObject(PrayerManager())
    }
}
