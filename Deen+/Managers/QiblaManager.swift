//
//  QiblaManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/21/26.
//

import Foundation
import CoreLocation
import Combine
#if os(iOS)
import CoreMotion
#endif

/// 100% on-device, zero-API astronomical and geodesic Qibla direction calculator.
/// Uses WGS-84 ellipsoidal geodesics (Vincenty's inverse algorithm) for sub-arcsecond
/// directional accuracy to the Holy Kaaba in Makkah al-Mukarramah.
final class QiblaManager: NSObject, ObservableObject {

    // Raw Heading (0...360) & Geodesic Qibla Bearing (0...360)
    @Published var heading: Double = 0
    @Published var qiblaDirection: Double = 0 {
        didSet { updateContinuousAngles() }
    }
    @Published var headingAccuracy: Double = -1
    @Published var isTrueHeadingAvailable: Bool = false

    // Smooth Continuous Rotations (No 180-degree or 360-degree reverse spin wrap-around)
    @Published var continuousHeading: Double = 0
    @Published var continuousNeedleAngle: Double = 0

    // Tilt / Level Status from CoreMotion (Smoothed for normal handheld usage)
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    @Published var isLevel: Bool = true

    // Internal trackers
    private var lastRawHeading: Double? = nil
    private var isFirstHeadingUpdate: Bool = true
    private var lastMotionUpdateTime: TimeInterval = 0

    private let locationManager = CLLocationManager()
    #if os(iOS)
    private let motionManager = CMMotionManager()
    #endif

    /// Exact geographic coordinates of the Holy Kaaba in Masjid al-Haram, Makkah
    static let kaabaLatitude: Double = 21.422487
    static let kaabaLongitude: Double = 39.826206

    // WGS-84 Ellipsoid constants
    private static let a: Double = 6378137.0 // Semi-major axis (meters)
    private static let f: Double = 1.0 / 298.257223563 // Flattening
    private static let b: Double = 6356752.314245 // Semi-minor axis (meters)

    override init() {
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 0.5

        // Check cached coordinates for instant offline launch
        let cachedLat = UserDefaults.standard.double(forKey: "cached_location_lat")
        let cachedLon = UserDefaults.standard.double(forKey: "cached_location_lon")

        if cachedLat != 0 || cachedLon != 0 {
            calculateQibla(latitude: cachedLat, longitude: cachedLon)
        } else {
            calculateQibla(latitude: Self.kaabaLatitude, longitude: Self.kaabaLongitude)
        }
    }

    /// Starts updating heading and device leveling motion
    func startUpdatingHeading() {
        isFirstHeadingUpdate = true
        lastRawHeading = nil

        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }

