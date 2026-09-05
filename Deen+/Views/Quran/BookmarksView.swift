//
//  BookmarksView.swift
//  Deen+
//

import SwiftUI

struct BookmarksView: View {

    @State private var bookmarks: [QuranVerse] = []

    var body: some View {
        List {
            ForEach(bookmarks) { verse in
                let surahNum = verse.surah
                let arabic = SurahNames.name(for: surahNum)
                let ayahNum = parseAyahNumber(from: verse.verseKey)

                NavigationLink {
                    SurahReaderView(
                        surah: surahNum,
                        arabicName: arabic,
                        highlightVerse: ayahNum,
                        resumeVerse: ayahNum
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(
                                verse.surahName ?? "Surah \(surahNum)"
                            )
                            .font(.headline)

                            Spacer()

                            Text(verse.verseKey)
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }

                        Text(verse.translation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: deleteBookmark)
        }
        .navigationTitle("Bookmarks")
        .safeAreaPadding(.bottom, 60)
        .onAppear {
            loadBookmarks()
        }
    }

    private func loadBookmarks() {
        bookmarks = QuranStorageManager.shared.loadBookmarks()
    }

    private func deleteBookmark(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        QuranStorageManager.shared.saveBookmarks(bookmarks)
    }

    private func parseAyahNumber(from verseKey: String) -> Int {
        let parts = verseKey.split(separator: ":")
        if parts.count == 2 {
            return Int(parts[1]) ?? 1
        }
        return 1
    }
}
