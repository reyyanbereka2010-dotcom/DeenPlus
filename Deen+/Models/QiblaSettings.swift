//
//  QiblaSettings.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/12/26.
//

import SwiftUI

// MARK: - Auto Setting Chooser Mode

enum QiblaConfigurationMode: String, CaseIterable, Identifiable {
    case automatic = "auto"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .automatic: return "wand.and.stars"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Auto Settings Resolver

struct QiblaAutoSettings {
    /// Detects whether user region uses Miles or Kilometers
    static func autoDistanceUnit() -> QiblaDistanceUnit {
        let regionCode = Locale.current.region?.identifier.uppercased() ?? "US"
        if regionCode == "US" || regionCode == "GB" || regionCode == "LR" || regionCode == "MM" {
            return .miles
        } else {
            return .kilometers
        }
    }

    /// Resets / applies all recommended settings for a simplified experience.
    /// Preserves user's preferred dial and needle design!
    static func applyRecommended() {
        let defaults = UserDefaults.standard
        defaults.set(QiblaConfigurationMode.automatic.rawValue, forKey: "qiblaConfigMode")
        defaults.set(autoDistanceUnit().rawValue, forKey: "qiblaDistanceUnit")
        defaults.set(QiblaNorthReference.trueNorth.rawValue, forKey: "qiblaNorthReference")
        defaults.set(true, forKey: "qiblaHapticEnabled")
        defaults.set(QiblaHapticIntensity.crisp.rawValue, forKey: "qiblaHapticIntensity")
        defaults.set(false, forKey: "qiblaShowLevelBubble")
        defaults.set(4.0, forKey: "qiblaAlignmentTolerance")
    }
}

// MARK: - Compass Dial Style

enum QiblaCompassDialStyle: String, CaseIterable, Identifiable {
    case modern = "modern"
    case arabesque = "arabesque"
    case astrolabe = "astrolabe"
    case oled = "oled"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .modern: return "Modern Precision"
        case .arabesque: return "Islamic Heritage"
        case .astrolabe: return "Astrolabe Nav"
        case .oled: return "Minimal OLED"
        }
    }

    var icon: String {
        switch self {
        case .modern: return "circle.dashed"
        case .arabesque: return "sparkles"
        case .astrolabe: return "globe.desk.fill"
        case .oled: return "moon.fill"
        }
    }
}

// MARK: - Compass Needle Style

enum QiblaNeedleStyle: String, CaseIterable, Identifiable {
    case kaaba = "kaaba"
    case crescent = "crescent"
    case aero = "aero"
    case orbital = "orbital"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kaaba: return "Holy Kaaba"
        case .crescent: return "Golden Crescent"
        case .aero: return "Precision Aero"
        case .orbital: return "Orbital Bezel"
        }
    }

    var icon: String {
        switch self {
        case .kaaba: return "cube.fill"
        case .crescent: return "moon.stars.fill"
        case .aero: return "location.north.fill"
        case .orbital: return "circle.circle.fill"
        }
    }
}

// MARK: - Distance Unit

enum QiblaDistanceUnit: String, CaseIterable, Identifiable {
    case kilometers = "km"
    case miles = "mi"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kilometers: return "Kilometers (km)"
        case .miles: return "Miles (mi)"
        }
    }

    var symbol: String {
        switch self {
        case .kilometers: return "km"
        case .miles: return "mi"
        }
    }
}

// MARK: - North Reference

enum QiblaNorthReference: String, CaseIterable, Identifiable {
    case trueNorth = "true"
    case magneticNorth = "magnetic"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .trueNorth: return "True Geographic North"
        case .magneticNorth: return "Magnetic North"
        }
    }
}

// MARK: - Haptic Intensity

enum QiblaHapticIntensity: String, CaseIterable, Identifiable {
    case subtle = "subtle"
    case crisp = "crisp"
    case strong = "strong"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .subtle: return "Subtle"
        case .crisp: return "Crisp"
        case .strong: return "Strong"
        }
    }
}