        #if os(iOS)
        if motionManager.isDeviceMotionAvailable && !motionManager.isDeviceMotionActive {
            motionManager.deviceMotionUpdateInterval = 1.0 / 15.0 // 15Hz is plenty for leveling without causing UI churn
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let self = self, let motion = motion else { return }

                let now = Date().timeIntervalSinceReferenceDate
                // Throttle level state updates to 10Hz to prevent high-frequency jitter
                guard now - self.lastMotionUpdateTime >= 0.09 else { return }
                self.lastMotionUpdateTime = now

                let p = motion.attitude.pitch * 180.0 / .pi
                let r = motion.attitude.roll * 180.0 / .pi
                self.pitch = p
                self.roll = r

                // For normal handheld usage, up to 25 degrees tilt is plenty accurate for iOS magnetometer
                let totalTilt = sqrt(p * p + r * r)
                let currentlyFlat = totalTilt <= 25.0
                if self.isLevel != currentlyFlat {
                    self.isLevel = currentlyFlat
                }
            }
        }
        #endif
    }

    /// Stops updating heading and device leveling motion to conserve battery
    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
        lastRawHeading = nil
        isFirstHeadingUpdate = true
        #if os(iOS)
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        #endif
    }

    // MARK: - Shortest Angle Delta Computation

    static func shortestAngleDelta(from: Double, to: Double) -> Double {
        var diff = (to - from).truncatingRemainder(dividingBy: 360.0)
        if diff > 180.0 {
            diff -= 360.0
        } else if diff < -180.0 {
            diff += 360.0
        }
        return diff
    }

    private func updateContinuousAngles() {
        // Continuous needle angle is always mathematically (qiblaDirection - continuousHeading)
        continuousNeedleAngle = qiblaDirection - continuousHeading
    }

    // MARK: - Status & Alignment Helpers

    func isFacingQibla(tolerance: Double = 4.0) -> Bool {
        let diff = abs(Self.shortestAngleDelta(from: heading, to: qiblaDirection))
        return diff <= tolerance
    }

    var isFacingQibla: Bool {
        isFacingQibla(tolerance: 4.0)
    }

    var arrowRotation: Double {
        continuousNeedleAngle
    }

    var relativeOffsetToQibla: Double {
        Self.shortestAngleDelta(from: heading, to: qiblaDirection)
    }

    var turnInstruction: String {
        let diff = relativeOffsetToQibla
        if abs(diff) <= 4.0 {
            return "Facing the Kaaba"
        } else if diff > 0 {
            return "Turn \(Int(diff.rounded()))° Right"
        } else {
            return "Turn \(Int(abs(diff).rounded()))° Left"
        }
    }

    var headingCardinal: String {
        Self.cardinalDirection(for: heading)
    }

    var qiblaCardinal: String {
        Self.cardinalDirection(for: qiblaDirection)
    }

    static func cardinalDirection(for degrees: Double) -> String {
        let normalized = (degrees.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
        let directions = ["North", "North-Northeast", "Northeast", "East-Northeast", "East", "East-Southeast", "Southeast", "South-Southeast", "South", "South-Southwest", "Southwest", "West-Southwest", "West", "West-Northwest", "Northwest", "North-Northwest"]
        let index = Int(((normalized + 11.25) / 22.5).rounded(.down)) % 16
        return directions[index]
    }

    var headingCardinalShort: String {
        let normalized = (heading.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int(((normalized + 11.25) / 22.5).rounded(.down)) % 16
        return directions[index]
    }

    var qiblaCardinalShort: String {
        let normalized = (qiblaDirection.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int(((normalized + 11.25) / 22.5).rounded(.down)) % 16
        return directions[index]
    }

    // MARK: - Recalculation

    func recalculateQibla(latitude: Double, longitude: Double) {
        if CLLocationManager.headingAvailable() {
            locationManager.stopUpdatingHeading()
            lastRawHeading = nil
            isFirstHeadingUpdate = true
            locationManager.startUpdatingHeading()
        }
        calculateQibla(latitude: latitude, longitude: longitude)
    }

    /// 100% on-device mathematical calculation of Qibla bearing.
    /// Employs Vincenty's inverse formula on the WGS-84 reference ellipsoid with spherical great-circle fallback.
    func calculateQibla(latitude: Double, longitude: Double) {
        guard latitude != 0 || longitude != 0 else { return }

        // Co-incident coordinates (standing at the Kaaba)
        if abs(latitude - Self.kaabaLatitude) < 0.0001 && abs(longitude - Self.kaabaLongitude) < 0.0001 {
            DispatchQueue.main.async {
                self.qiblaDirection = 0.0
            }
            return
        }

        let bearing = Self.computeWGS84GeodesicAzimuth(
            lat1: latitude,
            lon1: longitude,
            lat2: Self.kaabaLatitude,
            lon2: Self.kaabaLongitude
        )

        DispatchQueue.main.async {
            self.qiblaDirection = bearing
        }
    }

    // MARK: - Geodesic Azimuth (Vincenty Inverse)

    static func computeWGS84GeodesicAzimuth(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let phi1 = lat1 * .pi / 180.0
        let lambda1 = lon1 * .pi / 180.0
        let phi2 = lat2 * .pi / 180.0
        let lambda2 = lon2 * .pi / 180.0

        let L = lambda2 - lambda1
        let tanU1 = (1.0 - f) * tan(phi1)
        let cosU1 = 1.0 / sqrt(1.0 + tanU1 * tanU1)
        let sinU1 = tanU1 * cosU1

        let tanU2 = (1.0 - f) * tan(phi2)
        let cosU2 = 1.0 / sqrt(1.0 + tanU2 * tanU2)
        let sinU2 = tanU2 * cosU2

        var lambda = L
        var lambdaP = 2.0 * .pi
        var iterLimit = 100

        var sinLambda = 0.0
        var cosLambda = 0.0
        var sinSigma = 0.0
        var cosSigma = 0.0
        var sigma = 0.0
        var sinAlpha = 0.0
        var cosSqAlpha = 0.0
        var cos2SigmaM = 0.0
        var C = 0.0

        while abs(lambda - lambdaP) > 1e-12 && iterLimit > 0 {
            iterLimit -= 1
            sinLambda = sin(lambda)
            cosLambda = cos(lambda)

            let t1 = cosU2 * sinLambda
            let t2 = cosU1 * sinU2 - sinU1 * cosU2 * cosLambda
            sinSigma = sqrt(t1 * t1 + t2 * t2)

            if sinSigma == 0 {
                return 0.0 // Coincident points
            }

            cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda
            sigma = atan2(sinSigma, cosSigma)
            sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma
            cosSqAlpha = 1.0 - sinAlpha * sinAlpha

            if cosSqAlpha != 0 {
                cos2SigmaM = cosSigma - 2.0 * sinU1 * sinU2 / cosSqAlpha
            } else {
                cos2SigmaM = 0.0
            }

            C = f / 16.0 * cosSqAlpha * (4.0 + f * (4.0 - 3.0 * cosSqAlpha))
            lambdaP = lambda
            lambda = L + (1.0 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1.0 + 2.0 * cos2SigmaM * cos2SigmaM)))
        }

        // If Vincenty converges successfully
        if iterLimit > 0 {
            let y = cosU2 * sin(lambda)
            let x = cosU1 * sinU2 - sinU1 * cosU2 * cos(lambda)
            var alpha1 = atan2(y, x) * 180.0 / .pi
            alpha1 = (alpha1.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
            return alpha1
        }

        // Spherical Great Circle fallback
        return computeSphericalBearing(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2)
    }

    static func computeSphericalBearing(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let phi1 = lat1 * .pi / 180.0
        let lambda1 = lon1 * .pi / 180.0
        let phi2 = lat2 * .pi / 180.0
        let lambda2 = lon2 * .pi / 180.0

        let deltaLon = lambda2 - lambda1
        let y = sin(deltaLon) * cos(phi2)
        let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLon)

        let angle = atan2(y, x) * 180.0 / .pi
        return (angle.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
    }

    // MARK: - Distance Formatting with Unit Support

    func formattedDistanceToKaaba(userLat: Double, userLon: Double, unit: QiblaDistanceUnit = .kilometers) -> String {
        let lat = userLat != 0 ? userLat : Self.kaabaLatitude
        let lon = userLon != 0 ? userLon : Self.kaabaLongitude
        let userLocation = CLLocation(latitude: lat, longitude: lon)
        let kaabaLocation = CLLocation(latitude: Self.kaabaLatitude, longitude: Self.kaabaLongitude)
        let distanceMeters = userLocation.distance(from: kaabaLocation)

        let value: Double
        let unitSuffix: String
        switch unit {
        case .kilometers:
            value = distanceMeters / 1000.0
            unitSuffix = "km"
        case .miles:
            value = distanceMeters / 1609.344
            unitSuffix = "miles"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(formattedNumber) \(unitSuffix)"
    }
}

// MARK: - CLLocationManagerDelegate

extension QiblaManager: CLLocationManagerDelegate {
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateHeading newHeading: CLHeading
    ) {
        let northPref = UserDefaults.standard.string(forKey: "qiblaNorthReference") ?? "true"
        let preferTrue = northPref == "true"

        let isTrue = newHeading.trueHeading >= 0
        let validHeading = (preferTrue && isTrue) ? newHeading.trueHeading : newHeading.magneticHeading

        DispatchQueue.main.async {
            self.isTrueHeadingAvailable = isTrue
            self.headingAccuracy = newHeading.headingAccuracy
            self.heading = validHeading

            if self.isFirstHeadingUpdate || self.lastRawHeading == nil {
                // Initialize continuous angles smoothly to the shortest direct angle to avoid startup spins
                let initialRelative = Self.shortestAngleDelta(from: validHeading, to: self.qiblaDirection)
                self.continuousHeading = self.qiblaDirection - initialRelative
                self.continuousNeedleAngle = initialRelative
                self.isFirstHeadingUpdate = false
                self.lastRawHeading = validHeading
            } else if let prev = self.lastRawHeading {
                let delta = Self.shortestAngleDelta(from: prev, to: validHeading)
                // Filter micro-jitter below 0.15 degrees to stop needle from vibrating
                if abs(delta) >= 0.15 {
                    self.continuousHeading += delta
                    self.continuousNeedleAngle = self.qiblaDirection - self.continuousHeading
                    self.lastRawHeading = validHeading
                }
            }
        }
    }
}
