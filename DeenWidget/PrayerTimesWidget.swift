//
//  PrayerTimesWidget.swift
//  DeenWidget
//
//  Created by Reyyan Bereka on 9/19/26.
//

import WidgetKit
import SwiftUI

struct PrayerEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String
    let nextPrayerDate: Date
    let formattedTime: String
    let iconName: String
    let locationName: String
    let dailyPrayers: [(name: String, time: String, isNext: Bool)]
}

struct PrayerTimesTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(
            date: Date(),
            nextPrayerName: "Dhuhr",
            nextPrayerDate: Date().addingTimeInterval(3600),
            formattedTime: "1:15 PM",
            iconName: "sun.max.fill",
            locationName: "Local Time",
            dailyPrayers: [
                ("Fajr", "5:30 AM", false),
                ("Dhuhr", "1:15 PM", true),
                ("Asr", "4:45 PM", false),
                ("Maghrib", "7:20 PM", false),
                ("Isha", "8:45 PM", false)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let now = Date()

        let userDefaults = UserDefaults(suiteName: "group.com.reyber.Deen") ?? UserDefaults.standard
        let lat = userDefaults.double(forKey: "user_latitude")
        let lng = userDefaults.double(forKey: "user_longitude")
        let activeLat = lat != 0 ? lat : 21.4225
        let activeLng = lng != 0 ? lng : 39.8262
        let city = userDefaults.string(forKey: "cached_location_city") ?? "Local Time"

        let entry = makeEntry(for: now, activeLat: activeLat, activeLng: activeLng, city: city)

        // Schedule next refresh right after the next prayer starts, or at most in 15 minutes
        let nextUpdate = entry.nextPrayerDate > now
            ? min(entry.nextPrayerDate.addingTimeInterval(10), now.addingTimeInterval(900))
            : now.addingTimeInterval(900)

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func makeEntry(for date: Date, activeLat: Double, activeLng: Double, city: String) -> PrayerEntry {
        let pt = PrayTimes()
        let times = pt.calculate(for: [activeLat, activeLng], date: date)

        let rawPrayers: [(name: String, timeStr: String, icon: String)] = [
            ("Fajr", times.fajr, "sunrise.fill"),
            ("Dhuhr", times.dhuhr, "sun.max.fill"),
            ("Asr", times.asr, "sun.max"),
            ("Maghrib", times.maghrib, "sunset.fill"),
            ("Isha", times.isha, "moon.stars.fill")
        ]

        struct ParsedPrayer {
            let name: String
            let date: Date
            let time12H: String
            let icon: String
        }

        var parsedPrayers: [ParsedPrayer] = []
        for p in rawPrayers {
            if let pDate = parsePrayerDate(from: p.timeStr, baseDate: date) {
                let time12H = formatTo12Hour(date: pDate)
                parsedPrayers.append(ParsedPrayer(name: p.name, date: pDate, time12H: time12H, icon: p.icon))
            }
        }

        var nextItem: ParsedPrayer? = nil

        // Find the first prayer today whose parsed date is strictly in the future
        for p in parsedPrayers {
            if p.date > date {
                nextItem = p
                break
            }
        }

        // If all prayers today have passed, calculate tomorrow's Fajr
        if nextItem == nil {
            if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) {
                let tomorrowTimes = pt.calculate(for: [activeLat, activeLng], date: tomorrow)
                if let tomorrowFajrDate = parsePrayerDate(from: tomorrowTimes.fajr, baseDate: tomorrow) {
                    let time12H = formatTo12Hour(date: tomorrowFajrDate)
                    nextItem = ParsedPrayer(name: "Fajr", date: tomorrowFajrDate, time12H: time12H, icon: "sunrise.fill")
                }
            }
        }

        let fallbackTime = parsedPrayers.first?.time12H ?? "5:30 AM"
        let finalNext = nextItem ?? ParsedPrayer(
            name: "Fajr",
            date: date.addingTimeInterval(3600),
            time12H: fallbackTime,
            icon: "sunrise.fill"
        )

        let dailyList = parsedPrayers.map { p in
            (name: p.name, time: p.time12H, isNext: p.name == finalNext.name)
        }

        return PrayerEntry(
            date: date,
            nextPrayerName: finalNext.name,
            nextPrayerDate: finalNext.date,
            formattedTime: finalNext.time12H,
            iconName: finalNext.icon,
            locationName: city,
            dailyPrayers: dailyList
        )
    }

    private func parsePrayerDate(from timeStr: String, baseDate: Date) -> Date? {
        let trimmed = timeStr.trimmingCharacters(in: .whitespacesAndNewlines)
        let isPM = trimmed.lowercased().contains("pm")
        let isAM = trimmed.lowercased().contains("am")

        let clean = trimmed.replacingOccurrences(of: "AM", with: "", options: .caseInsensitive)
                           .replacingOccurrences(of: "PM", with: "", options: .caseInsensitive)
                           .trimmingCharacters(in: .whitespacesAndNewlines)

        let components = clean.components(separatedBy: ":")
        guard components.count >= 2,
              var hour = Int(components[0].trimmingCharacters(in: .whitespaces)),
              let minute = Int(components[1].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }

        if isPM && hour < 12 {
            hour += 12
        } else if isAM && hour == 12 {
            hour = 0
        }

        let cal = Calendar.current
        var comp = cal.dateComponents([.year, .month, .day], from: baseDate)
        comp.hour = hour
        comp.minute = minute
        comp.second = 0
        return cal.date(from: comp)
    }

    private func formatTo12Hour(date: Date) -> String {
        let outFormatter = DateFormatter()
        outFormatter.locale = Locale(identifier: "en_US_POSIX")
        outFormatter.dateFormat = "h:mm a"
        return outFormatter.string(from: date)
    }
}

