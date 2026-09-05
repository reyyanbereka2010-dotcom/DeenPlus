//
//  DailyDuasView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/5/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum DuaCategory: String, CaseIterable, Identifiable {
    case morningEvening = "Morning & Evening"
    case daily = "Daily Life"
    case prayer = "Prayer & Forgiveness"

    var id: String { rawValue }
}

struct DuaItem: Identifiable {
    let id = UUID()
    let category: DuaCategory
    let title: String
    let arabic: String
    let transliteration: String
    let translation: String
    let reference: String
    let targetCount: Int
}

struct DailyDuasView: View {

    @State private var selectedCategory: DuaCategory = .morningEvening
    @State private var duaCounts: [UUID: Int] = [:]

    private let duas: [DuaItem] = [
        // Morning & Evening
        DuaItem(
            category: .morningEvening,
            title: "Morning Remembrance",
            arabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ",
            transliteration: "Asbahna wa-asbahal-mulku lillah, wal-hamdulillahi, la ilaha illallahu wahdahu la shareeka lah",
            translation: "We have reached the morning and the dominion belongs to Allah, all praise is due to Allah, none has the right to be worshipped except Allah alone without partner.",
            reference: "Sahih Muslim",
            targetCount: 1
        ),
        DuaItem(
            category: .morningEvening,
            title: "Seeking Protection",
            arabic: "بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلاَ فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
            transliteration: "Bismillāhilladhī lā yadurru ma'as-mihī shay'un fil-ardi walā fis-samā'i wa huwas-Samī'ul-'Alīm",
            translation: "In the name of Allah, with whose name nothing on earth or in the heavens can cause harm, and He is the All-Hearing, All-Knowing.",
            reference: "Abu Dawud & At-Tirmidhi (3x)",
            targetCount: 3
        ),
        DuaItem(
            category: .morningEvening,
            title: "Sayyid al-Istighfar (Chief of Prayers for Forgiveness)",
            arabic: "اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ",
            transliteration: "Allahumma Anta Rabbi, la ilaha illa Anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika mastata'tu, a'udhu bika min sharri ma sana'tu, abu'u laka bini'matika 'alayya, wa abu'u bidhanbi faghfir li, fa innahu la yaghfirudh-dhunuba illa Anta",
            translation: "O Allah, You are my Lord, there is none worthy of worship except You. You created me and I am Your servant, and I abide by Your covenant and promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your favors upon me and I confess my sins, so forgive me, for none forgives sins except You.",
            reference: "Sahih al-Bukhari",
            targetCount: 1
        ),
        // Daily Life
        DuaItem(
            category: .daily,
            title: "Before Sleeping",
            arabic: "بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ",
            transliteration: "Bismika Rabbi wada'tu janbi wa bika arfa'uh, fa in amsakta nafsi farhamha, wa in arsaltaha fahfazha bima tahfazu bihi 'ibadakas-salihin",
            translation: "In Your name my Lord, I lie down and in Your name I rise. If You take my soul, have mercy upon it, and if You release it, protect it as You protect Your righteous servants.",
            reference: "Sahih al-Bukhari & Muslim",
            targetCount: 1
        ),
        DuaItem(
            category: .daily,
            title: "Leaving the House",
            arabic: "بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ",
            transliteration: "Bismillahi tawakkaltu 'alallahi, la hawla wa la quwwata illa billah",
            translation: "In the name of Allah, I place my trust in Allah. There is no might nor power except with Allah.",
            reference: "Abu Dawud & At-Tirmidhi",
            targetCount: 1
        ),
        DuaItem(
            category: .daily,
            title: "Before Eating",
            arabic: "بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ",
            transliteration: "Bismillahi wa 'ala barakatillah",
            translation: "In the name of Allah and with the blessings of Allah.",
            reference: "Al-Hakim",
            targetCount: 1
        ),
        // Prayer & Forgiveness
        DuaItem(
            category: .prayer,
            title: "Dua for Parents (Surah Al-Isra 17:24)",
            arabic: "رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا",
            transliteration: "Rabbi irhamhuma kama rabbayani sagheera",
            translation: "My Lord, have mercy upon them as they brought me up when I was small.",
            reference: "Quran (17:24)",
            targetCount: 3
        ),
        DuaItem(
            category: .prayer,
            title: "For Good in this Life & the Next (2:201)",
            arabic: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
            transliteration: "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
            translation: "Our Lord, give us in this world that which is good and in the Hereafter that which is good, and save us from the torment of the Fire.",
            reference: "Quran (2:201)",
            targetCount: 3
        ),
        DuaItem(
            category: .prayer,
            title: "Supplication in Sujood",
            arabic: "سُبْحَانَ رَبِّيَ الأَعْلَى وَبِحَمْدِهِ",
            transliteration: "Subhana Rabbiyal-A'la wa bihamdih",
            translation: "Glory be to my Lord, the Most High, and praise be to Him.",
            reference: "Sunan Abu Dawud (3x)",
            targetCount: 3
        )
    ]

    private var filteredDuas: [DuaItem] {
        duas.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(DuaCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowBackground(Color.clear)
                }

                ForEach(filteredDuas) { dua in
                    DuaCardRow(
                        dua: dua,
                        count: duaCounts[dua.id] ?? 0,
                        onIncrement: {
                            #if canImport(UIKit)
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            #endif
                            let cur = duaCounts[dua.id] ?? 0
                            duaCounts[dua.id] = cur + 1
                        },
                        onReset: {
                            duaCounts[dua.id] = 0
                        }
                    )
                }
            }
            .navigationTitle("Daily Duas")
        }
    }
}

struct DuaCardRow: View {
    let dua: DuaItem
    let count: Int
    let onIncrement: () -> Void
    let onReset: () -> Void

    private var isCompleted: Bool {
        count >= dua.targetCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dua.title)
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Text(dua.reference)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Arabic Text
            Text(dua.arabic)
                .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 22))
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(Color.green)

            // Transliteration
            Text(dua.transliteration)
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)

            // Translation
            Text(dua.translation)
                .font(.subheadline)
                .foregroundStyle(.primary)

            // Counter Button Bar
            HStack {
                Button(action: onIncrement) {
                    HStack(spacing: 8) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "hand.tap.fill")
                        Text(isCompleted ? "Completed" : "Count: \(count)/\(dua.targetCount)")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isCompleted ? Color.green : Color.green.opacity(0.15))
                    .foregroundStyle(isCompleted ? Color.white : Color.green)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if count > 0 {
                    Button(action: onReset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 6)
    }
}
