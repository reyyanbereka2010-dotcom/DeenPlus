//
//  ContentView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI

struct ContentView: View {
    
    @State private var hideTabBar = false
    @EnvironmentObject var prayerManager: PrayerManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            PrayerTimesView()
                .tabItem {
                    Label("Prayer Times", systemImage: "clock.fill")
                }
                .tag(1)

            QiblaView()
                .tabItem {
                    Label("Qibla", systemImage: "location.north.fill")
                }
                .tag(2)

            DailyDuasView()
                .tabItem {
                    Label("Duas", systemImage: "hands.sparkles.fill")
                }
                .tag(3)

            TasbihView()
                .tabItem {
                    Label("Tasbih", systemImage: "circle.circle.fill")
                }
                .tag(4)

            QuranView()
                .tabItem {
                    Label("Quran", systemImage: "book.fill")
                }
                .tag(5)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(6)
        }
        .toolbar(
            hideTabBar ? .hidden : .visible,
            for: .tabBar
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(PrayerManager())
}
