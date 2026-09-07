//
//  HomeView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Prayer Status Model

enum PrayerStatus {
    case isNow(name: String, time: String, minutesAgo: Int)
    case upcoming(name: String, time: String, timeRemaining: String)
    
    var prayerName: String {
        switch self {
        case .isNow(let name, _, _): return name
        case .upcoming(let name, _, _): return name
        }
    }
}

// MARK: - Daily Prayer Item for Mini-Timeline

struct DailyPrayerItem: Identifiable {
    let id = UUID()
    let name: String
    let rawTime: String
    let formattedTime: String
    let icon: String
    let isPassed: Bool
    let isCurrent: Bool
    let isNext: Bool
}

// MARK: - Daily Quran Verse Model

struct DailyAyah {
    let arabic: String
    let translation: String
    let surah: String
    let surahNumber: Int
    let ayahNumber: Int
}

struct HomeView: View {
    @State private var hideTabBar = false
    @Binding var selectedTab: Int
    @EnvironmentObject var prayerManager: PrayerManager
    @EnvironmentObject var locationManager: LocationManager
    
    @AppStorage("tasbih_total_count") private var totalTasbihCount: Int = 0
    
    @State private var currentTime = Date()
    @State private var animatePulse = false
    @State private var animateGlow = false
    @State private var recentlyRead: RecentlyRead? = nil
    @State private var showCopiedBanner = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let hijriManager = HijriCalendarManager.shared

