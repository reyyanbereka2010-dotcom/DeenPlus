//
//  MuslimPrayerApp.swift
//  MuslimPrayer
//
//  Created by Reyyan Bereka on 7/16/26.
//
import SwiftUI
import UserNotifications

@main
struct Deen_App: App {

    @AppStorage("appTheme")
    private var appTheme = "System"
    @AppStorage("appAccentColor")
    private var appAccentColor = "emerald"

    private var accentColor: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    @StateObject private var locationManager = LocationManager()
    @StateObject private var qiblaManager = QiblaManager()
    @StateObject private var prayerManager = PrayerManager()

    init() {
        NotificationManager.shared.requestPermission()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {

        WindowGroup {

            ContentView()
                .environmentObject(prayerManager)
                .environmentObject(locationManager)
                .environmentObject(qiblaManager)
                .preferredColorScheme(colorScheme)
                .tint(accentColor)

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
