//
//  SurahHeader.swift
//  Deen+
//

import SwiftUI

struct SurahHeader: View {
    let surah: Int
    let arabicName: String

    var body: some View {
        let metadata = SurahMetadata.get(surah)

        VStack(spacing: 12) {
            // Surah Title & Metadata
            VStack(spacing: 6) {
                Text(arabicName)
                    .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 38))
                    .foregroundColor(.green)

                Text(metadata.englishName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(metadata.englishTranslation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Text(metadata.revelationPlace)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12), in: Capsule())
                        .foregroundColor(.green)

                    Text("\(metadata.totalAyahs) Ayahs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
            .padding(.top, 8)

            // Bismillah (for all surahs except Surah 9 At-Tawbah)
            if surah != 9 {
                Divider()
                    .padding(.horizontal, 40)
                    .padding(.vertical, 4)

                Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                    .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 24))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemBackground).opacity(0.7))
        .cornerRadius(16)
    }
}
