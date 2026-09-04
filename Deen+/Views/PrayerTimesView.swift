import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PrayerTimesView: View {

    @EnvironmentObject var prayerManager: PrayerManager

    var body: some View {

        NavigationStack {

            List {

                if prayerManager.isLoading {

                    ProgressView("Loading prayer times...")
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
            
            .navigationTitle("Prayer Times")

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
