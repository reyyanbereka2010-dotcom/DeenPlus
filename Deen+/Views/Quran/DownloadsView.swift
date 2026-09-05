//
//  DownloadsView.swift
//  Deen+
//

import SwiftUI

struct DownloadsView: View {

    @State private var downloadedSurahs: [DownloadedQuran] = []

    @State private var showDeleteAll = false



    var body: some View {

        List {

            Section {

                ForEach(downloadedSurahs) { item in

                    let surahNumber = item.id
                    let arabic = SurahNames.name(for: surahNumber)
                    let metadata = SurahMetadata.get(surahNumber)


                    NavigationLink {
                        SurahReaderView(
                            surah: surahNumber,
                            arabicName: arabic
                        )
                    } label: {

                        HStack {

                            Text("\(surahNumber)")
                                .font(.headline)
                                .frame(
                                    width: 30,
                                    alignment: .leading
                                )
                                .foregroundColor(.secondary)



                            VStack(
                                alignment: .leading,
                                spacing: 2
                            ) {

                                Text(metadata.englishName)
                                    .font(.headline)


                                Text(arabic)
                                    .font(
                                        .custom(
                                            "KFGQPC Uthmanic Script HAFS Regular",
                                            size: 18
                                        )
                                    )
                                    .foregroundColor(.green)

                            }


                            Spacer()



                            VStack(
                                alignment: .trailing,
                                spacing: 2
                            ) {

                                Text(metadata.revelationPlace)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)


                                Text(
                                    "\(metadata.totalAyahs) Ayahs"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)

                            }

                        }

                        .padding(.vertical, 4)

                    }

                    .swipeActions {

                        Button(role: .destructive) {

                            deleteSurah(
                                id: surahNumber
                            )

                        } label: {

                            Label(
                                "Delete",
                                systemImage: "trash"
                            )

                        }

                    }

                }

                .onDelete(
                    perform: deleteAtOffsets
                )


            } header: {

                if !downloadedSurahs.isEmpty {

                    HStack {

                        Text(
                            "\(downloadedSurahs.count) downloaded"
                        )

                        Spacer()

                        Button("Delete All") {

                            showDeleteAll = true

                        }

                    }

                }

            }

        }

        .navigationTitle(
            "Quran Downloads"
        )
        .safeAreaPadding(.bottom, 60)

        .overlay {

            if downloadedSurahs.isEmpty {

                VStack(spacing: 12) {

                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)


                    Text(
                        "No downloaded Surahs yet."
                    )
                    .foregroundColor(.secondary)

                }

            }

        }

        .confirmationDialog(
            "Delete all downloaded Surahs?",
            isPresented: $showDeleteAll,
            titleVisibility: .visible
        ) {

            Button(
                "Delete All",
                role: .destructive
            ) {

                QuranFileManager.shared.deleteAll {
                    refreshDownloads()
                }

            }


            Button(
                "Cancel",
                role: .cancel
            ) {}

        }

        .onAppear {

            refreshDownloads()

        }

    }



    private func refreshDownloads() {

        downloadedSurahs =
        QuranFileManager.shared.getDownloadedSurahs()

    }



    private func deleteAtOffsets(
        at offsets: IndexSet
    ) {

        for index in offsets {

            let surah =
            downloadedSurahs[index]


            QuranFileManager.shared.deleteSurah(
                id: surah.id
            )

        }


        downloadedSurahs.remove(
            atOffsets: offsets
        )

    }



    private func deleteSurah(
        id: Int
    ) {

        withAnimation {

            QuranFileManager.shared.deleteSurah(
                id: id
            )


            downloadedSurahs.removeAll {
                $0.id == id
            }

        }

    }

}
