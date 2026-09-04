//
//  PrayerManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/19/26.
//

import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

class PrayerManager: ObservableObject {

    @Published var isLoading = false
    @Published var prayerTimes: PrayerTimes

    @Published var autoDetectSettings: Bool {
        didSet {
            UserDefaults.standard.set(autoDetectSettings, forKey: autoDetectKey)
            if autoDetectSettings {
                applyAutoSettings()
            }
        }
    }

    @Published var calculationMethod: String {
        didSet {
            UserDefaults.standard.set(calculationMethod, forKey: methodKey)
            calculatePrayerTimes()
        }
    }

    @Published var juristicMethod: PrayTimes.AdjustmentMethod {
        didSet {
            UserDefaults.standard.set(juristicMethod.rawValue, forKey: juristicKey)
            calculatePrayerTimes()
        }
    }

    @Published var highLatsMethod: PrayTimes.ElavationMethod {
        didSet {
            UserDefaults.standard.set(highLatsMethod.rawValue, forKey: highLatsKey)
            calculatePrayerTimes()
        }
    }

    var currentMethodDisplayName: String {
        PrayTimes.availableMethodKeys.first { $0.key == calculationMethod }?.name ?? calculationMethod
    }

    private let cacheKey = "cached_prayer_times"
    private let cacheDateKey = "cached_prayer_date"
    private let cacheLatKey = "cached_prayer_lat"
    private let cacheLonKey = "cached_prayer_lon"

    private let autoDetectKey = "prayer_auto_detect_settings"
    private let methodKey = "prayer_calc_method"
    private let juristicKey = "prayer_juristic_method"
    private let highLatsKey = "prayer_high_lats_method"

    private(set) var lastFetchedLat: Double = 0
    private(set) var lastFetchedLon: Double = 0

    // Fallback coordinates (Makkah) when GPS is not yet acquired
    private let fallbackLat: Double = 21.4225
    private let fallbackLon: Double = 39.8262

