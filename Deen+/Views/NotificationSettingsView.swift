// Refactored for type-checking reliability.
import SwiftUI
import UserNotifications

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

    // Toggle for in-app Athan haptic feedback
    @AppStorage("athaanHapticEnabled") private var athaanHapticEnabled: Bool = false

    var body: some View {
        Form {
            statusSection
            prayerSection
            athanHapticSection
            actionsSection
        }
        .navigationTitle("Notifications")
        .safeAreaPadding(.bottom, 60)
        .onAppear { refreshAuthorizationStatus() }
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

    private var prayerSection: some View {
        Section {
            Toggle("Fajr", isOn: $fajrEnabled)
            Toggle("Dhuhr", isOn: $dhuhrEnabled)
            Toggle("Asr", isOn: $asrEnabled)
            Toggle("Maghrib", isOn: $maghribEnabled)
            Toggle("Isha", isOn: $ishaEnabled)
        } header: {
            Text("Prayers")
        } footer: {
            Text(masterEnabled ? "Select which prayers you want notifications for." : "Enable notifications to configure per-prayer alerts.")
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
        } footer: {
            Text("Plays enhanced vibration/haptic feedback when a prayer notification fires with the app open.")
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
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    private func iconNameForStatus(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "checkmark.seal.fill"
        case .denied: return "xmark.seal.fill"
        case .notDetermined: return "questionmark.app.fill"
        case .provisional: return "hourglass"
        case .ephemeral: return "bolt.badge.clock"
        @unknown default: return "questionmark"
        }
    }

    private func colorForStatus(_ status: UNAuthorizationStatus) -> Color {
        switch status {
        case .authorized: return .green
        case .denied: return .red
        case .provisional: return .orange
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack { NotificationSettingsView().environmentObject(PrayerManager()) }
}
