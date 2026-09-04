//
//  NotificationManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/22/26.
//

import Foundation
import UserNotifications
import AVFoundation
import AudioToolbox
import CoreHaptics
import SwiftUI

class NotificationManager {
    private let prayerIdentifiers: [String] = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    // MARK: - In-App Athan & Haptic Support

    /// UserDefaults key for enabling/disabling in-app athan haptic feedback.
    /// Default value: true
    private let athaanHapticEnabledKey = "athaanHapticEnabled"

    /// AVAudioPlayer instance for playing athan sound in-app.
    private var audioPlayer: AVAudioPlayer?

    /// Core Haptics engine instance.
    private var hapticEngine: CHHapticEngine?

    /// Indicates whether Core Haptics is available and initialized.
    private var hapticsAvailable = false

    /// Shared instance for singleton pattern.
    static let shared = NotificationManager()

    private init() {
        prepareHaptics()
    }

    // MARK: - Public Methods

    /// Request notification permission from the user.
    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                if granted {
                    print("Notifications allowed")
                } else {
                    print("Notifications denied")
                }
            }
    }

    /// Cancel all scheduled prayer notifications.
    func cancelPrayerNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: prayerIdentifiers)
    }

    /// Schedule prayer notifications based on provided prayer times and user preferences.
    func schedulePrayerNotifications(
        prayerTimes: PrayerTimes
    ) {
        let defaults = UserDefaults.standard
        let masterEnabled = defaults.bool(forKey: "prayerNotificationsEnabled")
        guard masterEnabled else { return }

        let fajrOn = defaults.object(forKey: "notif_fajr") as? Bool ?? true
        let dhuhrOn = defaults.object(forKey: "notif_dhuhr") as? Bool ?? true
        let asrOn = defaults.object(forKey: "notif_asr") as? Bool ?? true
        let maghribOn = defaults.object(forKey: "notif_maghrib") as? Bool ?? true
        let ishaOn = defaults.object(forKey: "notif_isha") as? Bool ?? true

        let prayers = [
            ("Fajr", prayerTimes.fajr, fajrOn),
            ("Dhuhr", prayerTimes.dhuhr, dhuhrOn),
            ("Asr", prayerTimes.asr, asrOn),
            ("Maghrib", prayerTimes.maghrib, maghribOn),
            ("Isha", prayerTimes.isha, ishaOn)
        ]

        // Remove old prayer notifications first (only ours)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: prayerIdentifiers)

        for prayer in prayers where prayer.2 {
            schedule(name: prayer.0, time: prayer.1)
        }
    }

    /// Handle an athan notification firing while the app is in the foreground.
    ///
    /// - Parameter prayer: The name of the prayer to handle.
    public func handleForegroundAthan(for prayer: String) {
        let defaults = UserDefaults.standard
        let hapticEnabled = defaults.object(forKey: athaanHapticEnabledKey) as? Bool ?? true

        // Play athan sound in-app
        playAthanSound()

        // Provide haptic feedback if enabled
        if hapticEnabled {
            triggerHapticFeedback()
        }
    }

    // MARK: - Private Methods

    private func prayerMessage(for prayer: String) -> String {
        switch prayer {
        case "Fajr":
            return "Start your day with remembrance of Allah."
        case "Dhuhr":
            return "Take a moment to reconnect with Allah."
        case "Asr":
            return "Pause and make time for Salah."
        case "Maghrib":
            return "The sun has set. It is time for prayer."
        case "Isha":
            return "End your day with prayer and gratitude."
        default:
            return "It is time for Salah."
        }
    }

    private func schedule(
        name: String,
        time: String
    ) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"

        let cleanTime = time.components(separatedBy: " ").first ?? time

        guard let date = formatter.date(from: cleanTime) else { return }

        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.hour, .minute],
            from: date
        )

        let content = UNMutableNotificationContent()
        content.title = "\(name) Prayer Time"
        content.body = prayerMessage(for: name)
        content.sound = UNNotificationSound(
            named: UNNotificationSoundName("adhan.caf")
        )
        content.categoryIdentifier = "prayerReminder"

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: name,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Haptic & Audio Playback

    /// Prepare Core Haptics engine if available.
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            hapticsAvailable = false
            return
        }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            hapticsAvailable = true
        } catch {
            print("Failed to start haptic engine: \(error.localizedDescription)")
            hapticsAvailable = false
        }
    }

    /// Trigger haptic feedback using Core Haptics if available, otherwise fallback to vibration.
    private func triggerHapticFeedback() {
        if hapticsAvailable, let engine = hapticEngine {
            let sharpEvent = CHHapticEvent(eventType: .hapticTransient,
                                           parameters: [],
                                           relativeTime: 0)
            let continuousEvent = CHHapticEvent(eventType: .hapticContinuous,
                                                parameters: [],
                                                relativeTime: 0.1,
                                                duration: 1.0)
            do {
                let pattern = try CHHapticPattern(events: [sharpEvent, continuousEvent], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } catch {
                print("Failed to play haptic pattern: \(error.localizedDescription)")
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        } else {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    /// Play the athan sound in-app using AVAudioPlayer.
    private func playAthanSound() {
        guard let url = Bundle.main.url(forResource: "adhan", withExtension: "caf") else {
            print("Athan sound file 'adhan.caf' not found in bundle.")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play athan sound: \(error.localizedDescription)")
        }
    }
}
