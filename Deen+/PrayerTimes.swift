//
//  PrayerTimes.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/19/26.
//

import Foundation

struct PrayerTimes: Codable, Sendable {

    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String

    // MARK: - Islamic Night & Voluntary Prayer Timings (Tahajjud & Midnight)

    struct NightTimings: Sendable {
        let midnightDate: Date
        let tahajjudDate: Date
        let formattedMidnight: String
        let formattedTahajjud: String
        let isTahajjudActiveNow: Bool
    }

    /// Computes Islamic Midnight (Midpoint between Maghrib and Fajr)
    /// and Last Third of the Night (Tahajjud / Qiyam al-Layl start time).
    func calculateNightTimings(for baseDate: Date = Date()) -> NightTimings? {
        let formatter24 = DateFormatter()
        formatter24.locale = Locale(identifier: "en_US_POSIX")
        formatter24.dateFormat = "HH:mm"

        let formatterSingle = DateFormatter()
        formatterSingle.locale = Locale(identifier: "en_US_POSIX")
        formatterSingle.dateFormat = "H:mm"

        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "en_US_POSIX")
        displayFormatter.dateFormat = "h:mm a"

        func parseTime(_ str: String, on refDate: Date) -> Date? {
            let clean = str.components(separatedBy: " ").first ?? str
            guard let parsed = formatter24.date(from: clean) ?? formatterSingle.date(from: clean) else { return nil }
            let cal = Calendar.current
            var comp = cal.dateComponents([.hour, .minute], from: parsed)
            comp.year = cal.component(.year, from: refDate)
            comp.month = cal.component(.month, from: refDate)
            comp.day = cal.component(.day, from: refDate)
            comp.second = 0
            return cal.date(from: comp)
        }

        let cal = Calendar.current
        guard let maghribToday = parseTime(maghrib, on: baseDate) else { return nil }

        // Determine the relevant night window (Maghrib evening to Fajr morning)
        let relevantMaghrib: Date
        let relevantFajr: Date

        if baseDate >= maghribToday {
            // It's after Maghrib today; Fajr is tomorrow morning
            relevantMaghrib = maghribToday
            let tomorrow = cal.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
            guard let fajrTomorrow = parseTime(fajr, on: tomorrow) else { return nil }
            relevantFajr = fajrTomorrow
        } else {
            // It's before Maghrib today. If it's early morning before Fajr, the night started yesterday Maghrib
            guard let fajrToday = parseTime(fajr, on: baseDate) else { return nil }
            if baseDate < fajrToday {
                // Currently in the early morning part of last night
                let yesterday = cal.date(byAdding: .day, value: -1, to: baseDate) ?? baseDate
                guard let maghribYesterday = parseTime(maghrib, on: yesterday) else { return nil }
                relevantMaghrib = maghribYesterday
                relevantFajr = fajrToday
            } else {
                // Daytime (between Fajr and Maghrib): show tonight's upcoming night timings
                relevantMaghrib = maghribToday
                let tomorrow = cal.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
                guard let fajrTomorrow = parseTime(fajr, on: tomorrow) else { return nil }
                relevantFajr = fajrTomorrow
            }
        }

        let nightLength = relevantFajr.timeIntervalSince(relevantMaghrib)
        guard nightLength > 0 else { return nil }

        let midnightDate = relevantMaghrib.addingTimeInterval(nightLength * 0.5)
        let tahajjudDate = relevantMaghrib.addingTimeInterval(nightLength * (2.0 / 3.0))
        let isActiveNow = baseDate >= tahajjudDate && baseDate < relevantFajr

        return NightTimings(
            midnightDate: midnightDate,
            tahajjudDate: tahajjudDate,
            formattedMidnight: displayFormatter.string(from: midnightDate),
            formattedTahajjud: displayFormatter.string(from: tahajjudDate),
            isTahajjudActiveNow: isActiveNow
        )
    }
}
