import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

private enum RevelationFilter: String, CaseIterable, Identifiable {
    case all, meccan, medinan
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: return "All"
        case .meccan: return "Meccan"
        case .medinan: return "Medinan"
        }
    }
}

struct QuranReaderView: View {
    @State private var searchText: String = ""
    @AppStorage("revelationFilter") private var filterRaw: String = RevelationFilter.all.rawValue
    @State private var scrollPosition: Int? = nil

    private var activeFilter: RevelationFilter {
        get { RevelationFilter(rawValue: filterRaw) ?? .all }
        nonmutating set { filterRaw = newValue.rawValue }
    }

    private var filterBinding: Binding<RevelationFilter> {
        Binding(get: { activeFilter }, set: { activeFilter = $0 })
    }

    @StateObject private var progressStore = ReadingProgressStore()
    @StateObject private var player = RecitationPlayer()

    @AppStorage("sortByLengthAscending") private var sortByLengthAscending: Bool = false
    @AppStorage("showRecentFirst") private var showRecentFirst: Bool = true

    private var filtered: [SurahMeta] {
        let base: [SurahMeta]
        switch activeFilter {
        case .all: base = QuranData.allSurahs
        case .meccan: base = QuranData.meccanSurahs()
        case .medinan: base = QuranData.medinanSurahs()
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let list: [SurahMeta]
        if q.isEmpty {
            list = base
        } else {
            let searched = QuranData.search(q)
            let ids = Set(base.map { $0.id })
            list = searched.filter { ids.contains($0.id) }
        }
        let sorted = sortByLengthAscending ? list.sorted { $0.ayahCount < $1.ayahCount } : list
        if showRecentFirst, let recentId = progressStore.progress?.surahId {
            var arr = sorted
            if let idx = arr.firstIndex(where: { $0.id == recentId }) {
                let item = arr.remove(at: idx)
                arr.insert(item, at: 0)
            }
            return arr
        } else {
            return sorted
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let p = progressStore.progress, let surah = QuranData.surah(by: p.surahId) {
                    Section("Continue") {
                        NavigationLink(value: p.surahId) {
                            HStack(spacing: 12) {
                                Image(systemName: "book.fill")
                                    .font(.title2)
                                    .foregroundStyle(.tint)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Continue Reading")
                                        .font(.headline)
                                    Text("\(surah.englishName) — Ayah \(p.ayah)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(.quaternary.opacity(0.2), in: .rect(cornerRadius: 12))
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }

                Section("Surahs") {
                    ForEach(filtered) { surah in
                        NavigationLink(value: surah.id) {
                            SurahRowView(surah: surah)
                                .environmentObject(player)
                        }
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    }
                }
            }
            .applyScrollPositionIfAvailable($scrollPosition)
            .onAppear {
                if let p = progressStore.progress, p.surahId == nil {
                    scrollPosition = nil
                }
            }
            .navigationTitle("Quran")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Filter", selection: filterBinding) {
                        ForEach(RevelationFilter.allCases) { f in
                            Text(f.title).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 320)
                    .accessibilityLabel("Revelation filter")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        sortByLengthAscending.toggle()
                    } label: {
                        Image(systemName: sortByLengthAscending ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle")
                    }
                    .accessibilityLabel("Toggle sort by length")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showRecentFirst.toggle()
                    } label: {
                        Image(systemName: showRecentFirst ? "clock.fill" : "clock")
                    }
                    .accessibilityLabel("Toggle show recent first")
                }
            }
            .animation(.default, value: activeFilter)
            .animation(.default, value: sortByLengthAscending)
            .animation(.default, value: showRecentFirst)
            .navigationDestination(for: Int.self) { surahId in
                QuranSurahDetailView(surahId: surahId)
                    .environmentObject(progressStore)
                    .environmentObject(player)
            }
        }
    }
}

private struct SurahRowView: View {
    @EnvironmentObject private var player: RecitationPlayer

