//
//  AyahWidget.swift
//  DeenWidget
//
//  Created by Reyyan Bereka on 9/19/26.
//

import WidgetKit
import SwiftUI

struct AyahEntry: TimelineEntry {
    let date: Date
    let arabicText: String
    let englishText: String
    let surahInfo: String
}

struct AyahTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AyahEntry {
        AyahEntry(
            date: Date(),
            arabicText: "إِنَّ مَعَ الْعُسْرِ يُسْرًا",
            englishText: "Indeed, with hardship will come ease.",
            surahInfo: "Surah Ash-Sharh (94:6)"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AyahEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AyahEntry>) -> Void) {
        let entry = placeholder(in: context)
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86400)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct AyahWidgetEntryView: View {
    var entry: AyahEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundStyle(Color.green)
                Text("Ayah of the Day")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(Color.green)
                Spacer()
            }

            Text(entry.arabicText)
                .font(.system(size: family == .systemLarge ? 20 : 16, weight: .bold, design: .serif))
                .multilineTextAlignment(.leading)
                .foregroundStyle(.white)
                .lineLimit(family == .systemSmall ? 2 : 3)

            Text(entry.englishText)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(family == .systemSmall ? 2 : 3)

            Spacer()

            Text(entry.surahInfo)
                .font(.caption2)
                .bold()
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding()
        .containerBackground(Color(red: 0.08, green: 0.12, blue: 0.10), for: .widget)
    }
}

struct AyahWidget: Widget {
    let kind: String = "AyahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AyahTimelineProvider()) { entry in
            AyahWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Ayah of the Day")
        .description("Daily Quranic verse reflection.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