struct PrayerTimesWidgetEntryView: View {
    var entry: PrayerEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            largeView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: entry.iconName)
                    .font(.headline)
                    .foregroundStyle(Color.green)
                Spacer()
                Text(entry.formattedTime)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            Text(entry.nextPrayerName)
                .font(.title2)
                .bold()
                .foregroundStyle(.white)

            Text("Next Prayer")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))

            Text(entry.nextPrayerDate, style: .timer)
                .font(.headline)
                .bold()
                .monospacedDigit()
                .foregroundStyle(Color.green)
        }
        .padding()
        .containerBackground(Color(red: 0.08, green: 0.12, blue: 0.10), for: .widget)
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: entry.iconName)
                        .font(.title3)
                        .foregroundStyle(Color.green)
                    Text(entry.nextPrayerName)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.white)
                }

                Text(entry.locationName)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Text("Starts in")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))

                Text(entry.nextPrayerDate, style: .timer)
                    .font(.title2)
                    .bold()
                    .monospacedDigit()
                    .foregroundStyle(Color.green)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(Color.white.opacity(0.2))

            VStack(spacing: 4) {
                ForEach(entry.dailyPrayers, id: \.name) { p in
                    HStack {
                        Text(p.name)
                            .font(.caption)
                            .bold(p.isNext)
                            .foregroundStyle(p.isNext ? Color.green : .white.opacity(0.8))
                        Spacer()
                        Text(p.time)
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(p.isNext ? Color.green : .white.opacity(0.6))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(p.isNext ? Color.green.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .containerBackground(Color(red: 0.08, green: 0.12, blue: 0.10), for: .widget)
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deen+ Prayer Schedule")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)
                    Text(entry.locationName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundStyle(Color.green)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next: \(entry.nextPrayerName)")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.white)
                    Text(entry.formattedTime)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Text(entry.nextPrayerDate, style: .timer)
                    .font(.title)
                    .bold()
                    .monospacedDigit()
                    .foregroundStyle(Color.green)
            }
            .padding(10)
            .background(Color.green.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 6) {
                ForEach(entry.dailyPrayers, id: \.name) { p in
                    HStack {
                        Text(p.name)
                            .font(.subheadline)
                            .bold(p.isNext)
                            .foregroundStyle(p.isNext ? Color.green : .white)
                        Spacer()
                        Text(p.time)
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(p.isNext ? Color.green : .white.opacity(0.7))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(p.isNext ? Color.green.opacity(0.1) : Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .containerBackground(Color(red: 0.08, green: 0.12, blue: 0.10), for: .widget)
    }
}

struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesTimelineProvider()) { entry in
            PrayerTimesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("Track upcoming prayer times and real-time countdown.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
