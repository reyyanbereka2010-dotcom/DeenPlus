//
//  PrayTimes.swift
//  Deen+
//
//  Created by PrayTimes.org, translated to Swift by Basem Emara,
//  modernized for offline calculation in Deen+.
//  License: MIT
//

import Foundation

class PrayTimes {

    // MARK: - Enumerations

    enum TimeName: Int, CaseIterable {
        case imsak, fajr, sunrise, dhuhr, asr, sunset, maghrib, isha, midnight

        static let names: [TimeName: String] = [
            .imsak: "Imsak",
            .fajr: "Fajr",
            .sunrise: "Sunrise",
            .dhuhr: "Dhuhr",
            .asr: "Asr",
            .sunset: "Sunset",
            .maghrib: "Maghrib",
            .isha: "Isha",
            .midnight: "Midnight"
        ]

        func getName() -> String {
            return TimeName.names[self] ?? ""
        }
    }

    enum AdjustmentType {
        case degree, minute, method, factor
    }

    enum AdjustmentMethod: String, CaseIterable, Identifiable {
        case Standard = "Standard"
        case Hanafi = "Hanafi"
        case Jafari = "Jafari"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .Standard: return "Standard (Shafi'i, Maliki, Hanbali)"
            case .Hanafi: return "Hanafi"
            case .Jafari: return "Jafari"
            }
        }
    }

    enum ElavationMethod: String, CaseIterable, Identifiable {
        case None = "None"
        case NightMiddle = "NightMiddle"
        case OneSeventh = "OneSeventh"
        case AngleBased = "AngleBased"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .None: return "None"
            case .NightMiddle: return "Middle of the Night"
            case .OneSeventh: return "One-Seventh of the Night"
            case .AngleBased: return "Angle-Based"
            }
        }
    }

    // MARK: - Structs

    struct AdjustmentParam {
        var time: TimeName
        var type: AdjustmentType
        var value: Any?

        init(time: TimeName, type: AdjustmentType, value: Any?) {
            self.time = time
            self.type = type
            self.value = value
        }
    }

    struct PrayerMethod {
        var description: String
        var params: [AdjustmentParam] = []
        var elavation: ElavationMethod?

        init(_ description: String, _ params: [AdjustmentParam], elavation: ElavationMethod? = nil) {
            self.description = description
            self.params = params
            self.elavation = elavation

            for item in PrayTimes.defaultParams {
                if !self.params.contains(where: { $0.time == item.time }) {
                    self.params.append(item)
                }
            }
        }
    }

    struct PrayerResult {
        var timeFormat = "24h"
        var timeSuffixes = ["am", "pm"]
        var invalidTime = "--:--"

        var name: String
        var type: TimeName
        var time: Double
        var date: Date
        var requestDate: Date
        var coordinates: [Double]?
        var timeZone: Double?
        var abbr = ""
        var isFard = false
        var isCurrent = false
        var isNext = false

        var formattedTime: String {
            return getFormattedTime()
        }

        init(
            _ type: TimeName,
            _ time: Double,
            date: Date = Date(),
            requestDate: Date = Date(),
            coordinates: [Double]? = nil,
            timeZone: Double? = nil,
            timeFormat: String? = nil,
            timeSuffixes: [String]? = nil
        ) {
            self.name = type.getName()
            self.type = type
            self.time = time
            self.date = date
            self.requestDate = requestDate
            self.coordinates = coordinates

            if let value = timeZone { self.timeZone = value }
            if let value = timeFormat { self.timeFormat = value }
            if let value = timeSuffixes { self.timeSuffixes = value }

            // Handle times after midnight
            if self.time > 24 {
                self.date = Calendar.current.date(byAdding: .day, value: 1, to: self.date) ?? self.date
            }

            var timeComponents = PrayTimes.getTimeComponents(self.time)

            if timeComponents[1] >= 60 {
                timeComponents[0] += 1
                timeComponents[1] -= 60
            }

            if timeComponents[0] >= 24 {
                self.date = Calendar.current.date(byAdding: .day, value: 1, to: self.date) ?? self.date
                timeComponents[0] -= 24
            }

            self.date = Calendar.current.date(
                bySettingHour: timeComponents[0],
                minute: timeComponents[1],
                second: 0,
                of: self.date
            ) ?? self.date

            switch type {
            case .imsak:
                self.abbr = "IMK"
            case .fajr:
                self.abbr = "FJR"
                self.isFard = true
            case .sunrise:
                self.abbr = "SHK"
            case .dhuhr:
                self.abbr = "DHR"
                self.isFard = true
                let calendar = Calendar(identifier: .gregorian)
                let components = calendar.dateComponents([.weekday], from: date)
                if components.weekday == 6 {
                    self.name = "Jumuah"
                }
            case .asr:
                self.abbr = "ASR"
                self.isFard = true
            case .maghrib:
                self.abbr = "MGB"
                self.isFard = true
            case .isha:
                self.abbr = "ISH"
                self.isFard = true
            case .midnight:
                self.abbr = "MID"
            default:
                break
            }
        }

        func getFormattedTime(_ format: String? = nil, suffixes: [String]? = nil) -> String {
            let activeFormat = format ?? timeFormat
            let activeSuffixes = suffixes ?? timeSuffixes

            if time.isNaN || time == 0 {
                return invalidTime
            }

            if activeFormat == "Float" {
                return "\(time)"
            }

            let timeComponents = PrayTimes.getTimeComponents(time)
            let hours = timeComponents[0]
            let minutes = timeComponents[1]

            let suffix = activeFormat == "12h" && !activeSuffixes.isEmpty
                ? (hours < 12 ? activeSuffixes[0] : activeSuffixes[1])
                : ""
            let hour = activeFormat == "24h"
                ? PrayTimes.twoDigitsFormat(hours)
                : "\(Int((hours + 12 - 1) % 12 + 1))"

            let output = hour + ":" + PrayTimes.twoDigitsFormat(minutes)
                + (!suffix.isEmpty ? " " + suffix : "")

            return output
        }
    }

    // MARK: - Constants & Defaults

    static let availableMethodKeys: [(key: String, name: String)] = [
        ("MWL", "Muslim World League (MWL)"),
        ("ISNA", "Islamic Society of North America (ISNA)"),
        ("Egypt", "Egyptian General Authority of Survey"),
        ("Makkah", "Umm Al-Qura University, Makkah"),
        ("Karachi", "University of Islamic Sciences, Karachi"),
        ("Dubai", "United Arab Emirates (Dubai)"),
        ("Qatar", "Qatar"),
        ("Kuwait", "Kuwait"),
        ("Singapore", "Singapore (MUIS)"),
        ("Turkey", "Turkey (Diyanet)"),
        ("Tehran", "Institute of Geophysics, University of Tehran"),
        ("Jafari", "Shia Ithna-Ashari, Leva Institute, Qum"),
        ("UIOF", "Union of Islamic Organizations of France")
    ]

    let methods: [String: PrayerMethod] = [
        "MWL": PrayerMethod("Muslim World League", [
            AdjustmentParam(time: .fajr, type: .degree, value: 18.0),
            AdjustmentParam(time: .isha, type: .degree, value: 17.0)
        ]),
        "ISNA": PrayerMethod("Islamic Society of North America (ISNA)", [
            AdjustmentParam(time: .fajr, type: .degree, value: 15.0),
            AdjustmentParam(time: .isha, type: .degree, value: 15.0)
        ]),
        "Egypt": PrayerMethod("Egyptian General Authority of Survey", [
            AdjustmentParam(time: .fajr, type: .degree, value: 19.5),
            AdjustmentParam(time: .isha, type: .degree, value: 17.5)
        ]),
        "Makkah": PrayerMethod("Umm Al-Qura University, Makkah", [
            AdjustmentParam(time: .fajr, type: .degree, value: 18.5),
            AdjustmentParam(time: .isha, type: .minute, value: 90.0)
        ]),
        "Karachi": PrayerMethod("University of Islamic Sciences, Karachi", [
            AdjustmentParam(time: .fajr, type: .degree, value: 18.0),
            AdjustmentParam(time: .isha, type: .degree, value: 18.0)
        ]),
        "Dubai": PrayerMethod("United Arab Emirates (Dubai)", [
            AdjustmentParam(time: .fajr, type: .degree, value: 18.2),
            AdjustmentParam(time: .isha, type: .degree, value: 18.2)
        ]),
        "Qatar": PrayerMethod("Qatar", [
            AdjustmentParam(time: .fajr, type: .degree, value: 18.0),
            AdjustmentParam(time: .isha, type: .minute, value: 90.0)
        ]),
        "Kuwait": PrayerMethod("Kuwait", [
            AdjustmentParam(time: .fajr, type: .degree, value: 18.0),
            AdjustmentParam(time: .isha, type: .degree, value: 17.5)
        ]),
        "Singapore": PrayerMethod("Singapore (MUIS)", [
            AdjustmentParam(time: .fajr, type: .degree, value: 20.0),
            AdjustmentParam(time: .isha, type: .degree, value: 18.0)
        ]),
        "Turkey": PrayerMethod("Turkey (Diyanet)", [
            AdjustmentParam(time: .fajr, type: .degree, value: 18.0),
            AdjustmentParam(time: .isha, type: .degree, value: 17.0)
        ]),
        "Tehran": PrayerMethod("Institute of Geophysics, University of Tehran", [
            AdjustmentParam(time: .fajr, type: .degree, value: 17.7),
            AdjustmentParam(time: .maghrib, type: .degree, value: 4.5),
            AdjustmentParam(time: .isha, type: .degree, value: 14.0),
            AdjustmentParam(time: .midnight, type: .method, value: AdjustmentMethod.Jafari)
        ]),
        "Jafari": PrayerMethod("Shia Ithna-Ashari, Leva Institute, Qum", [
            AdjustmentParam(time: .fajr, type: .degree, value: 16.0),
            AdjustmentParam(time: .maghrib, type: .degree, value: 4.0),
            AdjustmentParam(time: .isha, type: .degree, value: 14.0),
            AdjustmentParam(time: .midnight, type: .method, value: AdjustmentMethod.Jafari)
        ]),
        "UIOF": PrayerMethod("Union of Islamic Organizations of France", [
            AdjustmentParam(time: .fajr, type: .degree, value: 12.0),
            AdjustmentParam(time: .isha, type: .degree, value: 12.0)
        ])
    ]

    static let defaultParams = [
        AdjustmentParam(time: .maghrib, type: .minute, value: 0.0),
        AdjustmentParam(time: .midnight, type: .method, value: AdjustmentMethod.Standard)
    ]

    static let defaultSettings = [
        AdjustmentParam(time: .imsak, type: .minute, value: 10.0),
        AdjustmentParam(time: .dhuhr, type: .minute, value: 0.0),
        AdjustmentParam(time: .asr, type: .method, value: AdjustmentMethod.Standard)
    ]

    static let defaultTimes: [TimeName: Double] = [
        .imsak: 5.0,
        .fajr: 5.0,
        .sunrise: 6.0,
        .dhuhr: 12.0,
        .asr: 13.0,
        .sunset: 18.0,
        .maghrib: 18.0,
        .isha: 18.0
    ]

    // MARK: - Properties

    var calcMethod = "ISNA"
    var highLats = ElavationMethod.NightMiddle
    var settings = defaultSettings

    var timeFormat = "24h"
    var timeSuffixes = ["am", "pm"]

    var timeZone: Double = 0
    var jDate: Double = 0
    var invalidTime = "--:--"

    var lat: Double = 0
    var lng: Double = 0
    var elv: Double = 0

    var offset: [TimeName: Double] = [
        .imsak: 0.0,
        .fajr: 0.0,
        .sunrise: 0.0,
        .dhuhr: 0.0,
        .asr: 0.0,
        .sunset: 0.0,
        .maghrib: 0.0,
        .isha: 0.0,
        .midnight: 0.0
    ]

    // MARK: - Initializers

    init(
        method: String? = nil,
        juristic: AdjustmentMethod? = nil,
        highLats: ElavationMethod? = nil
    ) {
        setMethod(method ?? calcMethod)

        if let j = juristic {
            for (index, item) in settings.enumerated() {
                if item.type == .method {
                    settings[index].value = j
                }
            }
        }

        if let hl = highLats {
            self.highLats = hl
        }
    }

    // MARK: - Configuration Methods

    func setMethod(_ method: String) {
        settings = PrayTimes.defaultSettings
        if let item = methods[method] {
            calcMethod = method
            adjust(item.params)
            if let el = item.elavation {
                highLats = el
            }
        } else if let fallback = methods[calcMethod] {
            adjust(fallback.params)
        }
    }

    func adjust(_ params: [AdjustmentParam]) {
        for item in params {
            settings = settings.filter { $0.time != item.time }
            settings.append(item)
        }
    }

    func tune(_ timeOffsets: [TimeName: Double]) {
        for (key, val) in timeOffsets {
            offset[key] = val
        }
    }

    func setJuristicMethod(_ juristic: AdjustmentMethod) {
        for (index, item) in settings.enumerated() {
            if item.type == .method {
                settings[index].value = juristic
            }
        }
    }

    func setHighLatsMethod(_ hl: ElavationMethod) {
        self.highLats = hl
    }

    func getMethod() -> String {
        return calcMethod
    }

    func getSetting(_ time: TimeName) -> AdjustmentParam? {
        return settings.first { $0.time == time }
    }

    func getSettingValue(_ time: TimeName) -> Double {
        guard let setting = getSetting(time) else { return 0.0 }
        if setting.type == .minute || setting.type == .degree {
            return (setting.value as? Double) ?? 0.0
        }
        return 0.0
    }

    // MARK: - Primary Offline Calculation

    /// Directly calculates and returns a `PrayerTimes` struct for the given coordinates, date, and timezone.
    /// Completely offline: requires zero network connectivity.
    func calculate(
        for coordinates: [Double],
        date: Date = Date(),
        timeZone: Double? = nil
    ) -> PrayerTimes {
        let results = calculateTimes(for: coordinates, date: date, timeZone: timeZone, format: "24h")

        func getTime(for type: TimeName) -> String {
            return results.first { $0.type == type }?.formattedTime ?? "--:--"
        }

        return PrayerTimes(
            fajr: getTime(for: .fajr),
            sunrise: getTime(for: .sunrise),
            dhuhr: getTime(for: .dhuhr),
            asr: getTime(for: .asr),
            maghrib: getTime(for: .maghrib),
            isha: getTime(for: .isha)
        )
    }

    /// Calculates prayer times synchronously and returns detailed `PrayerResult` objects.
    func calculateTimes(
        for coordinates: [Double],
        date: Date = Date(),
        timeZone: Double? = nil,
        format: String = "24h"
    ) -> [PrayerResult] {
        guard coordinates.count >= 2 else { return [] }
        lat = coordinates[0]
        lng = coordinates[1]
        elv = coordinates.count > 2 ? coordinates[2] : 0
        jDate = PrayTimes.getJulian(for: date) - lng / (15.0 * 24.0)
        timeFormat = format

        self.timeZone = timeZone ?? (Double(TimeZone.current.secondsFromGMT()) / 3600.0)

        var result = computeTimes().map {
            PrayerResult(
                $0.0,
                $0.1,
                date: date,
                requestDate: date,
                coordinates: coordinates,
                timeZone: self.timeZone,
                timeFormat: self.timeFormat,
                timeSuffixes: self.timeSuffixes
            )
        }.sorted { $0.time < $1.time }

        // Assign current and next prayer states
        if let nextType = result.filter({ $0.date.compare(date) == .orderedDescending && ($0.isFard || $0.type == .sunrise) }).first?.type {
            let currentType = PrayTimes.getPreviousPrayer(nextType)
            for index in result.indices {
                if result[index].type == currentType {
                    result[index].isCurrent = true
                } else if result[index].type == nextType {
                    result[index].isNext = true
                }
            }
        } else {
            for index in result.indices {
                if result[index].type == .fajr {
                    result[index].isNext = true
                } else if result[index].type == .isha {
                    result[index].isCurrent = true
                }
            }
        }

        return result
    }

    /// Backward-compatible asynchronous interface (runs completely offline and invokes handler immediately).
    func getTimes(
        for coordinates: [Double],
        date: Date = Date(),
        timeZone: Double? = nil,
        dst: Bool = false,
        dstOffset: Int = 3600,
        format: String? = nil,
        isLocalCoords: Bool = true,
        onlyEssentials: Bool = false,
        handler: @escaping ([PrayerResult]) -> Void
    ) {
        var tz = timeZone ?? (Double(TimeZone.current.secondsFromGMT()) / 3600.0)
        if dst { tz += 1.0 }

        let results = calculateTimes(
            for: coordinates,
            date: date,
            timeZone: tz,
            format: format ?? "24h"
        )

        let filtered = onlyEssentials
            ? results.filter { ($0.isFard || $0.type == .sunrise) && $0.type != .sunset }
            : results.filter { $0.type != .sunset }

        handler(filtered)
    }

    // MARK: - Internal Calculation Engine

    func computeTimes() -> [TimeName: Double] {
        var times = computePrayerTimes(for: PrayTimes.defaultTimes)
        times = adjustTimes(for: times)

        let midnight = getSetting(.midnight)
        if midnight?.type == .method && (midnight?.value as? AdjustmentMethod) == .Jafari {
            let sunset = times[.sunset] ?? 18.0
            let fajr = times[.fajr] ?? 5.0
            times[.midnight] = sunset + PrayTimes.timeDiff(sunset, fajr) / 2.0
        } else {
            let sunset = times[.sunset] ?? 18.0
            let sunrise = times[.sunrise] ?? 6.0
            times[.midnight] = sunset + PrayTimes.timeDiff(sunset, sunrise) / 2.0
        }

        times = tuneTimes(at: times)
        return times
    }

    func computePrayerTimes(for times: [TimeName: Double]) -> [TimeName: Double] {
        let portions = PrayTimes.dayPortion(for: times)

        let imsak = sunAngleTime(at: getSettingValue(.imsak), time: portions[.imsak] ?? 0.2, direction: "ccw")
        let fajr = sunAngleTime(at: getSettingValue(.fajr), time: portions[.fajr] ?? 0.2, direction: "ccw")
        let sunrise = sunAngleTime(at: riseSetAngle(), time: portions[.sunrise] ?? 0.25, direction: "ccw")
        let dhuhr = midDay(at: portions[.dhuhr] ?? 0.5)
        let asr = asrTime(at: portions[.asr] ?? 0.55)
        let sunset = sunAngleTime(at: riseSetAngle(), time: portions[.sunset] ?? 0.75)
        let maghrib = sunAngleTime(at: getSettingValue(.maghrib), time: portions[.maghrib] ?? 0.75)
        let isha = sunAngleTime(at: getSettingValue(.isha), time: portions[.isha] ?? 0.75)

        return [
            .imsak: imsak,
            .fajr: fajr,
            .sunrise: sunrise,
            .dhuhr: dhuhr,
            .asr: asr,
            .sunset: sunset,
            .maghrib: maghrib,
            .isha: isha
        ]
    }

    func midDay(at time: Double) -> Double {
        let eqt = PrayTimes.sunPosition(at: jDate + time).equation
        return PrayTimes.fixHour(12.0 - eqt)
    }

    func sunAngleTime(at angle: Double, time: Double, direction: String? = nil) -> Double {
        let decl = PrayTimes.sunPosition(at: jDate + time).declination
        let noon = midDay(at: time)

        let sinAngle = -PrayTimes.sin(angle) - PrayTimes.sin(decl) * PrayTimes.sin(lat)
        let cosAngle = PrayTimes.cos(decl) * PrayTimes.cos(lat)

        let val = sinAngle / cosAngle
        let clamped = max(-1.0, min(1.0, val))

        let t = 1.0 / 15.0 * PrayTimes.arccos(clamped)
        return noon + (direction == "ccw" ? -t : t)
    }

    func riseSetAngle() -> Double {
        let angle = 0.0347 * sqrt(max(0, elv))
        return 0.833 + angle
    }

    func asrTime(at time: Double) -> Double {
        let factor = asrFactor()
        let decl = PrayTimes.sunPosition(at: jDate + time).declination
        let angle = -PrayTimes.arccot(factor + PrayTimes.tan(abs(lat - decl)))
        return sunAngleTime(at: angle, time: time)
    }

    func asrFactor() -> Double {
        guard let asrParam = getSetting(.asr) else { return 1.0 }
        if asrParam.type == .method {
            let method = (asrParam.value as? AdjustmentMethod) ?? .Standard
            return method == .Hanafi ? 2.0 : 1.0
        }
        return getSettingValue(.asr) > 0 ? getSettingValue(.asr) : 1.0
    }

    func adjustTimes(for times: [TimeName: Double]) -> [TimeName: Double] {
        var adjusted = times
        let shift = timeZone - lng / 15.0

        for (k, v) in adjusted {
            adjusted[k] = v + shift
        }

        if highLats != .None {
            adjusted = adjustHighLats(for: adjusted)
        }

        let imsakSetting = getSetting(.imsak)
        if imsakSetting?.type == .minute {
            adjusted[.imsak] = (adjusted[.fajr] ?? 5.0) - ((imsakSetting?.value as? Double) ?? 10.0) / 60.0
        }

        let maghribSetting = getSetting(.maghrib)
        if maghribSetting?.type == .minute {
            adjusted[.maghrib] = (adjusted[.sunset] ?? 18.0) + ((maghribSetting?.value as? Double) ?? 0.0) / 60.0
        }

        let ishaSetting = getSetting(.isha)
        if ishaSetting?.type == .minute {
            adjusted[.isha] = (adjusted[.maghrib] ?? 18.0) + ((ishaSetting?.value as? Double) ?? 90.0) / 60.0
        }

        adjusted[.dhuhr] = (adjusted[.dhuhr] ?? 12.0) + getSettingValue(.dhuhr) / 60.0

        return adjusted
    }

    func adjustHighLats(for times: [TimeName: Double]) -> [TimeName: Double] {
        var adjusted = times
        let sunset = adjusted[.sunset] ?? 18.0
        let sunrise = adjusted[.sunrise] ?? 6.0
        let nightTime = PrayTimes.timeDiff(sunset, sunrise)

        adjusted[.imsak] = adjustHLTime(for: adjusted[.imsak] ?? 5.0, base: sunrise, angle: getSettingValue(.imsak), night: nightTime, direction: "ccw")
        adjusted[.fajr] = adjustHLTime(for: adjusted[.fajr] ?? 5.0, base: sunrise, angle: getSettingValue(.fajr), night: nightTime, direction: "ccw")
        adjusted[.isha] = adjustHLTime(for: adjusted[.isha] ?? 19.0, base: sunset, angle: getSettingValue(.isha), night: nightTime)
        adjusted[.maghrib] = adjustHLTime(for: adjusted[.maghrib] ?? 18.0, base: sunset, angle: getSettingValue(.maghrib), night: nightTime)

        return adjusted
    }

    func adjustHLTime(for time: Double, base: Double, angle: Double, night: Double, direction: String? = nil) -> Double {
        let portion = nightPortion(at: angle, for: night)
        let diff = direction == "ccw" ? PrayTimes.timeDiff(time, base) : PrayTimes.timeDiff(base, time)

        if time.isNaN || diff > portion {
            return base + (direction == "ccw" ? -portion : portion)
        }
        return time
    }

    func nightPortion(at angle: Double, for night: Double) -> Double {
        var portion = 0.5 // NightMiddle
        if highLats == .AngleBased {
            portion = 1.0 / 60.0 * angle
        } else if highLats == .OneSeventh {
            portion = 1.0 / 7.0
        }
        return portion * night
    }

    func tuneTimes(at times: [TimeName: Double]) -> [TimeName: Double] {
        var tuned = times
        for (k, v) in tuned {
            tuned[k] = v + (offset[k] ?? 0.0) / 60.0
        }
        return tuned
    }

    // MARK: - Astronomical & Mathematical Utilities

    static func sunPosition(at jd: Double) -> (declination: Double, equation: Double) {
        let D = jd - 2451545.0
        let g = fixAngle(357.529 + 0.98560028 * D)
        let q = fixAngle(280.459 + 0.98564736 * D)
        let L = fixAngle(q + 1.915 * sin(g) + 0.020 * sin(2.0 * g))
        let e = 23.439 - 0.00000036 * D

        let RA = arctan2(cos(e) * sin(L), cos(L)) / 15.0
        let eqt = q / 15.0 - fixHour(RA)
        let decl = arcsin(sin(e) * sin(L))

        return (declination: decl, equation: eqt)
    }

    static func getJulian(for date: Date) -> Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        var components = calendar.dateComponents([.year, .month, .day], from: date)

        var year = components.year ?? 2026
        var month = components.month ?? 1
        let day = components.day ?? 1

        if month <= 2 {
            year -= 1
            month += 12
        }

        let A = floor(Double(year) / 100.0)
        let B = 2.0 - A + floor(A / 4.0)
        let C = floor(365.25 * Double(year + 4716))
        let D = floor(30.6001 * Double(month + 1))
        let E = Double(day) + B - 1524.5

        return C + D + E
    }

    // Degree-based trig
    static func dtr(_ d: Double) -> Double { (d * .pi) / 180.0 }
    static func rtd(_ r: Double) -> Double { (r * 180.0) / .pi }

    static func sin(_ d: Double) -> Double { Darwin.sin(dtr(d)) }
    static func cos(_ d: Double) -> Double { Darwin.cos(dtr(d)) }
    static func tan(_ d: Double) -> Double { Darwin.tan(dtr(d)) }

    static func arcsin(_ d: Double) -> Double { rtd(Darwin.asin(max(-1.0, min(1.0, d)))) }
    static func arccos(_ d: Double) -> Double { rtd(Darwin.acos(max(-1.0, min(1.0, d)))) }
    static func arctan(_ d: Double) -> Double { rtd(Darwin.atan(d)) }
    static func arccot(_ x: Double) -> Double { rtd(Darwin.atan(1.0 / x)) }
    static func arctan2(_ y: Double, _ x: Double) -> Double { rtd(Darwin.atan2(y, x)) }

    static func fixAngle(_ a: Double) -> Double { fix(a, 360.0) }
    static func fixHour(_ a: Double) -> Double { fix(a, 24.0) }

    static func fix(_ a: Double, _ b: Double) -> Double {
        let res = a - b * floor(a / b)
        return res < 0 ? res + b : res
    }

    static func timeDiff(_ time1: Double, _ time2: Double) -> Double {
        return fixHour(time2 - time1)
    }

    static func twoDigitsFormat(_ num: Int) -> String {
        return num < 10 ? "0\(num)" : "\(num)"
    }

    static func dayPortion(for times: [TimeName: Double]) -> [TimeName: Double] {
        var portions = times
        for (k, v) in portions {
            portions[k] = v / 24.0
        }
        return portions
    }

    static func getTimeComponents(_ time: Double) -> [Int] {
        let roundedTime = fixHour(time + 0.5 / 60.0)
        var hours = floor(roundedTime)
        var minutes = round((roundedTime - hours) * 60.0)

        if minutes > 59 {
            hours += 1
            minutes = 0
        }
        return [Int(hours) % 24, Int(minutes)]
    }

    static func getPreviousPrayer(_ time: TimeName) -> TimeName {
        switch time {
        case .imsak: return .midnight
        case .fajr: return .imsak
        case .sunrise: return .fajr
        case .dhuhr: return .sunrise
        case .asr: return .dhuhr
        case .sunset: return .asr
        case .maghrib: return .sunset
        case .isha: return .maghrib
        case .midnight: return .isha
        }
    }

    static func getNextPrayer(_ time: TimeName) -> TimeName {
        switch time {
        case .imsak: return .fajr
        case .fajr: return .sunrise
        case .sunrise: return .dhuhr
        case .dhuhr: return .asr
        case .asr: return .sunset
        case .sunset: return .maghrib
        case .maghrib: return .isha
        case .isha: return .midnight
        case .midnight: return .imsak
        }
    }
}