    let surah: SurahMeta

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: surah.systemImage)
                .foregroundStyle(surah.revelationPlace == .meccan ? .blue : .green)
            VStack(alignment: .leading, spacing: 4) {
                Text(surah.displayTitle)
                    .font(.headline)
                Text(surah.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(surah.arabicName)
                .font(.title3)
            Button {
                player.togglePlay(for: surah.id)
            } label: {
                Image(systemName: player.isPlaying && player.currentSurahId == surah.id ? "pause.fill" : "play.fill")
                    .padding(8)
                    .background(.thinMaterial, in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(player.isPlaying && player.currentSurahId == surah.id ? "Pause recitation" : "Play recitation")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(surah.displayTitle), \(surah.subtitle)")
    }
}

private struct AyahItem: Identifiable {
    let index: Int
    let text: String
    var id: Int { index }
}

private struct AyahNumberBadge: View {
    let number: Int
    var body: some View {
        Text("\(number)")
            .font(.caption2)
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green, in: Capsule())
            .fixedSize(horizontal: true, vertical: true)
            .accessibilityLabel("Ayah number \(number)")
    }
}

struct QuranSurahDetailView: View {
    @EnvironmentObject private var progressStore: ReadingProgressStore
    @EnvironmentObject private var player: RecitationPlayer

    let surahId: Int

    @State private var showingTafsirAyah: Int? = nil
    @State private var isShowingTafsir: Bool = false

    @AppStorage("readerShowTranslation") private var showTranslation: Bool = false
    @AppStorage("readerFontSize") private var fontSize: Double = 18
    @AppStorage("readerLineSpacing") private var lineSpacing: Double = 4
    @State private var scrollPosition: Int? = nil

    @State private var jumpToAyahText: String = ""
    @State private var isJumpSheetPresented: Bool = false

    private var surah: SurahMeta? { QuranData.surah(by: surahId) }
    private var ayahs: [String] { QuranData.placeholderAyahs(for: surahId) }

    var body: some View {
        Group {
            if let surah {
                List {
                    Section {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(surah.displayTitle)
                                    .font(.title2).bold()
                                Text(surah.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(surah.arabicName)
                                .font(.largeTitle)
                        }
                        HStack(spacing: 12) {
                            Button {
                                player.togglePlay(for: surah.id)
                            } label: {
                                Label(player.isPlaying && player.currentSurahId == surah.id ? "Pause" : "Play", systemImage: player.isPlaying && player.currentSurahId == surah.id ? "pause.fill" : "play.fill")
                                    .labelStyle(.titleAndIcon)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.thinMaterial, in: .capsule)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Play surah recitation")

                            Button {
                                progressStore.update(surahId: surah.id, ayah: 1)
                            } label: {
                                Label("Bookmark", systemImage: "bookmark")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.thinMaterial, in: .capsule)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Bookmark surah")
                        }
                        HStack(spacing: 12) {
                            Toggle(isOn: $showTranslation) {
                                Text("Translation")
                            }
                            .toggleStyle(.switch)

                            Spacer()

                            Button {
                                isShowingTafsir = false
                                jumpToAyahText = ""
                                showingTafsirAyah = nil
                                isJumpSheetPresented = true
                            } label: {
                                Label("Jump", systemImage: "arrow.down.to.line")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.thinMaterial, in: .capsule)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Section("Ayahs") {
                        let items: [AyahItem] = ayahs.enumerated().map { AyahItem(index: $0.offset, text: $0.element) }
                        ForEach(items) { item in
                            let ayahNumber = item.index + 1
                            let isBookmarked = (progressStore.progress?.surahId == surah.id && progressStore.progress?.ayah == ayahNumber)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.text)
                                    .font(.system(size: CGFloat(fontSize)))
                                    .lineSpacing(CGFloat(lineSpacing))
                                    .multilineTextAlignment(.leading)
                                if showTranslation {
                                    Text("[Placeholder translation for ayah \(ayahNumber)]")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                                HStack(spacing: 8) {
                                    AyahNumberBadge(number: ayahNumber)
                                    Button {
                                        showingTafsirAyah = item.index; isShowingTafsir = true
                                    } label: {
                                        Image(systemName: "doc.plaintext")
                                            .padding(6)
                                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Show translation for ayah \(ayahNumber)")

                                    Button {
                                        progressStore.update(surahId: surah.id, ayah: ayahNumber)
                                        #if canImport(UIKit)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        #endif
                                    } label: {
                                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                            .padding(6)
                                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(isBookmarked ? "Remove bookmark from ayah \(ayahNumber)" : "Bookmark ayah \(ayahNumber)")

                                    Button {
                                        player.playAyah(surahId: surah.id, ayah: ayahNumber)
                                    } label: {
                                        Image(systemName: "play.circle")
                                            .padding(6)
                                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Play recitation for ayah \(ayahNumber)")

                                    Spacer()

                                    Button {
                                        #if canImport(UIKit)
                                        UIPasteboard.general.string = item.text
                                        #elseif canImport(AppKit)
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(item.text, forType: .string)
                                        #endif
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Copy ayah")

                                    ShareLink(item: item.text) {
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                    .accessibilityLabel("Share ayah")
                                }
                            }
                            .id(ayahNumber)
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button("Copy") {
                                    #if canImport(UIKit)
                                    UIPasteboard.general.string = item.text
                                    #elseif canImport(AppKit)
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(item.text, forType: .string)
                                    #endif
                                }
                                ShareLink(item: item.text) { Label("Share", systemImage: "square.and.arrow.up") }
                                Button(isBookmarked ? "Remove Bookmark" : "Bookmark") { progressStore.update(surahId: surah.id, ayah: ayahNumber) }
                                Button("Play From Here") { player.playAyah(surahId: surah.id, ayah: ayahNumber) }
                            }
                            .background(isBookmarked ? .yellow.opacity(0.15) : .clear, in: RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                progressStore.update(surahId: surah.id, ayah: ayahNumber)
                            }
                        }
                    }
                }
                .applyScrollPositionIfAvailable($scrollPosition)
                .onAppear {
                    if let p = progressStore.progress, p.surahId == surah.id {
                        scrollPosition = p.ayah
                    }
                }
                .navigationTitle(surah.englishName)
                .toolbarTitleDisplayMode(.inline)
                .sheet(isPresented: $isShowingTafsir, onDismiss: { showingTafsirAyah = nil }) {
                    VStack(spacing: 20) {
                        Text("Translation / Tafsir")
                            .font(.title2)
                            .bold()
                        Divider()
                        ScrollView {
                            if let idx = showingTafsirAyah {
                                Text("This is a placeholder translation/tafsir for ayah \(idx + 1) of Surah \(surah.displayTitle).")
                                    .padding()
                            }
                        }
                        Button("Dismiss") {
                            isShowingTafsir = false
                        }
                        .padding()
                    }
                    .padding()
                }
                .sheet(isPresented: $isJumpSheetPresented) {
                    VStack(spacing: 16) {
                        Text("Jump to Ayah").font(.headline)
                        TextField("Ayah number", text: $jumpToAyahText)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        HStack {
                            Button("Cancel") { isJumpSheetPresented = false }
                            Spacer()
                            Button("Go") {
                                if let n = Int(jumpToAyahText), n >= 1, n <= ayahs.count {
                                    progressStore.update(surahId: surah.id, ayah: n)
                                    scrollPosition = n
                                }
                                isJumpSheetPresented = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 8) {
                            Image(systemName: "textformat.size")
                            Slider(value: $fontSize, in: 14...28, step: 1)
                                .frame(width: 140)
                        }
                        .accessibilityLabel("Adjust font size")
                    }
                }
            } else {
                if #available(iOS 17.0, macOS 14.0, *) {
                    ContentUnavailableView("Surah not found", systemImage: "exclamationmark.triangle")
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle").font(.largeTitle)
                        Text("Surah not found")
                    }.padding()
                }
            }
        }
    }
}

extension RecitationPlayer {
    func playAyah(surahId: Int, ayah: Int) {
        print("Play ayah \(ayah) of surah \(surahId)")
    }
}

private extension View {
    @ViewBuilder
    func applyScrollPositionIfAvailable(_ id: Binding<Int?>) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.scrollPosition(id: id)
        } else {
            self
        }
    }
}

#Preview {
    QuranReaderView()
}
