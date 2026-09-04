//
//  PrayerAutoSettings.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/19/26.
//

import Foundation

struct PrayerAutoSettings {

    /// Automatically determines the optimal prayer calculation method, Asr juristic school,
    /// and high-latitude adjustment rule based on geographic location, country code, timezone, and locale.
    /// Completely offline: requires zero network connectivity.
    static func autoDetect(
        countryCode: String? = nil,
        latitude: Double,
        longitude: Double,
        timeZone: TimeZone = .current
    ) -> (method: String, juristic: PrayTimes.AdjustmentMethod, highLats: PrayTimes.ElavationMethod) {

        // 1. Resolve country code from passed code, cached code, locale region, timezone, or coordinate bounding box
        let code = (countryCode?.uppercased())
            ?? (Locale.current.region?.identifier.uppercased())
            ?? detectCountryFromTimeZone(timeZone)
            ?? detectCountryFromCoordinates(lat: latitude, lon: longitude)
            ?? "US"

        let method: String
        let juristic: PrayTimes.AdjustmentMethod

        switch code {
        // North America
        case "US", "CA":
            method = "ISNA"
            juristic = .Standard

        // Saudi Arabia & Arabian Peninsula
        case "SA", "YE", "OM", "BH":
            method = "Makkah"
            juristic = .Standard

        // UAE
        case "AE":
            method = "Dubai"
            juristic = .Standard

        // Qatar
        case "QA":
            method = "Qatar"
            juristic = .Standard

        // Kuwait
        case "KW":
            method = "Kuwait"
            juristic = .Standard

        // Egypt, North Africa & Levant
        case "EG", "SD", "LY", "SY", "LB", "JO", "PS", "MA", "DZ", "TN":
            method = "Egypt"
            juristic = .Standard

        // South Asia (Karachi method + Hanafi Asr)
        case "PK", "IN", "BD", "AF":
            method = "Karachi"
            juristic = .Hanafi

        // Southeast Asia
        case "SG", "MY", "ID", "BN":
            method = "Singapore"
            juristic = .Standard

        // Turkey & Central Asia
        case "TR", "AZ", "CY":
            method = "Turkey"
            juristic = .Hanafi

        // France
        case "FR":
            method = "UIOF"
            juristic = .Standard

        // Iran
        case "IR":
            method = "Tehran"
            juristic = .Standard

        // Default: Muslim World League (Europe, UK, Australasia, Rest of World)
        default:
            method = "MWL"
            juristic = .Standard
        }

        // 2. High-Latitude Adjustment Rule
        // Latitudes above ~48° N/S (e.g. UK, Canada, Scandinavia, Northern Europe) experience twilight anomalies in summer
        let highLats: PrayTimes.ElavationMethod
        if abs(latitude) >= 48.0 {
            highLats = .AngleBased
        } else {
            highLats = .NightMiddle
        }

        return (method, juristic, highLats)
    }

    private static func detectCountryFromTimeZone(_ tz: TimeZone) -> String? {
        let id = tz.identifier
        if id.hasPrefix("America/") { return "US" }
        if id.contains("Riyadh") { return "SA" }
        if id.contains("Dubai") { return "AE" }
        if id.contains("Qatar") { return "QA" }
        if id.contains("Kuwait") { return "KW" }
        if id.contains("Cairo") { return "EG" }
        if id.contains("Karachi") { return "PK" }
        if id.contains("Kolkata") || id.contains("Calcutta") { return "IN" }
        if id.contains("Dhaka") { return "BD" }
        if id.contains("Istanbul") { return "TR" }
        if id.contains("Singapore") { return "SG" }
        if id.contains("Kuala_Lumpur") { return "MY" }
        if id.contains("Jakarta") { return "ID" }
        if id.contains("Paris") { return "FR" }
        if id.contains("Tehran") { return "IR" }
        if id.hasPrefix("Europe/") { return "GB" }
        return nil
    }

    private static func detectCountryFromCoordinates(lat: Double, lon: Double) -> String? {
        // Simple bounding box checks when geocoding is unavailable
        if lat >= 24 && lat <= 50 && lon >= -125 && lon <= -65 { return "US" }
        if lat >= 16 && lat <= 32 && lon >= 34 && lon <= 56 { return "SA" }
        if lat >= 5 && lat <= 37 && lon >= 60 && lon <= 97 { return "PK" }
        if lat >= -11 && lat <= 7 && lon >= 95 && lon <= 141 { return "SG" }
        if lat >= 36 && lat <= 42 && lon >= 26 && lon <= 45 { return "TR" }
        if lat >= 22 && lat <= 32 && lon >= 25 && lon <= 35 { return "EG" }
        return nil
    }
}
