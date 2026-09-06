//
//  ReaderTheme.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/6/26.
//

import SwiftUI

enum ReaderTheme: String, CaseIterable, Identifiable, Sendable {
    case standard = "standard"
    case sepia = "sepia"
    case black = "black"
    case dark = "dark"
    case emerald = "emerald"
    case mint = "mint"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "Classic System"
        case .sepia: return "Warm Sepia"
        case .black: return "AMOLED Night"
        case .dark: return "Slate Dark"
        case .emerald: return "Madinah Emerald"
        case .mint: return "Soft Mint"
        }
    }

    var shortName: String {
        switch self {
        case .standard: return "System"
        case .sepia: return "Sepia"
        case .black: return "AMOLED"
        case .dark: return "Slate"
        case .emerald: return "Emerald"
        case .mint: return "Mint"
        }
    }

    var icon: String {
        switch self {
        case .standard: return "circle.lefthalf.filled"
        case .sepia: return "book.closed.fill"
        case .black: return "moon.stars.fill"
        case .dark: return "moon.fill"
        case .emerald: return "leaf.fill"
        case .mint: return "sparkles"
        }
    }

    var description: String {
        switch self {
        case .standard: return "Adapts automatically to iOS Light or Dark mode"
        case .sepia: return "Authentic warm parchment paper reminiscent of a physical Mushaf"
        case .black: return "Pure pitch black for OLED displays and night Tahajjud reading"
        case .dark: return "Refined low-contrast dark slate to ease eye fatigue"
        case .emerald: return "Deep Islamic green aesthetic inspired by the Prophet's Mosque"
        case .mint: return "Soothing light sage for comfortable daytime recitation"
        }
    }

    func backgroundColor(colorScheme: ColorScheme) -> Color {
        switch self {
        case .standard:
            return Color(uiColor: .systemGroupedBackground)
        case .sepia:
            return colorScheme == .dark
                ? Color(red: 0.14, green: 0.12, blue: 0.09)
                : Color(red: 0.97, green: 0.95, blue: 0.91)
        case .black:
            return Color.black
        case .dark:
            return Color(red: 0.08, green: 0.10, blue: 0.13)
        case .emerald:
            return colorScheme == .dark
                ? Color(red: 0.05, green: 0.11, blue: 0.08)
                : Color(red: 0.93, green: 0.97, blue: 0.95)
        case .mint:
            return Color(red: 0.94, green: 0.97, blue: 0.95)
        }
    }

    func cardBackgroundColor(colorScheme: ColorScheme) -> Color {
        switch self {
        case .standard:
            return Color(uiColor: .secondarySystemGroupedBackground)
        case .sepia:
            return colorScheme == .dark
                ? Color(red: 0.19, green: 0.16, blue: 0.13)
                : Color(red: 0.93, green: 0.90, blue: 0.84)
        case .black:
            return Color(red: 0.08, green: 0.08, blue: 0.09)
        case .dark:
            return Color(red: 0.12, green: 0.15, blue: 0.19)
        case .emerald:
            return colorScheme == .dark
                ? Color(red: 0.08, green: 0.16, blue: 0.12)
                : Color(red: 0.88, green: 0.94, blue: 0.91)
        case .mint:
            return Color.white
        }
    }

    func cardBorderColor(colorScheme: ColorScheme) -> Color {
        switch self {
        case .standard:
            return Color.clear
        case .sepia:
            return colorScheme == .dark
                ? Color(red: 0.28, green: 0.24, blue: 0.19).opacity(0.6)
                : Color(red: 0.85, green: 0.81, blue: 0.73)
        case .black:
            return Color(white: 0.16)
        case .dark:
            return Color(red: 0.19, green: 0.23, blue: 0.29)
        case .emerald:
            return colorScheme == .dark
                ? Color(red: 0.14, green: 0.26, blue: 0.20)
                : Color(red: 0.76, green: 0.86, blue: 0.80)
        case .mint:
            return Color(red: 0.80, green: 0.89, blue: 0.84)
        }
    }

    func primaryTextColor(colorScheme: ColorScheme) -> Color {
        switch self {
        case .standard:
            return Color.primary
        case .sepia:
            return colorScheme == .dark
                ? Color(red: 0.94, green: 0.91, blue: 0.85)
                : Color(red: 0.17, green: 0.13, blue: 0.09)
        case .black:
            return Color.white
        case .dark:
            return Color(red: 0.94, green: 0.96, blue: 0.98)
        case .emerald:
            return colorScheme == .dark
                ? Color(red: 0.91, green: 0.96, blue: 0.93)
                : Color(red: 0.04, green: 0.18, blue: 0.12)
        case .mint:
            return Color(red: 0.08, green: 0.20, blue: 0.14)
        }
    }

    func secondaryTextColor(colorScheme: ColorScheme) -> Color {
        switch self {
        case .standard:
            return Color.secondary
        case .sepia:
            return colorScheme == .dark
                ? Color(red: 0.73, green: 0.69, blue: 0.61)
                : Color(red: 0.40, green: 0.33, blue: 0.26)
        case .black:
            return Color(white: 0.65)
        case .dark:
            return Color(red: 0.60, green: 0.66, blue: 0.74)
        case .emerald:
            return colorScheme == .dark
                ? Color(red: 0.66, green: 0.80, blue: 0.73)
                : Color(red: 0.22, green: 0.42, blue: 0.33)
        case .mint:
            return Color(red: 0.30, green: 0.48, blue: 0.39)
        }
    }

    func accentColor(colorScheme: ColorScheme) -> Color {
        switch self {
        case .standard, .black, .dark:
            return Color.green
        case .sepia:
            return Color(red: 0.76, green: 0.54, blue: 0.15)
        case .emerald:
            return Color(red: 0.12, green: 0.72, blue: 0.46)
        case .mint:
            return Color(red: 0.08, green: 0.60, blue: 0.40)
        }
    }
}
