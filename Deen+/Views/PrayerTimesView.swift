import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PrayerTimesView: View {

    @EnvironmentObject var prayerManager: PrayerManager
    @State private var showingMonthlyCalendar = false
    @State private var showingIslamicEvents = false

    private let hijriManager = HijriCalendarManager.shared

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
                        PrayerRow(
                            name: "Fajr",
                            time: prayerManager.prayerTimes.fajr,
                            icon: "sunrise.fill"
                        )

                        PrayerRow(
                            name: "Sunrise",
                            time: prayerManager.prayerTimes.sunrise,
                            icon: "sun.min.fill"
                        )

                        PrayerRow(
                            name: "Dhuhr",
                            time: prayerManager.prayerTimes.dhuhr,
                            icon: "sun.max.fill"
                        )

                        PrayerRow(
                            name: "Asr",
                            time: prayerManager.prayerTimes.asr,
                            icon: "sun.max"
                        )

                        PrayerRow(
                            name: "Maghrib",
                            time: prayerManager.prayerTimes.maghrib,
                            icon: "sunset.fill"
                        )

                        PrayerRow(
                            name: "Isha",
                            time: prayerManager.prayerTimes.isha,
                            icon: "moon.stars.fill"
                        )
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

    var body: some View {

        HStack {

            Image(systemName: icon)
                .frame(width: 30)
                .foregroundStyle(.green)

            Text(name)
                .font(.headline)

            Spacer()

            Text(convertTime(time))
                .foregroundStyle(.secondary)

        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            #if canImport(UIKit)
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            #endif
        }
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
