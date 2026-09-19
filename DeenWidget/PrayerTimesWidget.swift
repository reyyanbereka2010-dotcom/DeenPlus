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

        let pt = PrayTimes()
        let times = pt.calculate(for: [activeLat, activeLng], date: now)

        let rawPrayers: [(name: String, timeStr: String, icon: String)] = [
            ("Fajr", times.fajr, "sunrise.fill"),
            ("Dhuhr", times.dhuhr, "sun.max.fill"),
            ("Asr", times.asr, "sun.max"),
            ("Maghrib", times.maghrib, "sunset.fill"),
            ("Isha", times.isha, "moon.stars.fill")
        ]

        var nextName = "Fajr"
        var nextDate = now.addingTimeInterval(3600)
        var nextFormatted = times.fajr
        var nextIcon = "sunrise.fill"

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for p in rawPrayers {
            formatter.dateFormat = "HH:mm"
            if let parsed = formatter.date(from: p.timeStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
                let cal = Calendar.current
                var comp = cal.dateComponents([.hour, .minute], from: parsed)
                comp.year = cal.component(.year, from: now)
                comp.month = cal.component(.month, from: now)
                comp.day = cal.component(.day, from: now)
                if let pDate = cal.date(from: comp), pDate > now {
                    nextName = p.name
                    nextDate = pDate
                    nextFormatted = p.timeStr
                    nextIcon = p.icon
                    break
                }
            }
        }

        let dailyList = rawPrayers.map { item in
            (name: item.name, time: item.timeStr, isNext: item.name == nextName)
        }

        let entry = PrayerEntry(
            date: now,
            nextPrayerName: nextName,
            nextPrayerDate: nextDate,
            formattedTime: nextFormatted,
            iconName: nextIcon,
            locationName: city,
            dailyPrayers: dailyList
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
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
