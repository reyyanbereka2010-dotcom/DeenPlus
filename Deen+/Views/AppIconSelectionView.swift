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

                            Text(option.displayName)
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
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }
}

// MARK: - App Icon Preview Box Component

struct AppIconPreviewBox: View {
    let option: AppIconOption

    var body: some View {
        ZStack {
            if let uiImage = UIImage(named: option.assetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Sleek fallback preview if image asset is missing in catalog
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.8), Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "book.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    )
            }
        }
        .frame(width: 54, height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
    }
}
