//
//  AppIconSelectionView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/9/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AppIconSelectionView: View {
    @ObservedObject private var iconManager = AppIconManager.shared
    @AppStorage("appAccentColor") private var appAccentColor: String = "emerald"

    private var accent: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    var body: some View {
        List {
            Section {
                ForEach(AppIconOption.allCases) { option in
                    Button {
                        triggerHaptic()
                        iconManager.setIcon(option)
                    } label: {
                        HStack(spacing: 16) {
                            // Icon Preview Squircle
                            AppIconPreviewBox(option: option)

                            Text(option.title)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Spacer()

                            if iconManager.selectedOption == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(accent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text("Select an icon to display on your Home Screen and App Library. Each icon supports native iOS 18 Light, Dark, and Tinted customization.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        #endif
    }
}

// MARK: - App Icon Preview Box Component

struct AppIconPreviewBox: View {
    let option: OptionType

    typealias OptionType = AppIconOption

    private var fallbackIcon: String {
        switch option {
        case .original:
            return "location.north.circle.fill"
        default:
            return "moon.stars.fill"
        }
    }

    var body: some View {
        ZStack {
            if let uiImage = option.previewImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // High-fidelity vector fallback
                LinearGradient(
                    colors: option.colorGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: fallbackIcon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(option == .monochrome ? Color.white : Color(red: 0.95, green: 0.85, blue: 0.50))
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
    }
}
