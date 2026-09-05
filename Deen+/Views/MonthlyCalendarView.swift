//
//  MonthlyCalendarView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/5/26.
//

import SwiftUI

struct DayPrayerSchedule: Identifiable, Equatable {
    static func == (lhs: DayPrayerSchedule, rhs: DayPrayerSchedule) -> Bool {
        lhs.date == rhs.date && lhs.times.fajr == rhs.times.fajr
    }
    let id = UUID()
    let date: Date
    let gregorianDay: Int
    let weekday: String
    let hijriInfo: HijriDateInfo
    let times: PrayerTimes
    let isToday: Bool
}

struct MonthlyCalendarView: View {

    @EnvironmentObject var prayerManager: PrayerManager
    @StateObject private var locationManager = LocationManager()
    @State private var selectedMonthOffset: Int = 0 // 0 = current month, -1 = last, +1 = next

    private let calendar = Calendar.current

    private var currentMonthDate: Date {
        calendar.date(byAdding: .month, value: selectedMonthOffset, to: Date()) ?? Date()
    }

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonthDate)
    }

    private var hijriMonthTitle: String {
        let hijri = HijriCalendarManager.shared.getHijriDate(for: currentMonthDate)
        return "\(hijri.monthNameEn) \(hijri.year) AH"
    }

    private var daysInMonth: [DayPrayerSchedule] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonthDate),
              let daysRange = calendar.range(of: .day, in: .month, for: currentMonthDate) else {
            return []
        }

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEE"

        let today = Date()

        return daysRange.compactMap { day -> DayPrayerSchedule? in
            guard let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) else {
                return nil
            }

            let hijri = HijriCalendarManager.shared.getHijriDate(for: dayDate)
            let lat = locationManager.latitude != 0 ? locationManager.latitude : nil
            let lon = locationManager.longitude != 0 ? locationManager.longitude : nil
            let times = prayerManager.timesForDate(dayDate, latitude: lat, longitude: lon)
            let isToday = calendar.isDate(dayDate, inSameDayAs: today)

            return DayPrayerSchedule(
                date: dayDate,
                gregorianDay: day,
                weekday: weekdayFormatter.string(from: dayDate),
                hijriInfo: hijri,
                times: times,
                isToday: isToday
            )
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month Selector Header
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { selectedMonthOffset -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .padding(8)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(monthYearTitle)
                            .font(.headline)
                            .fontWeight(.bold)

                        Text(hijriMonthTitle)
                            .font(.caption)
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { selectedMonthOffset += 1 }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))

                Divider()

                // Column Headers
                HStack(spacing: 0) {
                    Text("Day")
                        .frame(width: 60, alignment: .leading)
                    Spacer()
                    Text("Fajr")
                        .frame(width: 48, alignment: .center)
                    Spacer()
                    Text("Dhuhr")
                        .frame(width: 48, alignment: .center)
                    Spacer()
                    Text("Asr")
                        .frame(width: 48, alignment: .center)
                    Spacer()
                    Text("Maghrib")
                        .frame(width: 50, alignment: .center)
                    Spacer()
                    Text("Isha")
                        .frame(width: 48, alignment: .center)
                }
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemGroupedBackground))

                Divider()

                // Monthly Table
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(daysInMonth, id: \.date) { day in
                                HStack(spacing: 0) {
                                    // Date Column
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 4) {
                                            Text("\(day.gregorianDay)")
                                                .font(.subheadline)
                                                .fontWeight(day.isToday ? .bold : .medium)
                                                .foregroundStyle(day.isToday ? .green : .primary)

                                            Text(day.weekday)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }

                                        Text("\(day.hijriInfo.day) \(day.hijriInfo.monthNameEn.prefix(3))")
                                            .font(.system(size: 9))
                                            .foregroundStyle(day.hijriInfo.event != nil ? .orange : .secondary)
                                    }
                                    .frame(width: 60, alignment: .leading)

                                    Spacer()

                                    Text(formatShortTime(day.times.fajr))
                                        .frame(width: 48, alignment: .center)
                                    Spacer()
                                    Text(formatShortTime(day.times.dhuhr))
                                        .frame(width: 48, alignment: .center)
                                    Spacer()
                                    Text(formatShortTime(day.times.asr))
                                        .frame(width: 48, alignment: .center)
                                    Spacer()
                                    Text(formatShortTime(day.times.maghrib))
                                        .frame(width: 50, alignment: .center)
                                    Spacer()
                                    Text(formatShortTime(day.times.isha))
                                        .frame(width: 48, alignment: .center)
                                }
                                .font(.system(size: 11, design: .monospaced))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    day.isToday
                                    ? Color.green.opacity(0.12)
                                    : (day.hijriInfo.event != nil ? Color.orange.opacity(0.06) : Color.clear)
                                )
                                .id("\(selectedMonthOffset)-\(day.gregorianDay)")

                                Divider()
                            }
                        }
                    }
                    .id(selectedMonthOffset)
                    .onAppear {
                        locationManager.requestLocation()
                        if selectedMonthOffset == 0 {
                            let todayDay = calendar.component(.day, from: Date())
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo("0-\(todayDay)", anchor: .center)
                                }
                            }
                        }
                    }
                    .onChange(of: selectedMonthOffset) { newOffset in
                        if newOffset == 0 {
                            let todayDay = calendar.component(.day, from: Date())
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo("0-\(todayDay)", anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Prayer Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedMonthOffset != 0 {
                        Button("Today") {
                            withAnimation(.easeInOut(duration: 0.25)) { selectedMonthOffset = 0 }
                        }
                    }
                }
            }
        }
    }

    private func formatShortTime(_ time: String) -> String {
        let clean = time.components(separatedBy: " ").first ?? time
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"

        guard let date = formatter.date(from: clean) else { return time }

        let out = DateFormatter()
        out.dateFormat = "h:mm"
        return out.string(from: date)
    }
}
