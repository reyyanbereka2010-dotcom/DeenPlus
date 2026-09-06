//
//  SurahReaderView.swift
//  Deen+
//

import SwiftUI

struct SurahReaderView: View {
    
    let surah: Int
    let surahName: String?
    let arabicName: String?
    let highlightVerse: Int?
    let resumeVerse: Int?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var quranManager = QuranManager()
    @ObservedObject private var recitationPlayer = RecitationPlayer.shared
    
    @State private var showJumpToAyah = false
    @State private var showDisplaySettings = false
    @State private var targetAyahInput = ""
    
    @AppStorage("quranArabicFontSize") private var arabicFontSize: Double = 26
    @AppStorage("quranShowTranslation") private var showTranslation: Bool = true
    
    /// Currently highlighted Ayah number to visually distinguish it (e.g. after jump or resume)
    @State private var highlightedAyahNumber: Int?
    
    /// Tracks if the current Surah is downloaded locally
    @State private var isDownloaded = false
    
    /// The Ayah currently considered "active" in view (used to save reading position)
    @State private var currentAyah = 0
    
    /// The Ayah currently visible on screen (used to update currentAyah)
    @State private var visibleAyah = 0
    
    /// Flag to indicate the initial scroll to resume position has completed
    @State private var hasFinishedInitialScroll = false
    
