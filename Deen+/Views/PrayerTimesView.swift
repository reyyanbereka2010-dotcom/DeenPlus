import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

struct PrayerTimesView: View {

    @EnvironmentObject var prayerManager: PrayerManager
    @State private var showingMonthlyCalendar = false
    @State private var showingIslamicEvents = false
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let hijriManager = HijriCalendarManager.shared

    private struct PrayerItem {
        let name: String
        let time: String
        let icon: String
        let isSalah: Bool
        let isNext: Bool
        let isCurrent: Bool
        let timeRemaining: String?
    }

    private var calculatedPrayers: [PrayerItem] {
        let rawPrayers: [(name: String, time: String, icon: String, isSalah: Bool)] = [
            ("Fajr", prayerManager.prayerTimes.fajr, "sunrise.fill", true),
            ("Sunrise", prayerManager.prayerTimes.sunrise, "sun.min.fill", false),
            ("Dhuhr", prayerManager.prayerTimes.dhuhr, "sun.max.fill", true),
            ("Asr", prayerManager.prayerTimes.asr, "sun.max", true),
            ("Maghrib", prayerManager.prayerTimes.maghrib, "sunset.fill", true),
            ("Isha", prayerManager.prayerTimes.isha, "moon.stars.fill", true)
        ]

        let salahOnly = rawPrayers.filter { $0.isSalah }

        // 1. Check if any salah is currently active (within 20 mins after start time)
        var currentSalahName: String? = nil
        for prayer in salahOnly {
            if let prayerDate = parsePrayerDate(from: prayer.time, baseDate: currentTime) {
                let elapsed = currentTime.timeIntervalSince(prayerDate)
                if elapsed >= 0 && elapsed <= 1200 {
                    currentSalahName = prayer.name
                    break
                }
            }
        }

        // 2. Find next upcoming prayer today
        var nextSalahName: String? = nil
        var nextRemainingString: String? = nil

        for prayer in salahOnly {
            if let prayerDate = parsePrayerDate(from: prayer.time, baseDate: currentTime), prayerDate > currentTime {
                nextSalahName = prayer.name
                let diff = max(0, Int(prayerDate.timeIntervalSince(currentTime)))
                nextRemainingString = formatRemaining(diff)
                break
            }
        }

        // 3. If all prayers have passed today, tomorrow's Fajr is next
        if nextSalahName == nil {
            if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: currentTime),
               let tomorrowFajr = parsePrayerDate(from: prayerManager.prayerTimes.fajr, baseDate: tomorrow) {
                nextSalahName = "Fajr"
                let diff = max(0, Int(tomorrowFajr.timeIntervalSince(currentTime)))
                nextRemainingString = formatRemaining(diff)
            } else {
                nextSalahName = "Fajr"
            }
        }

