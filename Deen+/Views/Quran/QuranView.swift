//
//  QuranView.swift
//  Deen+
//

import SwiftUI

enum QuranRevelationFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case meccan = "Meccan"
    case medinan = "Medinan"
    
    var id: String { rawValue }
}

struct QuranView: View {

    @State private var recent: RecentlyRead?
    @State private var searchText = ""
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
                   metadata.englishTranslation.lowercased().contains(q) ||
                   arabic.contains(q) ||
                   "\(number)".contains(q)
        }
    }

    var body: some View {
        NavigationStack {
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

                Section {
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(QuranRevelationFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
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
                                            .font(.caption)
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
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search surah name or number...")
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
