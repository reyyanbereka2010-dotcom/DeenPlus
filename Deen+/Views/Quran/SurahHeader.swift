//
//  SurahHeader.swift
//  Deen+
//

import SwiftUI

struct SurahHeader: View {
    let surah: Int
    let arabicName: String

    @AppStorage("quranReadingTheme") private var readingTheme: String = "standard"
    @Environment(\.colorScheme) private var colorScheme

    private var currentTheme: ReaderTheme {
        ReaderTheme(rawValue: readingTheme) ?? .standard
    }

    var body: some View {
        let metadata = SurahMetadata.get(surah)

        VStack(spacing: 12) {
            // Surah Title & Metadata
            VStack(spacing: 6) {
                Text(arabicName)
                    .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 38))
                    .foregroundStyle(currentTheme.accentColor(colorScheme: colorScheme))

                Text(metadata.englishName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(currentTheme.primaryTextColor(colorScheme: colorScheme))

                Text(metadata.englishTranslation)
                    .font(.subheadline)
                    .foregroundStyle(currentTheme.secondaryTextColor(colorScheme: colorScheme))

                HStack(spacing: 8) {
                    Text(metadata.revelationPlace)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(currentTheme.accentColor(colorScheme: colorScheme).opacity(0.14), in: Capsule())
                        .foregroundStyle(currentTheme.accentColor(colorScheme: colorScheme))

                    Text("\(metadata.totalAyahs) Ayahs")
                        .font(.caption)
                        .foregroundStyle(currentTheme.secondaryTextColor(colorScheme: colorScheme))
                }
                .padding(.top, 2)
            }
            .padding(.top, 8)

            // Bismillah (for all surahs except Surah 9 At-Tawbah)
            if surah != 9 {
                Divider()
                    .overlay(currentTheme.cardBorderColor(colorScheme: colorScheme))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 4)

                Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                    .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 24))
                    .foregroundStyle(currentTheme.primaryTextColor(colorScheme: colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(currentTheme.cardBackgroundColor(colorScheme: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(currentTheme.cardBorderColor(colorScheme: colorScheme), lineWidth: 1)
        )
    }
}
