import Foundation
import UserNotifications
import Combine
import SwiftUI

// MARK: - Authorization State

enum NotificationAuthState: String, Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
}

// MARK: - Manager

@MainActor
final class NotificationPermissionManager: ObservableObject {
    @Published private(set) var state: NotificationAuthState = .notDetermined

    var isAuthorized: Bool {
        switch state {
        case .authorized, .provisional, .ephemeral: return true
        case .notDetermined, .denied: return false
        }
    }

    init() {
        Task { await refresh() }
    }

    func refresh() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: state = .notDetermined
        case .denied: state = .denied
        case .authorized: state = .authorized
        case .provisional: state = .provisional
        case .ephemeral: state = .ephemeral
        @unknown default: state = .notDetermined
        }
    }

    func requestAuthorization(options: UNAuthorizationOptions = [.alert, .badge, .sound]) async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            await refresh()
            return granted
        } catch {
            await refresh()
            return false
        }
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // MARK: - Convenience for testing

    func scheduleTestNotification(in seconds: TimeInterval = 5) async {
        guard isAuthorized else { return }
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a sample notification from the app."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            // Ignore scheduling errors for now
        }
    }
}
