//
//  MuslimPrayerApp.swift
//  MuslimPrayer
//
//  Created by Reyyan Bereka on 7/16/26.
//
import SwiftUI
import UserNotifications
import AVFoundation

@main
struct Deen_App: App {

    @AppStorage("appTheme")
    private var appTheme = "System"
    @AppStorage("appAccentColor")
    private var appAccentColor = "emerald"

    private var accentColor: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var locationManager = LocationManager()
    @StateObject private var qiblaManager = QiblaManager()
    @StateObject private var prayerManager = PrayerManager()

    init() {
        BackgroundTaskManager.shared.registerBackgroundTasks()
        NotificationManager.shared.requestPermission()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio, options: [])
        } catch {
            // Silently continue
        }
    }

    var body: some Scene {

        WindowGroup {

            ContentView()
                .environmentObject(prayerManager)
                .environmentObject(locationManager)
                .environmentObject(qiblaManager)
                .preferredColorScheme(colorScheme)
                .tint(accentColor)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        prayerManager.updatePrayerLiveActivity()
                    } else if newPhase == .background {
                        prayerManager.updatePrayerLiveActivity()
                        BackgroundTaskManager.shared.scheduleAllTasks()
                    }
                }

        }

    }

    private var colorScheme: ColorScheme? {

        switch appTheme {

        case "Light":
            return .light

        case "Dark":
            return .dark

        default:
            return nil

        }

    }

}
