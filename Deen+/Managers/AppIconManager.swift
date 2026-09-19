//
//  AppIconManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/9/26.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

enum AppIconOption: String, CaseIterable, Identifiable {
    case emerald = "AppIconEmerald"
    case original = "AppIconOriginal"
    case midnight = "AppIconMidnight"
    case teal = "AppIconTeal"
    case navy = "AppIconNavy"
    case gold = "AppIconGold"
    case monochrome = "AppIconMonochrome"
    case crimson = "AppIconCrimson"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .emerald: return "Emerald Classic"
        case .original: return "Original Compass"
        case .midnight: return "Midnight Obsidian"
        case .teal: return "Islamic Teal"
        case .navy: return "Royal Navy"
        case .gold: return "Warm Gold"
        case .monochrome: return "Pure Slate"
        case .crimson: return "Royal Crimson"
        }
    }

    var colorGradient: [Color] {
        switch self {
        case .emerald:
            return [Color(red: 0.05, green: 0.55, blue: 0.32), Color(red: 0.02, green: 0.35, blue: 0.20)]
        case .original:
            return [Color(red: 0.08, green: 0.48, blue: 0.36), Color(red: 0.03, green: 0.28, blue: 0.22)]
        case .midnight:
            return [Color(red: 0.15, green: 0.16, blue: 0.18), Color(red: 0.07, green: 0.07, blue: 0.08)]
        case .teal:
            return [Color(red: 0.05, green: 0.32, blue: 0.30), Color(red: 0.03, green: 0.20, blue: 0.20)]
        case .navy:
            return [Color(red: 0.06, green: 0.18, blue: 0.34), Color(red: 0.04, green: 0.10, blue: 0.22)]
        case .gold:
            return [Color(red: 0.76, green: 0.56, blue: 0.12), Color(red: 0.48, green: 0.35, blue: 0.06)]
        case .monochrome:
            return [Color(red: 0.22, green: 0.23, blue: 0.26), Color(red: 0.10, green: 0.10, blue: 0.12)]
        case .crimson:
            return [Color(red: 0.47, green: 0.09, blue: 0.15), Color(red: 0.22, green: 0.04, blue: 0.07)]
        }
    }

    var alternateIconName: String? {
        switch self {
        case .emerald:
            return nil // Primary AppIcon
        default:
            return rawValue
        }
    }

    /// Loads the high-resolution app icon artwork
    var previewImage: UIImage? {
        #if canImport(UIKit)
        if let img = UIImage(named: rawValue) {
            return img
        }
        if let path = Bundle.main.path(forResource: "\(rawValue)@3x", ofType: "png") ??
                      Bundle.main.path(forResource: rawValue, ofType: "png") ??
                      Bundle.main.path(forResource: rawValue, ofType: "png", inDirectory: "Icons") {
            return UIImage(contentsOfFile: path)
        }
        #endif
        return nil
    }
}

@MainActor
final class AppIconManager: ObservableObject {
    static let shared = AppIconManager()

    private let storageKey = "selectedAppIconOption"

    @Published var currentOption: String {
        didSet {
            UserDefaults.standard.set(currentOption, forKey: storageKey)
        }
    }

    init() {
        #if canImport(UIKit)
        if let alt = UIApplication.shared.alternateIconName, !alt.isEmpty {
            self.currentOption = alt
        } else {
            self.currentOption = UserDefaults.standard.string(forKey: storageKey) ?? AppIconOption.emerald.rawValue
        }
        #else
        self.currentOption = UserDefaults.standard.string(forKey: storageKey) ?? AppIconOption.emerald.rawValue
        #endif
    }

    var selectedOption: AppIconOption {
        AppIconOption(rawValue: currentOption) ?? .emerald
    }

    func setIcon(_ option: AppIconOption) {
        #if canImport(UIKit)
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Alternate icons not supported on this device/environment")
            self.currentOption = option.rawValue
            return
        }

        let targetName = option.alternateIconName
        UIApplication.shared.setAlternateIconName(targetName) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Alternate icon switch error: \(error.localizedDescription)")
                } else {
                    print("Successfully updated system icon to: \(targetName ?? "Primary")")
                }
                self?.currentOption = option.rawValue
            }
        }
        #else
        self.currentOption = option.rawValue
        #endif
    }
}
