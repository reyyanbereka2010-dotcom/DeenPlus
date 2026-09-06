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
                        ZStack {
                            if isSelected {
                                switch menuBarIndicator {
                                case "pill":
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(accent.opacity(0.18))
                                        .frame(width: shouldShowLabels ? 38 : 42, height: shouldShowLabels ? 30 : 38)
                                case "glow":
                                    Circle()
                                        .fill(accent.opacity(0.35))
                                        .frame(width: 34, height: 34)
                                        .blur(radius: 5)
                                default:
                                    EmptyView()
                                }
                            }

                            Image(systemName: item.icon)
                                .font(.system(size: shouldShowLabels ? 16 : 19, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? accent : Color.secondary)
                        }
                        .frame(height: shouldShowLabels ? 30 : 38)

                        if shouldShowLabels {
                            Text(item.title)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? accent : Color.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        if isSelected {
                            if menuBarIndicator == "dot" {
                                Circle()
                                    .fill(accent)
                                    .frame(width: 4, height: 4)
                                    .padding(.top, shouldShowLabels ? 1 : 2)
                            } else if menuBarIndicator == "line" {
                                Capsule()
                                    .fill(accent)
                                    .frame(width: 16, height: 2.5)
                                    .padding(.top, shouldShowLabels ? 1 : 2)
                            }
                        } else if menuBarIndicator == "dot" || menuBarIndicator == "line" {
                            Color.clear
                                .frame(height: shouldShowLabels ? 5 : 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .offset(y: style == "dock" && isSelected ? -4 : 0)
                    .scaleEffect(style == "dock" && isSelected ? 1.08 : 1.0)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, style == "minimal" ? 4 : (style == "compact" ? 16 : 8))
        .padding(.top, style == "compact" ? 8 : 10)
        .padding(.bottom, bottomInnerPadding)
        .background(
            barBackgroundView
        )
        .padding(.horizontal, outerHorizontalPadding)
        .padding(.bottom, outerBottomPadding)
    }

    private var bottomInnerPadding: CGFloat {
        switch style {
        case "floating", "glass", "compact":
            return 10
        case "dock":
            return 12
        case "minimal":
            return 26
        default:
            return 28
        }
    }

    private var outerHorizontalPadding: CGFloat {
        switch style {
        case "floating", "glass":
            return 14
        case "compact":
            return 24
        case "dock":
            return 12
        case "minimal":
            return 0
        default:
            return 8
        }
    }

    private var outerBottomPadding: CGFloat {
        switch style {
        case "floating", "compact":
            return 12
        case "glass":
            return 14
        case "dock":
            return 10
        case "minimal":
            return 0
        default:
            return 0
        }
    }

    @ViewBuilder
    private var barBackgroundView: some View {
        switch style {
        case "floating":
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: -2)

        case "glass":
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(accent.opacity(0.06))
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(accent.opacity(0.32), lineWidth: 1.2)
            }
            .shadow(color: accent.opacity(0.22), radius: 16, x: 0, y: 4)

        case "minimal":
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 0.5)
            }

        case "dock":
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.regularMaterial)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.14), radius: 16, x: 0, y: 3)

        case "compact":
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                Capsule()
                    .stroke(Color.primary.opacity(0.09), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 2)

        default:
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.regularMaterial)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: -2)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PrayerManager())
}