    init(
        surah: Int,
        surahName: String? = nil,
        arabicName: String? = nil,
        highlightVerse: Int? = nil,
        resumeVerse: Int? = nil,
        initialVerse: Int? = nil
    ) {
        self.surah = surah
        self.surahName = surahName
        self.arabicName = arabicName
        self.highlightVerse = highlightVerse
        self.resumeVerse = resumeVerse ?? initialVerse
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // Header scrolls inline with the verses so it doesn't block the screen
                    SurahHeader(
                        surah: surah,
                        arabicName: arabicName ?? SurahNames.name(for: surah)
                    )
                    .padding(.top, 8)
                    
                    Group {
                        if quranManager.isLoading {
                            ProgressView("Loading Ayahs...")
                                .padding(.top, 50)
                                .accessibilityLabel("Loading ayahs")
                        } else if quranManager.offlineError {
                            VStack(spacing: 15) {
                                Image(systemName: "wifi.slash")
                                    .font(.largeTitle)
                                
                                Text("Surah Not Available Offline")
                                    .font(.headline)
                                
                                Text("Download this surah first or connect to the internet.")
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 60)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(quranManager.verses) { verse in
                                    let ayah = parseAyahNumber(from: verse.verseKey)
                                    
                                    VerseRow(
                                        verse: verse,
                                        arabicSize: CGFloat(arabicFontSize),
                                        showTranslation: showTranslation,
                                        highlighted: highlightedAyahNumber == ayah
                                    )
                                    .id(ayah)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear
                                                .preference(
                                                    key: AyahPositionKey.self,
                                                    value: [
                                                        ayah: geo.frame(in: .named("scroll")).minY
                                                    ]
                                                )
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 80)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(AyahPositionKey.self) { positions in
                guard hasFinishedInitialScroll, !positions.isEmpty else {
                    return
                }
                
                let closest = positions.min {
                    abs($0.value) < abs($1.value)
                }
                
                if let ayah = closest?.key, ayah != currentAyah {
                    currentAyah = ayah
                    saveAyah(ayah)
                }
            }
            .navigationTitle(surahName ?? SurahMetadata.get(surah).englishName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            recitationPlayer.togglePlay(for: surah)
                        } label: {
                            Label(recitationPlayer.isPlayingSurah(surahId: surah) ? "Pause Recitation" : "Play Full Surah", systemImage: recitationPlayer.isPlayingSurah(surahId: surah) ? "pause.fill" : "play.fill")
                        }

                        Section("Sheikh / Reciter") {
                            ForEach(Reciter.allCases) { reciter in
                                Button {
                                    recitationPlayer.setReciter(reciter)
                                    if !recitationPlayer.isPlaying {
                                        recitationPlayer.playSurah(surahId: surah, reciter: reciter)
                                    }
                                } label: {
                                    HStack {
                                        Text(reciter.displayName)
                                        if recitationPlayer.activeReciter == reciter {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: recitationPlayer.isPlayingSurah(surahId: surah) ? "pause.circle.fill" : "play.circle")
                            .foregroundStyle(recitationPlayer.isPlayingSurah(surahId: surah) ? .green : .primary)
                    } primaryAction: {
                        recitationPlayer.togglePlay(for: surah)
                    }
                    .accessibilityLabel(recitationPlayer.isPlayingSurah(surahId: surah) ? "Pause recitation" : "Play recitation (\(recitationPlayer.activeReciter.shortName))")

                    Button {
                        showDisplaySettings = true
                    } label: {
                        Image(systemName: "textformat.size")
                    }
                    .accessibilityLabel("Adjust display settings")

                    Button {
                        if isDownloaded {
                            QuranFileManager.shared.deleteSurah(id: surah)
                            isDownloaded = false
                        } else {
                            Task {
                                let result = await quranManager.downloadSurah(surah)
                                await MainActor.run { isDownloaded = result }
                            }
                        }
                    } label: {
                        Image(
                            systemName: isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle"
                        )
                    }
                    .accessibilityLabel(isDownloaded ? "Surah downloaded" : "Download surah for offline use")
                    
                    Button {
                        showJumpToAyah = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("Jump to ayah")
                }
            }
            .onAppear {
                isDownloaded = QuranFileManager.shared.isDownloaded(id: surah)
                
                Task {
                    let name = surahName ?? SurahMetadata.get(surah).englishName
                    
                    await MainActor.run {
                        quranManager.isLoading = true
                    }
                    
                    await quranManager.fetchVerses(for: surah, surahName: name)
                    
                    await MainActor.run {
                        let targetVerse = resumeVerse ?? highlightVerse
                        if let targetVerse = targetVerse {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    proxy.scrollTo(targetVerse, anchor: .center)
                                    highlightedAyahNumber = targetVerse
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    hasFinishedInitialScroll = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        highlightedAyahNumber = nil
                                    }
                                }
                            }
                        } else {
                            highlightedAyahNumber = nil
                            hasFinishedInitialScroll = true
                        }
                    }
                }
            }
            .onDisappear {
                recitationPlayer.pause()
            }
            .sheet(isPresented: $showDisplaySettings) {
                VStack(spacing: 20) {
                    Text("Reader & Audio Settings")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Reciter / Sheikh")
                                .font(.subheadline)
                            Spacer()
                            Picker("Sheikh", selection: Binding(
                                get: { recitationPlayer.activeReciter },
                                set: { recitationPlayer.setReciter($0) }
                            )) {
                                ForEach(Reciter.allCases) { reciter in
                                    Text(reciter.displayName).tag(reciter)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.green)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Arabic Font Size")
                            Spacer()
                            Text("\(Int(arabicFontSize)) pt")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 16) {
                            Text("A")
                                .font(.footnote)
                            Slider(value: $arabicFontSize, in: 18...38, step: 2)
                            Text("A")
                                .font(.title3).bold()
                        }
                    }
                    
                    Toggle("Show English Translation", isOn: $showTranslation)
                        .toggleStyle(.switch)
                    
                    Button("Done") {
                        showDisplaySettings = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding()
                .presentationDetents([.fraction(0.45)])
            }
            .sheet(isPresented: $showJumpToAyah) {
                VStack(spacing: 20) {
                    Text("Jump to Ayah")
                        .font(.headline)
                    
                    TextField("Ayah Number (1-\(quranManager.verses.count))", text: $targetAyahInput)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            targetAyahInput = ""
                            showJumpToAyah = false
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Go") {
                            if let target = Int(targetAyahInput), target >= 1, target <= quranManager.verses.count {
                                showJumpToAyah = false
                                targetAyahInput = ""
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        proxy.scrollTo(target, anchor: .center)
                                        highlightedAyahNumber = target
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            highlightedAyahNumber = nil
                                        }
                                    }
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding()
                .presentationDetents([.fraction(0.3)])
            }
        }
    }
    
    private func parseAyahNumber(from verseKey: String) -> Int {
        let parts = verseKey.split(separator: ":")
        if parts.count == 2, let num = Int(parts[1]) {
            return num
        }
        return 0
    }
    
    private func saveAyah(_ ayah: Int) {
        guard ayah > 0 else { return }
        RecentlyReadManager.shared.save(
            surah: surah,
            surahName: surahName ?? SurahMetadata.get(surah).englishName,
            verse: ayah
        )
    }

    struct AyahPositionKey: PreferenceKey {
        static var defaultValue: [Int: CGFloat] = [:]
        static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
            value.merge(nextValue()) { _, new in new }
        }
    }
}
