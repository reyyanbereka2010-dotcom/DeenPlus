//
//  NotificationDelegate.swift
//  Deen+
//
//  Handles foreground notification delivery (prayer reminders with athan sound/haptics).
//

import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private let prayerIdentifiers: Set<String> = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    private override init() { super.init() }

    // Called when a notification arrives while the app is foregrounded
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let identifier = notification.request.identifier
        if prayerIdentifiers.contains(identifier) || identifier == "TestPrayerNotification" {
            // Play athan sound/haptic in-app
            NotificationManager.shared.handleForegroundAthan(for: identifier == "TestPrayerNotification" ? "Fajr" : identifier)
            // Show the notification as a banner with sound
            completionHandler([.sound, .banner])
        } else {
            completionHandler([.banner, .sound])
        }
    }

    // Handle user tapping on the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
