//
//  HijriCalendarManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/5/26.
//

import Foundation

struct IslamicEvent: Identifiable {
    let id = UUID()
    let hijriMonth: Int
    let hijriDay: Int
    let title: String
    let description: String
    let icon: String
}

struct HijriDateInfo {
    let day: Int
    let month: Int
    let year: Int
    let monthNameEn: String
    let monthNameAr: String
    let formattedEn: String
    let formattedAr: String
    let event: IslamicEvent?
}

class HijriCalendarManager {

    static let shared = HijriCalendarManager()

    private let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)

    let hijriMonthNamesEn = [
        "Muharram",
        "Safar",
        "Rabi' al-Awwal",
        "Rabi' al-Thani",
        "Jumada al-Awwal",
        "Jumada al-Thani",
        "Rajab",
        "Sha'ban",
        "Ramadan",
        "Shawwal",
        "Dhu al-Qi'dah",
        "Dhu al-Hijjah"
    ]

    let hijriMonthNamesAr = [
        "محرم",
        "صفر",
        "ربيع الأول",
        "ربيع الثاني",
        "جمادى الأولى",
        "جمادى الآخرة",
        "رجب",
        "شعبان",
        "رمضان",
        "شوال",
        "ذو القعدة",
        "ذو الحجة"
    ]

    let islamicEvents: [IslamicEvent] = [
        IslamicEvent(
            hijriMonth: 1,
            hijriDay: 1,
            title: "Islamic New Year",
            description: "1st of Muharram — beginning of the new Hijri calendar year.",
            icon: "sparkles"
        ),
        IslamicEvent(
            hijriMonth: 1,
            hijriDay: 10,
            title: "Day of Ashura",
            description: "10th of Muharram — Sunnah day of fasting commemorating Prophet Musa (AS).",
            icon: "moon.fill"
        ),
        IslamicEvent(
            hijriMonth: 3,
            hijriDay: 12,
            title: "Mawlid al-Nabi",
            description: "12th of Rabi' al-Awwal — birth of the Prophet Muhammad (SAW).",
            icon: "star.fill"
        ),
        IslamicEvent(
            hijriMonth: 7,
            hijriDay: 27,
            title: "Al-Isra' wal-Mi'raj",
            description: "27th of Rajab — The miraculous Night Journey & Ascension.",
            icon: "arrow.up.heart.fill"
        ),
        IslamicEvent(
            hijriMonth: 8,
            hijriDay: 15,
            title: "Nisfu Sha'ban",
            description: "15th of Sha'ban — Night of forgiveness and preparation for Ramadan.",
            icon: "moon.stars.fill"
        ),
        IslamicEvent(
            hijriMonth: 9,
            hijriDay: 1,
            title: "First Day of Ramadan",
            description: "1st of Ramadan — The blessed month of fasting begins.",
            icon: "moon.fill"
        ),
        IslamicEvent(
            hijriMonth: 9,
            hijriDay: 27,
            title: "Laylat al-Qadr (Estimated)",
            description: "The Night of Power, better than a thousand months.",
            icon: "sparkles"
        ),
        IslamicEvent(
            hijriMonth: 10,
            hijriDay: 1,
            title: "Eid al-Fitr",
            description: "1st of Shawwal — Festival marking the completion of Ramadan.",
            icon: "gift.fill"
        ),
        IslamicEvent(
            hijriMonth: 12,
            hijriDay: 1,
            title: "First 10 Days of Dhul Hijjah",
            description: "The best days of the year for righteous deeds.",
            icon: "sun.max.fill"
        ),
        IslamicEvent(
            hijriMonth: 12,
            hijriDay: 9,
            title: "Day of Arafah",
            description: "The pinnacle of Hajj — Fasting this day expiates sins of two years.",
            icon: "heart.fill"
        ),
        IslamicEvent(
            hijriMonth: 12,
            hijriDay: 10,
            title: "Eid al-Adha",
            description: "Festival of the Sacrifice commemorating the legacy of Prophet Ibrahim (AS).",
            icon: "star.circle.fill"
        ),
        IslamicEvent(
            hijriMonth: 12,
            hijriDay: 11,
            title: "Days of Tashreeq",
            description: "Days of eating, drinking, and remembrance of Allah.",
            icon: "sun.haze.fill"
        )
    ]

    func getHijriDate(for date: Date = Date()) -> HijriDateInfo {
        let components = hijriCalendar.dateComponents([.year, .month, .day], from: date)
        let day = components.day ?? 1
        let month = components.month ?? 1
        let year = components.year ?? 1448

        let monthIdx = max(0, min(month - 1, 11))
        let monthEn = hijriMonthNamesEn[monthIdx]
        let monthAr = hijriMonthNamesAr[monthIdx]

        let formattedEn = "\(day) \(monthEn) \(year) AH"
        let formattedAr = "\(day) \(monthAr) \(year) هـ"

        let matchingEvent = islamicEvents.first {
            $0.hijriMonth == month && $0.hijriDay == day
        }

        return HijriDateInfo(
            day: day,
            month: month,
            year: year,
            monthNameEn: monthEn,
            monthNameAr: monthAr,
            formattedEn: formattedEn,
            formattedAr: formattedAr,
            event: matchingEvent
        )
    }

    /// Returns upcoming Islamic events starting from today
    func getUpcomingEvents(limit: Int = 5) -> [IslamicEvent] {
        let current = getHijriDate()
        var events = islamicEvents

        // Sort events relative to current Hijri month & day
        events.sort { a, b in
            let aScore = (a.hijriMonth < current.month || (a.hijriMonth == current.month && a.hijriDay < current.day)) ? (a.hijriMonth * 30 + a.hijriDay + 360) : (a.hijriMonth * 30 + a.hijriDay)
            let bScore = (b.hijriMonth < current.month || (b.hijriMonth == current.month && b.hijriDay < current.day)) ? (b.hijriMonth * 30 + b.hijriDay + 360) : (b.hijriMonth * 30 + b.hijriDay)
            return aScore < bScore
        }

        return Array(events.prefix(limit))
    }
}
