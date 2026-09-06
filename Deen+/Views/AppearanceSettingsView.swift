//
//  AppearanceSettingsView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/6/26.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("appTheme") private var appTheme: String = "System"
    @AppStorage("appAccentColor") private var appAccentColor: String = "emerald"
    @AppStorage("menuBarStyle") private var menuBarStyle: String = "pill"
    @AppStorage("quranReadingTheme") private var quranReadingTheme: String = "standard"
    @AppStorage("quranArabicFontSize") private var quranArabicFontSize: Double = 26
    @AppStorage("quranTranslationFontSize") private var quranTranslationFontSize: Double = 16
    @AppStorage("quranShowTranslation") private var quranShowTranslation: Bool = true
    @AppStorage("quranKeepScreenAwake") private var quranKeepScreenAwake: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    private var activeAccent: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    private var activeReaderTheme: ReaderTheme {
        ReaderTheme(rawValue: quranReadingTheme) ?? .standard
    }

    var body: some View {
        Form {
            // MARK: - Hero Header
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [activeAccent.opacity(0.85), Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: activeAccent.opacity(0.3), radius: 8, x: 0, y: 3)

                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }

                    Text("Theme & Appearance")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 4)
            }

            // MARK: - App Color Scheme
            Section {
                HStack(spacing: 12) {
                    themeCard(title: "System", icon: "circle.lefthalf.filled", value: "System")
                    themeCard(title: "Light", icon: "sun.max.fill", value: "Light")
                    themeCard(title: "Dark", icon: "moon.fill", value: "Dark")
                }
                .padding(.vertical, 6)
            } header: {
                Label("App Color Mode", systemImage: "circle.lefthalf.filled")
                    .foregroundStyle(activeAccent)
            } footer: {
                Text("Select System to automatically mirror your iPhone's appearance settings.")
            }

            // MARK: - Global Accent Color
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(AppAccentColor.allCases) { accent in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                appAccentColor = accent.rawValue
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(accent.color.gradient)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: accent.color.opacity(0.35), radius: 4, x: 0, y: 2)

                                    if appAccentColor == accent.rawValue {
                                        Image(systemName: "checkmark")
                                            .font(.headline.bold())
                                            .foregroundStyle(.white)
                                    }
                                }

                                Text(accent.displayName)
                                    .font(.caption2.weight(appAccentColor == accent.rawValue ? .bold : .medium))
                                    .foregroundStyle(appAccentColor == accent.rawValue ? Color.primary : Color.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(appAccentColor == accent.rawValue ? accent.color.opacity(0.10) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
            } header: {
                Label("Global Accent Tint", systemImage: "paintpalette.fill")
                    .foregroundStyle(activeAccent)
            } footer: {
                Text("Applies to buttons, navigation highlights, active prayer indicators, and badges throughout the app.")
            }

            // MARK: - Navigation Menu Bar Style
            Section {
                Picker("Menu Bar Style", selection: $menuBarStyle) {
                    Text("Modern Pill / Rectangle").tag("pill")
                    Text("Floating Capsule").tag("floating")
                    Text("Standard Tab Bar").tag("standard")
                }
                .pickerStyle(.menu)
            } header: {
                Label("Navigation Bar Style", systemImage: "menubar.rectangle")
                    .foregroundStyle(activeAccent)
            } footer: {
                Text("Choose between an elevated modern pill, floating capsule, or native iOS bottom tab bar.")
            }

            // MARK: - Quran Reader Theme Preview & Selection
            Section {
                // Live Interactive Theme Preview Card
                VStack(spacing: 12) {
                    HStack {
                        Text("Live Theme Preview")
                            .font(.caption.bold())
                            .foregroundStyle(activeReaderTheme.secondaryTextColor(colorScheme: colorScheme))
                        Spacer()
                        Text("Surah Al-Fatihah • Ayah 1")
                            .font(.caption2)
                            .foregroundStyle(activeReaderTheme.secondaryTextColor(colorScheme: colorScheme))
                    }

                    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                        .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: CGFloat(quranArabicFontSize)))
                        .foregroundStyle(activeReaderTheme.primaryTextColor(colorScheme: colorScheme))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    if quranShowTranslation {
                        Text("In the name of Allah, the Entirely Merciful, the Especially Merciful.")
                            .font(.system(size: CGFloat(quranTranslationFontSize)))
                            .foregroundStyle(activeReaderTheme.secondaryTextColor(colorScheme: colorScheme))
                            .multilineTextAlignment(.center)
                    }

                    HStack {
                        HStack(spacing: 4) {
                            Text("Ayah")
                                .font(.caption2)
                                .foregroundStyle(activeReaderTheme.secondaryTextColor(colorScheme: colorScheme))
                            Text("1")
                                .font(.caption.bold())
                                .foregroundStyle(activeReaderTheme.accentColor(colorScheme: colorScheme))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(activeReaderTheme.accentColor(colorScheme: colorScheme).opacity(0.14), in: Capsule())

                        Spacer()

                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(activeReaderTheme.accentColor(colorScheme: colorScheme))
                    }
                }
                .padding(16)
                .background(activeReaderTheme.cardBackgroundColor(colorScheme: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(activeReaderTheme.cardBorderColor(colorScheme: colorScheme), lineWidth: 1)
                )
                .padding(.vertical, 6)

                // Reader Theme Selector Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(ReaderTheme.allCases) { theme in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                quranReadingTheme = theme.rawValue
                            }
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(theme.cardBackgroundColor(colorScheme: colorScheme))
                                        .frame(height: 52)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(quranReadingTheme == theme.rawValue ? theme.accentColor(colorScheme: colorScheme) : theme.cardBorderColor(colorScheme: colorScheme), lineWidth: quranReadingTheme == theme.rawValue ? 2.5 : 1)
                                        )

                                    HStack(spacing: 4) {
                                        Image(systemName: theme.icon)
                                            .font(.caption2)
                                            .foregroundStyle(theme.accentColor(colorScheme: colorScheme))
                                        Text("بِسْمِ اللَّهِ")
                                            .font(.caption2)
                                            .foregroundStyle(theme.primaryTextColor(colorScheme: colorScheme))
                                    }

                                    if quranReadingTheme == theme.rawValue {
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(theme.accentColor(colorScheme: colorScheme))
                                                    .padding(4)
                                            }
                                            Spacer()
                                        }
                                    }
                                }

                                Text(theme.shortName)
                                    .font(.caption2.weight(quranReadingTheme == theme.rawValue ? .bold : .medium))
                                    .foregroundStyle(quranReadingTheme == theme.rawValue ? Color.primary : Color.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Label("Quran Reader Theme", systemImage: "book.pages.fill")
                    .foregroundStyle(activeAccent)
            } footer: {
                Text("Warm Sepia emulates physical Mushaf paper, while AMOLED Night saves battery and prevents glare.")
            }

            // MARK: - Font Sizing
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Arabic Calligraphy Font Size")
                        Spacer()
                        Text("\(Int(quranArabicFontSize)) pt")
                            .font(.subheadline.bold())
                            .foregroundStyle(activeAccent)
                    }
                    Slider(value: $quranArabicFontSize, in: 18...38, step: 2)
                        .tint(activeAccent)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Translation Font Size")
                        Spacer()
                        Text("\(Int(quranTranslationFontSize)) pt")
                            .font(.subheadline.bold())
                            .foregroundStyle(activeAccent)
                    }
                    Slider(value: $quranTranslationFontSize, in: 13...24, step: 1)
                        .tint(activeAccent)
                }
                .padding(.vertical, 4)
            } header: {
                Label("Typography Sizing", systemImage: "textformat.size")
                    .foregroundStyle(activeAccent)
            }

            // MARK: - Reader Display Preferences
            Section {
                Toggle("Show English Translation", isOn: $quranShowTranslation)
                Toggle("Keep Screen Awake in Reader", isOn: $quranKeepScreenAwake)
            } header: {
                Label("Reader Display", systemImage: "eye.fill")
                    .foregroundStyle(activeAccent)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subview Helpers

    private func themeCard(title: String, icon: String, value: String) -> some View {
        let isSelected = appTheme == value
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appTheme = value
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? activeAccent : Color.secondary)

                Text(title)
                    .font(.caption.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(activeAccent)
                } else {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        .frame(width: 12, height: 12)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? activeAccent.opacity(0.12) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? activeAccent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
