//
//  QuranView.swift
//  Deen+
//

import SwiftUI

enum QuranBrowseMode: String, CaseIterable, Identifiable {
    case surah = "Surahs"
    case juz = "Juz (30)"
    
    var id: String { rawValue }
}

enum QuranRevelationFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case meccan = "Meccan"
    case medinan = "Medinan"
    
    var id: String { rawValue }
}

struct QuranView: View {

    @ObservedObject private var recitationPlayer = RecitationPlayer.shared
    @State private var recent: RecentlyRead?
    @State private var searchText = ""
    @State private var browseMode: QuranBrowseMode = .surah
    @State private var selectedFilter: QuranRevelationFilter = .all

    private var filteredSurahs: [Int] {
        (1...114).filter { number in
            let metadata = SurahMetadata.get(number)
            let arabic = SurahNames.name(for: number)
            
            // Filter by revelation place
            if selectedFilter == .meccan && metadata.revelationPlace.lowercased() != "makkah" && metadata.revelationPlace.lowercased() != "meccan" {
                return false
            }
            if selectedFilter == .medinan && metadata.revelationPlace.lowercased() != "madinah" && metadata.revelationPlace.lowercased() != "medinan" {
                return false
            }
            
            // Search text filter
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if q.isEmpty { return true }
            
            return metadata.englishName.lowercased().contains(q) ||
                   arabic.contains(q) ||
                   "\(number)".contains(q)
        }
    }

    private var filteredJuz: [JuzInfo] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return JuzMetadata.allJuz }
        return JuzMetadata.allJuz.filter {
            $0.englishTitle.lowercased().contains(q) ||
            $0.arabicName.contains(q) ||
            "\($0.id)".contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                List {
                    if let recent, searchText.isEmpty {
                        Section {
                            NavigationLink {
                                SurahReaderView(
                                    surah: recent.surah,
                                    arabicName: SurahNames.name(for: recent.surah),
                                    resumeVerse: recent.verse
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: "book.fill")
                                            .foregroundStyle(.green)

                                        Text("Continue Reading")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.green)
                                    }

                                    Text(recent.surahName)
                                        .font(.headline)

                                    Text("Ayah \(recent.verse)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    // Browse Mode Switcher (Surahs vs Juz)
                    Section {
                        Picker("Browse Mode", selection: $browseMode) {
                            ForEach(QuranBrowseMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 4, trailing: 12))
                        .listRowBackground(Color.clear)
                    }

                    if browseMode == .surah {
                        // Revelation Filter for Surahs
                        Section {
                            Picker("Revelation Filter", selection: $selectedFilter) {
                                ForEach(QuranRevelationFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)
                            .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 6, trailing: 12))
                            .listRowBackground(Color.clear)
                        }

                        if filteredSurahs.isEmpty {
                            Section {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.secondary)
                                    Text("No Surahs Found")
                                        .font(.headline)
                                    Text("No surah matches '\(searchText)'")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 30)
                            }
                        } else {
                            Section("Surahs (\(filteredSurahs.count))") {
                                ForEach(filteredSurahs, id: \.self) { number in
                                    let arabic = SurahNames.name(for: number)
                                    let metadata = SurahMetadata.get(number)

                                    NavigationLink {
                                        SurahReaderView(
                                            surah: number,
                                            arabicName: arabic
                                        )
                                    } label: {
                                        HStack(spacing: 12) {
                                            Text("\(number)")
                                                .font(.headline)
                                                .frame(width: 32, alignment: .leading)
                                                .foregroundStyle(.secondary)

                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(metadata.englishName)
                                                    .font(.headline)

                                                Text("\(metadata.revelationPlace) • \(metadata.totalAyahs) Ayahs")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }

                                            Spacer()

                                            Text(arabic)
                                                .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 22))
                                                .foregroundStyle(.green)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    } else {
                        // Juz Mode (30 Paras)
                        if filteredJuz.isEmpty {
                            Section {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.secondary)
                                    Text("No Juz Found")
                                        .font(.headline)
                                    Text("No juz matches '\(searchText)'")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 30)
                            }
                        } else {
                            Section("All 30 Juz (\(filteredJuz.count))") {
                                ForEach(filteredJuz) { juz in
                                    NavigationLink {
                                        SurahReaderView(
                                            surah: juz.startSurah,
                                            arabicName: SurahNames.name(for: juz.startSurah),
                                            resumeVerse: juz.startAyah
                                        )
                                    } label: {
                                        HStack(spacing: 12) {
                                            Text("\(juz.id)")
                                                .font(.headline)
                                                .frame(width: 32, alignment: .leading)
                                                .foregroundStyle(.secondary)

                                            VStack(alignment: .leading, spacing: 3) {
                                                Text("Juz \(juz.id)")
                                                    .font(.headline)

                                                Text(juz.englishTitle)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }

                                            Spacer()

                                            Text(juz.arabicName)
                                                .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 20))
                                                .foregroundStyle(.green)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: browseMode == .surah ? "Search surah name or number..." : "Search juz number or title...")
                .safeAreaPadding(.bottom, recitationPlayer.currentSurahId != nil && recitationPlayer.currentAyahNumber != nil ? 75 : 50)

                // Now Playing Bar
                QuranNowPlayingBar()
                    .padding(.bottom, 6)
            }
            .navigationTitle("Quran")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        NavigationLink {
                            DownloadsView()
                        } label: {
                            Image(systemName: "arrow.down.circle")
                        }

                        NavigationLink {
                            BookmarksView()
                        } label: {
                            Image(systemName: "bookmark")
                        }
                    }
                }
            }
            .onAppear {
                recent = RecentlyReadManager.shared.load()
            }
        }
    }
}
