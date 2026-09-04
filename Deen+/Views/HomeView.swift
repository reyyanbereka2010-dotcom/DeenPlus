//
//  HomeView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum PrayerStatus {
    case isNow(name: String, time: String, minutesAgo: Int)
    case upcoming(name: String, time: String)
    
    var prayerName: String {
        switch self {
        case .isNow(let name, _, _): return name
        case .upcoming(let name, _): return name
        }
    }
}

struct HomeView: View {
    @State private var hideTabBar = false
    @Binding var selectedTab: Int
    @EnvironmentObject var prayerManager: PrayerManager
    @StateObject private var locationManager = LocationManager()
    
    @State private var animatePulse = false
    @State private var animateGlow = false
    
    var currentPrayerStatus: PrayerStatus {
        let prayers = [
            ("Fajr", prayerManager.prayerTimes.fajr),
            ("Dhuhr", prayerManager.prayerTimes.dhuhr),
            ("Asr", prayerManager.prayerTimes.asr),
            ("Maghrib", prayerManager.prayerTimes.maghrib),
            ("Isha", prayerManager.prayerTimes.isha)
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        
        let calendar = Calendar.current
        let now = Date()
        
        // 1. Check if any prayer is currently active (within 20 minutes past start time)
        for prayer in prayers {
            let cleanTime = prayer.1.components(separatedBy: " ").first ?? prayer.1
            guard let timeDate = formatter.date(from: cleanTime) else { continue }
            
            var components = calendar.dateComponents([.hour, .minute], from: timeDate)
            components.year = calendar.component(.year, from: now)
            components.month = calendar.component(.month, from: now)
            components.day = calendar.component(.day, from: now)
            
            if let prayerDate = calendar.date(from: components) {
                let elapsed = now.timeIntervalSince(prayerDate)
                // Between 0 and 20 minutes (1200 seconds) after prayer start time
                if elapsed >= 0 && elapsed <= 1200 {
                    let mins = Int(elapsed / 60)
                    return .isNow(name: prayer.0, time: formatTimeString(prayer.1), minutesAgo: mins)
                }
            }
        }
        
        // 2. Otherwise find next upcoming prayer
        for prayer in prayers {
            let cleanTime = prayer.1.components(separatedBy: " ").first ?? prayer.1
            guard let timeDate = formatter.date(from: cleanTime) else { continue }
            
            var components = calendar.dateComponents([.hour, .minute], from: timeDate)
            components.year = calendar.component(.year, from: now)
            components.month = calendar.component(.month, from: now)
            components.day = calendar.component(.day, from: now)
            
            if let prayerDate = calendar.date(from: components), prayerDate > now {
                return .upcoming(name: prayer.0, time: formatTimeString(prayer.1))
            }
        }
        
        // If all passed today, tomorrow's Fajr
        return .upcoming(name: prayers[0].0, time: formatTimeString(prayers[0].1))
    }
    
    private func formatTimeString(_ time: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "h:mm a"
        
        let cleanTime = time.components(separatedBy: " ").first ?? time
        if let date = formatter.date(from: cleanTime) {
            return displayFormatter.string(from: date)
        }
        return time
    }
    
    var prayerIcon: String {
        switch currentPrayerStatus.prayerName {
        case "Fajr":
            return "sunrise.fill"
        case "Dhuhr":
            return "sun.max.fill"
        case "Asr":
            return "sun.haze.fill"
        case "Maghrib":
            return "sunset.fill"
        case "Isha":
            return "moon.stars.fill"
        default:
            return "sun.max.fill"
        }
    }
    
    var skyGradient: [Color] {
        switch currentPrayerStatus.prayerName {
        case "Fajr":
            return [
                Color(red: 0.12, green: 0.16, blue: 0.38),
                Color(red: 0.45, green: 0.28, blue: 0.52),
                Color(red: 0.88, green: 0.52, blue: 0.42)
            ]
        case "Dhuhr":
            return [
                Color(red: 0.05, green: 0.42, blue: 0.85),
                Color(red: 0.22, green: 0.65, blue: 0.95),
                Color(red: 0.55, green: 0.85, blue: 0.98)
            ]
        case "Asr":
            return [
                Color(red: 0.15, green: 0.28, blue: 0.58),
                Color(red: 0.75, green: 0.48, blue: 0.28),
                Color(red: 0.95, green: 0.72, blue: 0.35)
            ]
        case "Maghrib":
            return [
                Color(red: 0.18, green: 0.08, blue: 0.32),
                Color(red: 0.58, green: 0.18, blue: 0.38),
                Color(red: 0.88, green: 0.38, blue: 0.25)
            ]
        case "Isha":
            return [
                Color(red: 0.03, green: 0.05, blue: 0.14),
                Color(red: 0.08, green: 0.12, blue: 0.28),
                Color(red: 0.02, green: 0.03, blue: 0.10)
            ]
        default:
            return [Color.blue, Color.cyan]
        }
    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()
    
    private func triggerHaptic() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Smooth Dynamic Sky Gradient Background
                LinearGradient(
                    colors: skyGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle Ambient Light Orbs (Out of the way of content)
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 260, height: 260)
                        .blur(radius: 50)
                        .offset(x: -120, y: -220)
                        .scaleEffect(animateGlow ? 1.15 : 0.9)
                    
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 320, height: 320)
                        .blur(radius: 60)
                        .offset(x: 140, y: 180)
                        .scaleEffect(animateGlow ? 0.9 : 1.12)
                }
                .animation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true), value: animateGlow)
                
                ScrollView(showsIndicators: false) {
                    ScrollDetector(hideTabBar: $hideTabBar)
                        .frame(height: 0)
                    
                    VStack(spacing: 22) {
                        // Header Greeting & Location
                        VStack(spacing: 8) {
                            Text("Assalamu Alaikum")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                Text(
                                    locationManager.city == "Unknown"
                                    ? "Locating..."
                                    : locationManager.city
                                )
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                            
                            Text(dateFormatter.string(from: Date()))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.top, 2)
                        }
                        .padding(.top, 10)
                        
                        // Hero Prayer Card (Frosted Glass Container)
                        VStack(spacing: 18) {
                            // Active Status Indicator or Next Prayer Label
                            switch currentPrayerStatus {
                            case .isNow(let name, let time, let minsAgo):
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 10, height: 10)
                                        .scaleEffect(animatePulse ? 1.35 : 1.0)
                                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animatePulse)
                                    
                                    Text("PRAYER TIME IS NOW")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.green)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(.white)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.15), radius: 4)
                                .onAppear { animatePulse = true }
                                
                                Image(systemName: prayerIcon)
                                    .font(.system(size: 64))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                
                                VStack(spacing: 4) {
                                    Text("\(name) Prayer")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    
                                    Text(minsAgo == 0 ? "Started just now (\(time))" : "Started \(minsAgo) min\(minsAgo == 1 ? "" : "s") ago (\(time))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                                
                            case .upcoming(let name, let time):
                                Text("Next Prayer")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .textCase(.uppercase)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .tracking(1.2)
                                
                                Image(systemName: prayerIcon)
                                    .font(.system(size: 68))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                
                                VStack(spacing: 4) {
                                    Text(name)
                                        .font(.system(size: 38, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    
                                    Text(time)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white.opacity(0.95))
                                }
                            }
                            
                            Button {
                                triggerHaptic()
                                selectedTab = 1
                            } label: {
                                HStack(spacing: 8) {
                                    Text("View Prayer Times")
                                        .font(.headline)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 13)
                                .background(Color.white)
                                .foregroundStyle(Color.black)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 26)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.5), .white.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.2
                                    )
                            }
                        )
                        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 8)
                        .padding(.horizontal, 20)
                        
                        // Sleek Quick Action Cards Bar (Qibla, Tasbih, Quran)
                        HStack(spacing: 12) {
                            QuickActionCard(
                                title: "Qibla",
                                subtitle: "Direction",
                                icon: "location.north.fill",
                                color: .green
                            ) {
                                triggerHaptic()
                                selectedTab = 2
                            }
                            
                            QuickActionCard(
                                title: "Tasbih",
                                subtitle: "Counter",
                                icon: "circle.circle.fill",
                                color: .teal
                            ) {
                                triggerHaptic()
                                selectedTab = 3
                            }
                            
                            QuickActionCard(
                                title: "Quran",
                                subtitle: "Read",
                                icon: "book.fill",
                                color: Color(red: 0.2, green: 0.8, blue: 0.5)
                            ) {
                                triggerHaptic()
                                selectedTab = 4
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .onAppear {
            animateGlow = true
            locationManager.requestLocation()
            prayerManager.fetchPrayerTimes(
                latitude: locationManager.latitude,
                longitude: locationManager.longitude
            )
        }
        .onChange(of: locationManager.latitude) { newLat in
            prayerManager.fetchPrayerTimes(
                latitude: newLat,
                longitude: locationManager.longitude
            )
        }
    }
}

// MARK: - Individual Quick Action Card Component

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.22))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.45), .white.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
        .environmentObject(PrayerManager())
}
