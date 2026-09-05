//
//  QiblaManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/21/26.
//

import Foundation
import CoreLocation
import Combine

class QiblaManager: NSObject, ObservableObject {
    
    @Published var displayedRotation: Double = 0
    @Published var heading: Double = 0 {
        didSet { updateDisplayedRotation() }
    }
    @Published var qiblaDirection: Double = 0 {
        didSet { updateDisplayedRotation() }
    }

    private let locationManager = CLLocationManager()
    private let kaabaLatitude = 21.4225
    private let kaabaLongitude = 39.8262

    override init() {
        super.init()

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
        
        // Default calculation
        calculateQibla(latitude: 21.4225, longitude: 39.8262)
    }
    
    private func updateDisplayedRotation() {
        let targetRotation = qiblaDirection - heading
        let diff = targetRotation - displayedRotation
        
        var shortestDiff = diff.truncatingRemainder(dividingBy: 360)
        
        if shortestDiff > 180 {
            shortestDiff -= 360
        } else if shortestDiff < -180 {
            shortestDiff += 360
        }
        
        displayedRotation += shortestDiff
    }

    var arrowRotation: Double {
        var angle = qiblaDirection - heading

        while angle < -180 {
            angle += 360
        }

        while angle > 180 {
            angle -= 360
        }

        return angle
    }
    
    var isFacingQibla: Bool {
        abs(arrowRotation) <= 5
    }

    /// Recalculates Qibla direction, resets heading tracking, and re-computes azimuth
    func recalculateQibla(latitude: Double, longitude: Double) {
        if CLLocationManager.headingAvailable() {
            locationManager.stopUpdatingHeading()
            locationManager.startUpdatingHeading()
        }
        calculateQibla(latitude: latitude, longitude: longitude)
    }

    func calculateQibla(latitude: Double, longitude: Double) {
        guard latitude != 0 || longitude != 0 else {
            // Fallback to Kaaba calculation
            calculateQibla(latitude: kaabaLatitude, longitude: kaabaLongitude)
            return
        }

        let userLat = latitude * .pi / 180
        let userLon = longitude * .pi / 180

        let kaabaLat = kaabaLatitude * .pi / 180
        let kaabaLon = kaabaLongitude * .pi / 180

        let deltaLon = kaabaLon - userLon

        let y = sin(deltaLon) * cos(kaabaLat)
        let x = cos(userLat) * sin(kaabaLat) - sin(userLat) * cos(kaabaLat) * cos(deltaLon)

        let angle = atan2(y, x)
        let degrees = angle * 180 / .pi
        let calculated = (degrees + 360).truncatingRemainder(dividingBy: 360)

        DispatchQueue.main.async {
            self.qiblaDirection = calculated
        }
    }
}

extension QiblaManager: CLLocationManagerDelegate {
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateHeading newHeading: CLHeading
    ) {
        let validHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        DispatchQueue.main.async {
            self.heading = validHeading
        }
    }
}
