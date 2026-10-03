//
//  AppIconManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/23/26.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

enum AppIconOption: String, CaseIterable, Identifiable {
    case original = "Original"
    case emerald = "Emerald"
    case gold = "Gold"
    case crimson = "Crimson"
    case midnight = "Midnight"
    case navy = "Navy"
    case teal = "Teal"
    case monochrome = "Monochrome"
    case arabesque = "Arabesque"
    case dome = "Dome"
    case kaaba = "Kaaba"
    case quran = "Quran"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .original: return "Original Green"
        case .emerald: return "Emerald Bay"
        case .gold: return "Royal Gold"
        case .crimson: return "Crimson Velvet"
        case .midnight: return "Midnight Obsidian"
        case .navy: return "Deep Navy"
        case .teal: return "Ocean Teal"
        case .monochrome: return "Monochrome Slate"
        case .arabesque: return "Arabesque Pattern"
        case .dome: return "Masjid Dome"
        case .kaaba: return "Holy Kaaba"
        case .quran: return "Noble Quran"
        }
    }

    var assetName: String {
        switch self {
        case .original: return "AppIconOriginal"
        case .emerald: return "AppIconEmerald"
        case .gold: return "AppIconGold"
        case .crimson: return "AppIconCrimson"
        case .midnight: return "AppIconMidnight"
        case .navy: return "Deep Navy"
        case .teal: return "AppIconTeal"
        case .monochrome: return "AppIconMonochrome"
        case .arabesque: return "AppIconArabesque"
        case .dome: return "AppIconDome"
        case .kaaba: return "AppIconKaaba"
        case .quran: return "AppIconQuran"
        }
    }

    /// The alternate icon name expected by iOS setAlternateIconName.
    /// If nil, resets to primary icon.
    var alternateIconName: String? {
        switch self {
        case .emerald, .original:
            return nil // Primary AppIcon
        case .gold:
            return "AppIconGold"
        case .crimson:
            return "AppIconCrimson"
        case .midnight:
            return "AppIconMidnight"
        case .navy:
            return "AppIconNavy"
        case .teal:
            return "AppIconTeal"
        case .monochrome:
            return "AppIconMonochrome"
        case .arabesque:
            return "AppIconArabesque"
        case .dome:
            return "AppIconDome"
        case .kaaba:
            return "AppIconKaaba"
        case .quran:
            return "AppIconQuran"
        }
    }
}

@MainActor
final class AppIconManager: ObservableObject {
    static let shared = AppIconManager()

    @AppStorage("selected_app_icon_option") var currentOption: String = AppIconOption.emerald.rawValue

    private init() {
        // Sync state with actual system icon if available
        #if canImport(UIKit)
        if let alt = UIApplication.shared.alternateIconName {
            self.currentOption = alt
        } else {
            self.currentOption = UserDefaults.standard.string(forKey: "selected_app_icon_option") ?? AppIconOption.emerald.rawValue
        }
        #else
        self.currentOption = UserDefaults.standard.string(forKey: "selected_app_icon_option") ?? AppIconOption.emerald.rawValue
        #endif
    }

    var selectedOption: AppIconOption {
        AppIconOption(rawValue: currentOption) ?? .emerald
    }

    func setIcon(_ option: AppIconOption) {
        #if canImport(UIKit)
        guard UIApplication.shared.supportsAlternateIcons else {
            #if DEBUG
            print("Alternate icons not supported on this device/environment")
            #endif
            self.currentOption = option.rawValue
            return
        }

        let targetName = option.alternateIconName
        UIApplication.shared.setAlternateIconName(targetName) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    #if DEBUG
                    print("Alternate icon switch error: \(error.localizedDescription)")
                    #endif
                } else {
                    #if DEBUG
                    print("Successfully updated system icon to: \(targetName ?? "Primary")")
                    #endif
                }
                self?.currentOption = option.rawValue
            }
        }
        #else
        self.currentOption = option.rawValue
        #endif
    }
}