    // MARK: - Cached Date Formatters
    private static let prayerFormatter24: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let prayerFormatterSingleHour: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "H:mm"
        return f
    }()

    private static let prayerDisplayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return f
    }()
    
    // Curated inspirational Ayat that rotate daily
    private let dailyVerses: [DailyAyah] = [
        DailyAyah(
            arabic: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا • إِنَّ مَعَ الْعُسْرِ يُسْرًا",
            translation: "For indeed, with hardship [will be] ease. Indeed, with hardship [will be] ease.",
            surah: "Ash-Sharh",
            surahNumber: 94,
            ayahNumber: 5
        ),
        DailyAyah(
            arabic: "وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ",
            translation: "And your Lord says, \"Call upon Me; I will respond to you.\"",
            surah: "Ghafir",
            surahNumber: 40,
            ayahNumber: 60
        ),
        DailyAyah(
            arabic: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
            translation: "Unquestionably, by the remembrance of Allah hearts are assured.",
            surah: "Ar-Ra'd",
            surahNumber: 13,
            ayahNumber: 28
        ),
        DailyAyah(
            arabic: "وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ",
            translation: "And whoever relies upon Allah - then He is sufficient for him.",
            surah: "At-Talaq",
            surahNumber: 65,
            ayahNumber: 3
        ),
        DailyAyah(
            arabic: "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ",
            translation: "And He is with you wherever you are.",
            surah: "Al-Hadid",
            surahNumber: 57,
            ayahNumber: 4
        ),
        DailyAyah(
            arabic: "إِنَّ اللَّهَ مَعَ الصَّابِرِينَ",
            translation: "Indeed, Allah is with the patient.",
            surah: "Al-Baqarah",
            surahNumber: 2,
            ayahNumber: 153
        ),
        DailyAyah(
            arabic: "وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ",
            translation: "My mercy encompasses all things.",
            surah: "Al-A'raf",
            surahNumber: 7,
            ayahNumber: 156
        ),
        DailyAyah(
            arabic: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
            translation: "Our Lord, give us in this world that which is good and in the Hereafter that which is good and protect us from the punishment of the Fire.",
            surah: "Al-Baqarah",
            surahNumber: 2,
            ayahNumber: 201
        )
    ]
    
    private var todayAyah: DailyAyah {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: currentTime) ?? 1
        return dailyVerses[dayOfYear % dailyVerses.count]
    }
    
    // MARK: - Prayer Calculations
    
    private var prayerList: [(name: String, time: String, icon: String)] {
        [
            ("Fajr", prayerManager.prayerTimes.fajr, "sunrise.fill"),
            ("Sunrise", prayerManager.prayerTimes.sunrise, "sun.and.horizon.fill"),
            ("Dhuhr", prayerManager.prayerTimes.dhuhr, "sun.max.fill"),
            ("Asr", prayerManager.prayerTimes.asr, "sun.haze.fill"),
            ("Maghrib", prayerManager.prayerTimes.maghrib, "sunset.fill"),
            ("Isha", prayerManager.prayerTimes.isha, "moon.stars.fill")
        ]
    }
    
    private func parsePrayerDate(from timeStr: String, baseDate: Date) -> Date? {
        let cleanTime = timeStr.components(separatedBy: " ").first ?? timeStr
        guard let parsed = Self.prayerFormatter24.date(from: cleanTime) ?? Self.prayerFormatterSingleHour.date(from: cleanTime) else { return nil }
        
        let cal = Calendar.current
        var components = cal.dateComponents([.hour, .minute], from: parsed)
        components.year = cal.component(.year, from: baseDate)
        components.month = cal.component(.month, from: baseDate)
        components.day = cal.component(.day, from: baseDate)
        return cal.date(from: components)
    }
    
    var currentPrayerStatus: PrayerStatus {
        let mainPrayers = [
            ("Fajr", prayerManager.prayerTimes.fajr),
            ("Dhuhr", prayerManager.prayerTimes.dhuhr),
            ("Asr", prayerManager.prayerTimes.asr),
            ("Maghrib", prayerManager.prayerTimes.maghrib),
            ("Isha", prayerManager.prayerTimes.isha)
        ]
        
        // 1. Check if any prayer is currently active (within 20 mins after start time)
        for prayer in mainPrayers {
            if let prayerDate = parsePrayerDate(from: prayer.1, baseDate: currentTime) {
                let elapsed = currentTime.timeIntervalSince(prayerDate)
                if elapsed >= 0 && elapsed <= 1200 {
                    let mins = Int(elapsed / 60)
                    return .isNow(name: prayer.0, time: formatTimeString(prayer.1), minutesAgo: mins)
                }
            }
        }
        
        // 2. Otherwise find next upcoming prayer today
        for prayer in mainPrayers {
            if let prayerDate = parsePrayerDate(from: prayer.1, baseDate: currentTime), prayerDate > currentTime {
                let diff = Int(prayerDate.timeIntervalSince(currentTime))
                let hours = diff / 3600
                let mins = (diff % 3600) / 60
                let secs = diff % 60
                
                let remainingString: String
                if hours > 0 {
                    remainingString = "in \(hours)h \(mins)m"
                } else if mins > 0 {
                    remainingString = "in \(mins)m \(secs)s"
                } else {
                    remainingString = "in \(secs)s"
                }
                
                return .upcoming(name: prayer.0, time: formatTimeString(prayer.1), timeRemaining: remainingString)
            }
        }
        
        // 3. If all passed today, tomorrow's Fajr
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: currentTime),
           let tomorrowFajr = parsePrayerDate(from: mainPrayers[0].1, baseDate: tomorrow) {
            let diff = max(0, Int(tomorrowFajr.timeIntervalSince(currentTime)))
            let hours = diff / 3600
            let mins = (diff % 3600) / 60
            let remainingString = "\(hours)h \(mins)m"
            return .upcoming(name: mainPrayers[0].0, time: formatTimeString(mainPrayers[0].1), timeRemaining: "in \(remainingString)")
        }
        
        return .upcoming(name: mainPrayers[0].0, time: formatTimeString(mainPrayers[0].1), timeRemaining: "")
    }
    
    var dailyTimeline: [DailyPrayerItem] {
        var items: [DailyPrayerItem] = []
        var nextFound = false
        
        for item in prayerList {
            let date = parsePrayerDate(from: item.time, baseDate: currentTime)
            let isPassed = (date != nil && date! < currentTime && currentTime.timeIntervalSince(date!) > 1200)
            let isCurrent: Bool
            if let d = date {
                let diff = currentTime.timeIntervalSince(d)
                isCurrent = (diff >= 0 && diff <= 1200)
            } else {
                isCurrent = false
            }
            
            let isNext: Bool
            if !nextFound && date != nil && date! > currentTime {
                isNext = true
                nextFound = true
            } else {
                isNext = false
            }
            
            items.append(DailyPrayerItem(
                name: item.name,
                rawTime: item.time,
                formattedTime: formatTimeString(item.time),
                icon: item.icon,
                isPassed: isPassed,
                isCurrent: isCurrent,
                isNext: isNext
            ))
        }
        
        // If all passed, highlight Fajr as next
        if !nextFound && !items.isEmpty {
            let first = items[0]
            items[0] = DailyPrayerItem(
                name: first.name,
                rawTime: first.rawTime,
                formattedTime: first.formattedTime,
                icon: first.icon,
                isPassed: false,
                isCurrent: false,
                isNext: true
            )
        }
        
        return items
    }
    
    private func formatTimeString(_ time: String) -> String {
        let cleanTime = time.components(separatedBy: " ").first ?? time
        if let date = Self.prayerFormatter24.date(from: cleanTime) ?? Self.prayerFormatterSingleHour.date(from: cleanTime) {
            return Self.prayerDisplayFormatter.string(from: date)
        }
        return time
    }
    
    // Dynamic greeting based on time of day
    var contextualGreeting: (title: String, arabic: String) {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 4..<12:
            return ("Good Morning", "صباح الخير والبركة")
        case 12..<17:
            return ("Good Afternoon", "تقبل الله طاعاتكم")
        case 17..<21:
            return ("Good Evening", "مساء الخير والسكينة")
        default:
            return ("Peaceful Night", "ليلة مباركة هادئة")
        }
    }
    
    var skyGradient: [Color] {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 4..<6:
            // Fajr: Mystical dawn twilight (deep purple into soft rose & orange)
            return [
                Color(red: 0.12, green: 0.08, blue: 0.28),
                Color(red: 0.35, green: 0.15, blue: 0.40),
                Color(red: 0.70, green: 0.30, blue: 0.38),
                Color(red: 0.92, green: 0.55, blue: 0.35)
            ]
        case 6..<9:
            // Sunrise / Early Morning: Bright optimistic golden dawn
            return [
                Color(red: 0.15, green: 0.35, blue: 0.65),
                Color(red: 0.35, green: 0.58, blue: 0.80),
                Color(red: 0.85, green: 0.68, blue: 0.45),
                Color(red: 0.98, green: 0.82, blue: 0.55)
            ]
        case 9..<16:
            // Dhuhr / Midday: Rich serene Islamic emerald-cyan day
            return [
                Color(red: 0.05, green: 0.38, blue: 0.48),
                Color(red: 0.08, green: 0.52, blue: 0.45),
                Color(red: 0.12, green: 0.65, blue: 0.52),
                Color(red: 0.20, green: 0.78, blue: 0.62)
            ]
        case 16..<18:
            // Asr: Warm golden afternoon glow
            return [
                Color(red: 0.18, green: 0.28, blue: 0.55),
                Color(red: 0.38, green: 0.40, blue: 0.60),
                Color(red: 0.78, green: 0.52, blue: 0.38),
                Color(red: 0.95, green: 0.70, blue: 0.38)
            ]
        case 18..<20:
            // Maghrib: Dramatic sunset red-orange into twilight indigo
            return [
                Color(red: 0.10, green: 0.08, blue: 0.30),
                Color(red: 0.42, green: 0.12, blue: 0.32),
                Color(red: 0.82, green: 0.25, blue: 0.25),
                Color(red: 0.95, green: 0.55, blue: 0.22)
            ]
        default:
            // Isha / Night: Majestic deep cosmic midnight blue with moonlight cyan undertone
            return [
                Color(red: 0.03, green: 0.05, blue: 0.15),
                Color(red: 0.06, green: 0.10, blue: 0.24),
                Color(red: 0.09, green: 0.18, blue: 0.35),
                Color(red: 0.12, green: 0.25, blue: 0.42)
            ]
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Living Dynamic Sky Gradient
                LinearGradient(
                    colors: skyGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 2.0), value: skyGradient)
                
                // Ambient Radial Glow in the Corner
                RadialGradient(
                    colors: [Color.white.opacity(0.18), Color.clear],
                    center: .topTrailing,
                    startRadius: 20,
                    endRadius: 400
                )
                .ignoresSafeArea()
                .blendMode(.overlay)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Top Header: Greeting, Islamic Date, Live Clock
                        headerView
                        
                        // Islamic Event Banner (if any today)
                        if let event = hijriManager.getHijriDate(for: currentTime).event {
                            islamicEventBanner(event: event)
                        }
                        
                        // Hero Next/Current Prayer Card
                        heroPrayerCard
                        
                        // Continue Reading Quran Quick-Access (if available)
                        if let read = recentlyRead {
                            continueReadingCard(read: read)
                        }
                        
                        // Daily Inspirational Ayah Card
                        dailyAyahCard
                        
                        // 2x2 Bento Quick Actions Grid
                        bentoGridSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onReceive(timer) { input in
                currentTime = input
            }
            .onAppear {
                recentlyRead = RecentlyReadManager.shared.load()
                prayerManager.fetchPrayerTimes(
                    latitude: locationManager.latitude,
                    longitude: locationManager.longitude
                )
            }
            .overlay(alignment: .top) {
                if showCopiedBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Ayah copied to clipboard")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                    .padding(.top, 50)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        let hijri = hijriManager.getHijriDate(for: currentTime)
        let greeting = contextualGreeting
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting.arabic)
                        .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 18))
                        .foregroundStyle(.white.opacity(0.85))
                    
                    Text(greeting.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                // Clock Pill
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currentTime, style: .time)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(currentTime, format: .dateTime.weekday(.wide))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.8))
                        .textCase(.uppercase)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
            }
            
            // Location Chip & Hijri Date Row
            HStack(spacing: 8) {
                // Location Chip
                Button {
                    triggerHaptic()
                    locationManager.requestLocation()
                    prayerManager.fetchPrayerTimes(
                        latitude: locationManager.latitude,
                        longitude: locationManager.longitude
                    )
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Text(
                            locationManager.city == "Unknown"
                            ? "Locating..."
                            : locationManager.city
                        )
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Hijri Date
                HStack(spacing: 5) {
                    Image(systemName: "moon.stars.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(hijri.formattedEn)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.95))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Islamic Event Banner
    
    private func islamicEventBanner(event: IslamicEvent) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.25))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's Islamic Observance")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                    .foregroundStyle(.orange)
                
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                )
        )
        .onTapGesture {
            triggerHaptic()
            selectedTab = 1
        }
    }
    
    // MARK: - Hero Prayer Card
    
    private var heroPrayerCard: some View {
        VStack(spacing: 18) {
            // Status Header Pill
            HStack {
                switch currentPrayerStatus {
                case .isNow(let name, let time, let minsAgo):
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animatePulse ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animatePulse)
                        
                        Text("PRAYER TIME NOW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.white)
                    .clipShape(Capsule())
                    .onAppear { animatePulse = true }
                    
                    Spacer()
                    
                    Text("\(name) began \(minsAgo)m ago (\(time))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    
                case .upcoming(_, _, let timeRemaining):
                    HStack(spacing: 6) {
                        Image(systemName: "hourglass")
                            .font(.caption2)
                        Text("NEXT PRAYER")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    if !timeRemaining.isEmpty {
                        Text(timeRemaining)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color(red: 0.65, green: 0.95, blue: 0.75))
                    }
                }
            }
            
            // Big Prayer Display
            switch currentPrayerStatus {
            case .isNow(let name, let time, _):
                HStack(alignment: .lastTextBaseline) {
                    Text(name)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(time)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                }
            case .upcoming(let name, let time, _):
                HStack(alignment: .lastTextBaseline) {
                    Text(name)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(time)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
            
            // Mini 5-Prayer Timeline Bar
            HStack(spacing: 6) {
                ForEach(dailyTimeline) { item in
                    VStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(
                                item.isCurrent ? Color.green :
                                (item.isNext ? Color.white : Color.white.opacity(item.isPassed ? 0.45 : 0.8))
                            )
                        
                        Text(item.name)
                            .font(.system(size: 11, weight: item.isNext || item.isCurrent ? .bold : .medium))
                            .foregroundStyle(
                                item.isCurrent ? Color.green :
                                (item.isNext ? Color.white : Color.white.opacity(item.isPassed ? 0.45 : 0.8))
                            )
                        
                        Text(item.formattedTime.replacingOccurrences(of: " ", with: ""))
                            .font(.system(size: 9, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.white.opacity(item.isPassed ? 0.35 : 0.75))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if item.isCurrent {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.25))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.green, lineWidth: 1.5)
                                    )
                            } else if item.isNext {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            }
                        }
                    )
                }
            }
            
            // Action Button: View Full Prayer Times
            Button {
                triggerHaptic(style: .medium)
                selectedTab = 1
            } label: {
                HStack(spacing: 8) {
                    Text("View Full Schedule & Adhan")
                        .font(.system(size: 15, weight: .semibold))
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .foregroundStyle(Color.black)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.16), radius: 6, y: 3)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 28, style: .continuous)
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
        .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Continue Reading Card
    
    private func continueReadingCard(read: RecentlyRead) -> some View {
        Button {
            triggerHaptic()
            selectedTab = 2
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.25))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("CONTINUE READING")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.green)
                        .tracking(0.5)
                    
                    Text("\(read.surahName)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Ayah \(read.verse) • Tap to resume")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
            )
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Daily Ayah Card
    
    private var dailyAyahCard: some View {
        let ayah = todayAyah
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.caption)
                        .foregroundStyle(Color.yellow)
                    
                    Text("AYAH OF THE DAY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .tracking(0.5)
                }
                
                Spacer()
                
                // Copy Button
                Button {
                    triggerHaptic()
                    #if canImport(UIKit)
                    UIPasteboard.general.string = "\(ayah.arabic)\n\n\"\(ayah.translation)\"\n— Surah \(ayah.surah) (\(ayah.surahNumber):\(ayah.ayahNumber))"
                    #endif
                    withAnimation(.spring()) {
                        showCopiedBanner = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            showCopiedBanner = false
                        }
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                
                // Share Link
                ShareLink(
                    item: "\(ayah.arabic)\n\n\"\(ayah.translation)\"\n— Surah \(ayah.surah) (\(ayah.surahNumber):\(ayah.ayahNumber)) via Deen+"
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            
            // Arabic Text
            Text(ayah.arabic)
                .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 22))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.white)
                .lineSpacing(10)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 4)
            
            // English Translation
            Text("\"\(ayah.translation)\"")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
            
            // Surah Reference & Quran Shortcut
            HStack {
                Text("Surah \(ayah.surah) • \(ayah.surahNumber):\(ayah.ayahNumber)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.yellow.opacity(0.9))
                
                Spacer()
                
                Button {
                    triggerHaptic()
                    selectedTab = 2
                } label: {
                    HStack(spacing: 4) {
                        Text("Open Surah")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.35), Color.white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }
    
    // MARK: - Modern 2x2 Bento Quick Actions
    
    private var bentoGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK EXPLORATION")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.75))
                .tracking(0.5)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                // Quran Tile
                BentoTile(
                    title: "Holy Quran",
                    subtitle: "114 Surahs & Recitation",
                    icon: "book.fill",
                    accentColor: Color(red: 0.2, green: 0.82, blue: 0.52),
                    badge: "Read"
                ) {
                    triggerHaptic()
                    selectedTab = 2
                }
                
                // Duas Tile
                BentoTile(
                    title: "Daily Duas",
                    subtitle: "Supplications & Adhkar",
                    icon: "hands.sparkles.fill",
                    accentColor: Color(red: 0.72, green: 0.48, blue: 0.98),
                    badge: "Daily"
                ) {
                    triggerHaptic()
                    selectedTab = 3
                }
                
                // Qibla Tile
                BentoTile(
                    title: "Qibla Compass",
                    subtitle: "Direction to Kaaba",
                    icon: "location.north.fill",
                    accentColor: Color(red: 0.95, green: 0.68, blue: 0.25),
                    badge: "Compass"
                ) {
                    triggerHaptic()
                    selectedTab = 4
                }
                
                // Tasbih Tile
                BentoTile(
                    title: "Digital Tasbih",
                    subtitle: totalTasbihCount > 0 ? "\(totalTasbihCount) recited" : "Dhikr Counter",
                    icon: "circle.circle.fill",
                    accentColor: Color(red: 0.25, green: 0.75, blue: 0.98),
                    badge: "Counter"
                ) {
                    triggerHaptic()
                    selectedTab = 5
                }
            }
        }
    }
    
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }
}

// MARK: - Bento Tile Component

struct BentoTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let badge: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.22))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(accentColor)
                    }
                    
                    Spacer()
                    
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [accentColor.opacity(0.4), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.14), radius: 8, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
        .environmentObject(PrayerManager())
        .environmentObject(LocationManager())
}
