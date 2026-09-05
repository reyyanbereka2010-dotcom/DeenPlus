//
//  IslamicEventsView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/5/26.
//

import SwiftUI

struct IslamicEventsView: View {

    private let hijriManager = HijriCalendarManager.shared

    var body: some View {
        List {
            // Current Hijri Header
            Section {
                let current = hijriManager.getHijriDate()
                VStack(spacing: 8) {
                    Text(current.formattedAr)
                        .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 24))
                        .foregroundStyle(.green)

                    Text(current.formattedEn)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let event = current.event {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.orange)
                            Text("Today is \(event.title)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // All Key Islamic Events
            Section("Annual Islamic Observances") {
                ForEach(hijriManager.islamicEvents) { event in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: event.icon)
                            .font(.title2)
                            .foregroundStyle(.green)
                            .frame(width: 32)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(event.title)
                                    .font(.headline)

                                Spacer()

                                Text("\(event.hijriDay) \(hijriManager.hijriMonthNamesEn[event.hijriMonth - 1])")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            Text(event.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Islamic Events")
        .navigationBarTitleDisplayMode(.inline)
    }
}