        return rawPrayers.map { p in
            let isNext = (p.name == nextSalahName)
            let isCurrent = (p.name == currentSalahName)
            let remaining = isNext ? nextRemainingString : nil
            return PrayerItem(
                name: p.name,
                time: p.time,
                icon: p.icon,
                isSalah: p.isSalah,
                isNext: isNext,
                isCurrent: isCurrent,
                timeRemaining: remaining
            )
        }
    }

    private func formatRemaining(_ diff: Int) -> String {
        let hours = diff / 3600
        let mins = (diff % 3600) / 60
        let secs = diff % 60
        if hours > 0 {
            return "in \(hours)h \(mins)m"
        } else if mins > 0 {
            return "in \(mins)m \(secs)s"
        } else {
            return "in \(secs)s"
        }
    }

    private func parsePrayerDate(from timeString: String, baseDate: Date) -> Date? {
        let cleanTime = timeString.components(separatedBy: " ").first ?? timeString
        let cal = Calendar.current

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"

        var parsed = formatter.date(from: cleanTime)
        if parsed == nil {
            formatter.dateFormat = "H:mm"
            parsed = formatter.date(from: cleanTime)
        }
        guard let parsedDate = parsed else { return nil }

        var components = cal.dateComponents([.hour, .minute], from: parsedDate)
        components.year = cal.component(.year, from: baseDate)
        components.month = cal.component(.month, from: baseDate)
        components.day = cal.component(.day, from: baseDate)
        components.second = 0
        return cal.date(from: components)
    }

    var body: some View {
        NavigationStack {
            List {
                // Hijri Date Banner Card
                Section {
                    let hijri = hijriManager.getHijriDate()
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(hijri.formattedEn)
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Text(hijri.formattedAr)
                                    .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 18))
                                    .foregroundStyle(.green)
                            }

                            Spacer()

                            Image(systemName: "moon.stars.circle.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(.green)
                        }

                        if let event = hijri.event {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.orange)
                                Text("Today: \(event.title)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Quick Navigation Shortcuts
                Section {
                    NavigationLink {
                        MonthlyCalendarView()
                    } label: {
                        Label("Monthly Prayer Schedule", systemImage: "calendar")
                    }

                    NavigationLink {
                        IslamicEventsView()
                    } label: {
                        Label("Islamic Calendar & Observances", systemImage: "star.fill")
                    }
                }

                // Daily Prayer Times
                Section("Today's Timings") {
                    if prayerManager.isLoading {
                        ProgressView("Calculating prayer times...")
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(calculatedPrayers, id: \.name) { prayer in
                            PrayerRow(
                                name: prayer.name,
                                time: prayer.time,
                                icon: prayer.icon,
                                isNext: prayer.isNext,
                                isCurrent: prayer.isCurrent,
                                timeRemaining: prayer.timeRemaining
                            )
                            .listRowBackground(
                                prayer.isNext
                                ? Color.green.opacity(0.14)
                                : (prayer.isCurrent ? Color.blue.opacity(0.10) : nil)
                            )
                        }
                    }
                }
            }
            .navigationTitle("Prayer Times")
            .safeAreaPadding(.bottom, 60)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MonthlyCalendarView()
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .onReceive(timer) { newTime in
                currentTime = newTime
            }
        }
    }
}

#Preview {
    PrayerTimesView()
        .environmentObject(PrayerManager())
}

struct PrayerRow: View {

    let name: String
    let time: String
    let icon: String
    var isNext: Bool = false
    var isCurrent: Bool = false
    var timeRemaining: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isNext ? Color.green.opacity(0.18) : (isCurrent ? Color.blue.opacity(0.16) : Color.clear))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: isNext ? .bold : .medium))
                    .foregroundStyle(isNext ? Color.green : (name == "Sunrise" ? Color.orange : (isCurrent ? Color.blue : Color.green)))
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(isNext ? .headline.weight(.bold) : .headline)
                        .foregroundStyle(isNext ? Color.green : Color.primary)

                    if isNext {
                        Text("NEXT")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Color.green, in: Capsule())
                    } else if isCurrent {
                        Text("NOW")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Color.blue, in: Capsule())
                    }
                }

                if name == "Sunrise" {
                    Text("Shurooq")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(convertTime(time))
                    .font(isNext ? .headline.weight(.bold) : .body)
                    .foregroundStyle(isNext ? Color.green : Color.primary)

                if let remaining = timeRemaining, isNext {
                    Text(remaining)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                } else if isCurrent {
                    Text("Active now")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, isNext ? 10 : 8)
        .contentShape(Rectangle())
        .onTapGesture {
            #if canImport(UIKit)
            let impact = UIImpactFeedbackGenerator(style: isNext ? .medium : .light)
            impact.impactOccurred()
            #endif
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(convertTime(time))\(isNext ? ", Next prayer, \(timeRemaining ?? "")" : "")\(isCurrent ? ", Active now" : "")")
    }

    func convertTime(_ time: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"

        let cleanTime = time.components(separatedBy: " ").first ?? time

        guard let date = formatter.date(from: cleanTime) else {
            return time
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "h:mm a"

        return displayFormatter.string(from: date)
    }
}
