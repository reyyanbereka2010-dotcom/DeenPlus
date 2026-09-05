import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private let cachedCityKey = "cached_location_city"
    private let cachedCountryKey = "cached_location_country_code"
    private let cachedLatKey = "cached_location_lat"
    private let cachedLonKey = "cached_location_lon"

    @Published var city: String
    @Published var countryCode: String?
    @Published var latitude: Double
    @Published var longitude: Double

    override init() {
        // Load cached city, country code, and coordinates for offline support
        self.city = UserDefaults.standard.string(forKey: cachedCityKey) ?? "Unknown"
        self.countryCode = UserDefaults.standard.string(forKey: cachedCountryKey)
        self.latitude = UserDefaults.standard.double(forKey: cachedLatKey)
        self.longitude = UserDefaults.standard.double(forKey: cachedLonKey)

        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            manager.requestLocation()
        }
    }

    /// Explicitly forces a fresh GPS coordinate fix and reverse geocoding
    func recalculateLocation() {
        manager.stopUpdatingLocation()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        UserDefaults.standard.set(lat, forKey: cachedLatKey)
        UserDefaults.standard.set(lon, forKey: cachedLonKey)

        DispatchQueue.main.async {
            self.latitude = lat
            self.longitude = lon
        }

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                #if DEBUG
                print("Geocoding error:", error.localizedDescription)
                #endif
                return
            }

            guard let placemark = placemarks?.first else {
                #if DEBUG
                print("No placemark found")
                #endif
                return
            }

            let resolved = placemark.locality ??
                placemark.subAdministrativeArea ??
                placemark.administrativeArea ??
                "Unknown"

            if resolved != "Unknown" {
                UserDefaults.standard.set(resolved, forKey: self.cachedCityKey)
            }

            if let isoCode = placemark.isoCountryCode {
                UserDefaults.standard.set(isoCode, forKey: self.cachedCountryKey)
            }

            DispatchQueue.main.async {
                self.city = resolved
                if let isoCode = placemark.isoCountryCode {
                    self.countryCode = isoCode
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        print("Location error:", error.localizedDescription)
        #endif
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }
}