    init() {
        // Default auto-detect to true if not explicitly set
        let isAuto = UserDefaults.standard.object(forKey: autoDetectKey) as? Bool ?? true
        self.autoDetectSettings = isAuto

        // Load cached coordinates
        let savedLat = UserDefaults.standard.double(forKey: cacheLatKey)
        let savedLon = UserDefaults.standard.double(forKey: cacheLonKey)
        self.lastFetchedLat = savedLat
        self.lastFetchedLon = savedLon

        let activeLat = savedLat != 0 ? savedLat : fallbackLat
        let activeLon = savedLon != 0 ? savedLon : fallbackLon

        let cachedCountry = UserDefaults.standard.string(forKey: "cached_location_country_code")

        let method: String
        let juristic: PrayTimes.AdjustmentMethod
        let highLats: PrayTimes.ElavationMethod

        if isAuto {
            let auto = PrayerAutoSettings.autoDetect(
                countryCode: cachedCountry,
                latitude: activeLat,
                longitude: activeLon
            )
            method = auto.method
            juristic = auto.juristic
            highLats = auto.highLats
        } else {
            let savedMethod = UserDefaults.standard.string(forKey: methodKey) ?? "ISNA"
            let savedJuristicRaw = UserDefaults.standard.string(forKey: juristicKey) ?? PrayTimes.AdjustmentMethod.Standard.rawValue
            let savedHighLatsRaw = UserDefaults.standard.string(forKey: highLatsKey) ?? PrayTimes.ElavationMethod.NightMiddle.rawValue

            method = savedMethod
            juristic = PrayTimes.AdjustmentMethod(rawValue: savedJuristicRaw) ?? .Standard
            highLats = PrayTimes.ElavationMethod(rawValue: savedHighLatsRaw) ?? .NightMiddle
        }

        self.calculationMethod = method
        self.juristicMethod = juristic
        self.highLatsMethod = highLats

        // Pre-calculate today's prayer times offline immediately with zero delay
        let pt = PrayTimes(method: method, juristic: juristic, highLats: highLats)
        let initialTimes = pt.calculate(for: [activeLat, activeLon], date: Date())
        self.prayerTimes = initialTimes

        NotificationManager.shared.schedulePrayerNotifications(prayerTimes: initialTimes)

        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDayOrTimeChange),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDayOrTimeChange),
            name: UIApplication.significantTimeChangeNotification,
            object: nil
        )
        #endif
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleDayOrTimeChange() {
        let today = dateString(for: Date())
        let cachedDate = UserDefaults.standard.string(forKey: cacheDateKey) ?? ""

        if today != cachedDate {
            calculatePrayerTimes()
        }
    }

    // MARK: - Auto-Detection

    /// Automatically sets the calculation method, juristic school, and high latitude adjustments based on location
    public func applyAutoSettings(
        latitude: Double? = nil,
        longitude: Double? = nil,
        countryCode: String? = nil
    ) {
        let lat = latitude ?? (lastFetchedLat != 0 ? lastFetchedLat : fallbackLat)
        let lon = longitude ?? (lastFetchedLon != 0 ? lastFetchedLon : fallbackLon)
        let code = countryCode ?? UserDefaults.standard.string(forKey: "cached_location_country_code")

        let auto = PrayerAutoSettings.autoDetect(
            countryCode: code,
            latitude: lat,
            longitude: lon
        )

        var changed = false
        if self.calculationMethod != auto.method {
            self.calculationMethod = auto.method
            changed = true
        }
        if self.juristicMethod != auto.juristic {
            self.juristicMethod = auto.juristic
            changed = true
        }
        if self.highLatsMethod != auto.highLats {
            self.highLatsMethod = auto.highLats
            changed = true
        }

        if !changed {
            calculatePrayerTimes(latitude: lat, longitude: lon)
        }
    }

    // MARK: - Offline Calculation

    /// Calculates prayer times completely offline using astronomical algorithms.
    /// Synchronously computes times, updates `@Published var prayerTimes`, caches results, and schedules notifications.
    public func calculatePrayerTimes(
        date: Date = Date(),
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        var lat = latitude ?? (lastFetchedLat != 0 ? lastFetchedLat : fallbackLat)
        var lon = longitude ?? (lastFetchedLon != 0 ? lastFetchedLon : fallbackLon)

        // If explicitly passed 0,0 (location pending), fallback to cached or default
        if lat == 0 && lon == 0 {
            lat = lastFetchedLat != 0 ? lastFetchedLat : fallbackLat
            lon = lastFetchedLon != 0 ? lastFetchedLon : fallbackLon
        }

        lastFetchedLat = lat
        lastFetchedLon = lon

        let pt = PrayTimes(
            method: calculationMethod,
            juristic: juristicMethod,
            highLats: highLatsMethod
        )

        let calculated = pt.calculate(for: [lat, lon], date: date)

        let applyUpdate = {
            self.prayerTimes = calculated
            self.isLoading = false
            self.saveCachedPrayerTimes(calculated, date: self.dateString(for: date), lat: lat, lon: lon)
            NotificationManager.shared.schedulePrayerNotifications(prayerTimes: calculated)
        }

        if Thread.isMainThread {
            applyUpdate()
        } else {
            DispatchQueue.main.async(execute: applyUpdate)
        }
    }

    /// Backward-compatible method called from views like HomeView.
    /// Operates completely offline.
    public func fetchPrayerTimes(
        latitude: Double,
        longitude: Double,
        countryCode: String? = nil,
        isBackground: Bool = false
    ) {
        if autoDetectSettings {
            applyAutoSettings(latitude: latitude, longitude: longitude, countryCode: countryCode)
        } else {
            calculatePrayerTimes(date: Date(), latitude: latitude, longitude: longitude)
        }
    }

    // MARK: - Caching Helpers

    private func saveCachedPrayerTimes(_ times: PrayerTimes, date: String, lat: Double, lon: Double) {
        if let data = try? JSONEncoder().encode(times) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(date, forKey: cacheDateKey)
            UserDefaults.standard.set(lat, forKey: cacheLatKey)
            UserDefaults.standard.set(lon, forKey: cacheLonKey)
        }
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
