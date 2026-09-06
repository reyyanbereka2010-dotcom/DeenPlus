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

    private var accent: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    var body: some View {
        Group {
            if menuBarStyle == "standard" {
                // Native System Tab Bar
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

                    QuranView()
                        .tabItem {
                            Label("Quran", systemImage: "book.fill")
                        }
                        .tag(2)

                    DailyDuasView()
                        .tabItem {
                            Label("Duas", systemImage: "hands.sparkles.fill")
                        }
                        .tag(3)

                    QiblaView()
                        .tabItem {
                            Label("Qibla", systemImage: "location.north.fill")
                        }
                        .tag(4)

                    TasbihView()
                        .tabItem {
                            Label("Tasbih", systemImage: "circle.circle.fill")
                        }
                        .tag(5)

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(6)
                }
                .tint(accent)
                .onAppear {
                    let appearance = UITabBarAppearance()
                    appearance.configureWithDefaultBackground()
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            } else {
                // Modern Custom Navigation Menu Bar (Rectangular Pill or Floating Capsule)
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

                    // Bottom Custom Bar
                    if !hideTabBar {
                        CustomBottomMenuBar(
                            selectedTab: $selectedTab,
                            style: menuBarStyle
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
    }
}

// MARK: - Custom Bottom Navigation Bar

struct CustomBottomMenuBar: View {
    @Binding var selectedTab: Int
    let style: String
    @AppStorage("appAccentColor") private var appAccentColor: String = "emerald"

    private var accent: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(TabItemType.allCases) { item in
                Button {
                    #if canImport(UIKit)
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    #endif
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = item.rawValue
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == item.rawValue {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(accent.opacity(0.18))
                                    .frame(width: 40, height: 32)
                            }

                            Image(systemName: item.icon)
                                .font(.system(size: 16, weight: selectedTab == item.rawValue ? .semibold : .regular))
                                .foregroundStyle(selectedTab == item.rawValue ? accent : Color.secondary)
                        }
                        .frame(height: 32)

                        Text(item.title)
                            .font(.system(size: 10, weight: selectedTab == item.rawValue ? .bold : .medium))
                            .foregroundStyle(selectedTab == item.rawValue ? accent : Color.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, style == "floating" ? 12 : 28)
        .background(
            ZStack {
                if style == "floating" {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                } else {
                    // Modern Rectangular Pill Bar
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.regularMaterial)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                }
            }
            .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: -2)
        )
        .padding(.horizontal, style == "floating" ? 14 : 10)
        .padding(.bottom, style == "floating" ? 12 : 0)
    }
}

#Preview {
    ContentView()
        .environmentObject(PrayerManager())
}
