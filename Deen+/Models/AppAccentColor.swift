//
//  AppAccentColor.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/6/26.
//

import SwiftUI

enum AppAccentColor: String, CaseIterable, Identifiable, Sendable {
    case emerald = "emerald"
    case teal = "teal"
    case blue = "blue"
    case amber = "amber"
    case rose = "rose"
    case purple = "purple"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .emerald: return "Emerald Green"
        case .teal: return "Islamic Teal"
        case .blue: return "Ocean Blue"
        case .amber: return "Warm Gold"
        case .rose: return "Rose Carmine"
        case .purple: return "Royal Violet"
        }
    }

    var color: Color {
        switch self {
        case .emerald: return Color.green
        case .teal: return Color.teal
        case .blue: return Color.blue
        case .amber: return Color.orange
        case .rose: return Color.pink
        case .purple: return Color.purple
        }
    }

    var icon: String {
        switch self {
        case .emerald: return "leaf.fill"
        case .teal: return "drop.fill"
        case .blue: return "water.waves"
        case .amber: return "sun.max.fill"
        case .rose: return "heart.fill"
        case .purple: return "sparkles"
        }
    }
}
