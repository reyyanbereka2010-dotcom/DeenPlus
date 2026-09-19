//
//  ContentView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum TabItemType: Int, CaseIterable, Identifiable {
    case home = 0
    case prayer = 1
    case quran = 2
    case duas = 3
    case qibla = 4
    case tasbih = 5
    case settings = 6

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .prayer: return "Prayers"
        case .quran: return "Quran"
        case .duas: return "Duas"
        case .qibla: return "Qibla"
        case .tasbih: return "Tasbih"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .prayer: return "clock.fill"
        case .quran: return "book.fill"
        case .duas: return "hands.sparkles.fill"
        case .qibla: return "location.north.fill"
        case .tasbih: return "circle.circle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var hideTabBar = false
    @EnvironmentObject var prayerManager: PrayerManager
    @State private var selectedTab = 0
    @AppStorage("menuBarStyle") private var menuBarStyle: String = "pill"
    @AppStorage("appAccentColor") private var appAccentColor: String = "emerald"
    @AppStorage("hasCompletedOnboardingV1") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding: Bool = false
    @State private var showLaunchSplash: Bool = true

    private var accent: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    private var sanitizedStyle: String {
        menuBarStyle == "standard" ? "pill" : menuBarStyle
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Active View Layer
            Group {
                switch selectedTab {
                case 0:
                    HomeView(selectedTab: $selectedTab)
                case 1:
                    PrayerTimesView()
                case 2:
                    QuranView()
                case 3:
                    DailyDuasView()
                case 4:
                    QiblaView()
                case 5:
                    TasbihView()
                case 6:
                    SettingsView()
                default:
                    HomeView(selectedTab: $selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom Custom Navigation Menu Bar
            if !hideTabBar {
                CustomBottomMenuBar(
                    selectedTab: $selectedTab,
                    style: sanitizedStyle
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Launch Splash Animation
            if showLaunchSplash {
                AppLaunchSplashView(isAnimating: $showLaunchSplash)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showOnboarding) {
            OnboardingSheetView(isPresented: $showOnboarding)
        }
        .onAppear {
            if menuBarStyle == "standard" {
                menuBarStyle = "pill"
            }
            prayerManager.updatePrayerLiveActivity()
            if !hasCompletedOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    showOnboarding = true
                }
            }
        }
    }
}

// MARK: - Custom Bottom Navigation Bar

struct CustomBottomMenuBar: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var selectedTab: Int
    let style: String
    @AppStorage("appAccentColor") private var appAccentColor: String = "emerald"
    @AppStorage("menuBarShowLabels") private var menuBarShowLabels: Bool = true
    @AppStorage("menuBarHaptics") private var menuBarHaptics: Bool = true
    @AppStorage("menuBarIndicator") private var menuBarIndicator: String = "pill"

    private var accent: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    private var shouldShowLabels: Bool {
        style != "compact" && menuBarShowLabels
    }

    var body: some View {
        HStack(spacing: style == "compact" ? 10 : 2) {
            ForEach(TabItemType.allCases) { item in
                let isSelected = selectedTab == item.rawValue

                Button {
                    if menuBarHaptics {
                        #if canImport(UIKit)
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        #endif
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = item.rawValue
                    }
                } label: {
                    VStack(spacing: shouldShowLabels ? 3 : 0) {
                        Image(systemName: item.icon)
                            .font(.system(size: isSelected ? 18 : 16, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? accent : .secondary)

                        if shouldShowLabels {
                            Text(item.title)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? accent : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if isSelected && menuBarIndicator == "pill" {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(accent.opacity(0.15))
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
