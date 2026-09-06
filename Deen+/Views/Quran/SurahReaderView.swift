//
//  SurahReaderView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SurahReaderView: View {
    
    let surah: Int
    let surahName: String?
    let arabicName: String?
    let highlightVerse: Int?
    let resumeVerse: Int?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var quranManager = QuranManager()
    @ObservedObject private var recitationPlayer = RecitationPlayer.shared
    @ObservedObject private var translationNarrator = TranslationNarrator.shared
    
    @State private var showJumpToAyah = false
    @State private var showDisplaySettings = false
    @State private var targetAyahInput = ""
    
    @AppStorage("quranArabicFontSize") private var arabicFontSize: Double = 26
    @AppStorage("quranTranslationFontSize") private var translationFontSize: Double = 16
    @AppStorage("quranShowTranslation") private var showTranslation: Bool = true
    @AppStorage("quranReadingTheme") private var readingTheme: String = "standard"
    @AppStorage("quranKeepScreenAwake") private var keepScreenAwake: Bool = true
    
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

    private var readerBackgroundColor: Color {
        switch readingTheme {
        case "sepia":
            return colorScheme == .dark
                ? Color(red: 0.16, green: 0.14, blue: 0.11)
                : Color(red: 0.98, green: 0.96, blue: 0.91)
        case "black":
            return Color.black
        default:
            return Color(uiColor: .systemGroupedBackground)
        }
    }
    
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
            ZStack(alignment: .bottom) {
                readerBackgroundColor
                    .ignoresSafeArea()

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
                                            translationSize: CGFloat(translationFontSize),
                                            showTranslation: showTranslation,
                                            highlighted: highlightedAyahNumber == ayah
                                        )
                                        .id(ayah)
                                        .background(
                                            GeometryReader { geo in
                                                Color.clear
                                                    .preference(
                                                        key: AyahPositionPreferenceKey.self,
                                                        value: [
                                                            ayah: geo.frame(in: .named("scroll")).minY
                                                        ]
                                                    )
                                            }
                                        )
                                    }
                                }

                                // Surah Navigation Footer
                                if !quranManager.isLoading && !quranManager.verses.isEmpty {
                                    HStack(spacing: 12) {
                                        if surah > 1 {
                                            let prevSurah = surah - 1
                                            let prevInfo = SurahMetadata.get(prevSurah)
                                            NavigationLink {
                                                SurahReaderView(surah: prevSurah, surahName: prevInfo.englishName)
                                            } label: {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "chevron.left")
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text("Previous Surah")
                                                            .font(.caption2)
                                                            .foregroundStyle(.secondary)
                                                        Text(prevInfo.englishName)
                                                            .font(.subheadline.bold())
                                                            .foregroundStyle(.primary)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 12)
                                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        if surah < 114 {
                                            let nextSurah = surah + 1
                                            let nextInfo = SurahMetadata.get(nextSurah)
                                            NavigationLink {
                                                SurahReaderView(surah: nextSurah, surahName: nextInfo.englishName)
                                            } label: {
                                                HStack(spacing: 8) {
                                                    VStack(alignment: .trailing, spacing: 2) {
                                                        Text("Next Surah")
                                                            .font(.caption2)
                                                            .foregroundStyle(.secondary)
                                                        Text(nextInfo.englishName)
                                                            .font(.subheadline.bold())
                                                            .foregroundStyle(.green)
                                                            .lineLimit(1)
                                                    }
                                                    Image(systemName: "chevron.right")
                                                        .foregroundStyle(.green)
                                                }
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 12)
                                                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.top, 16)
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, recitationPlayer.currentSurahId == surah && recitationPlayer.currentAyahNumber != nil ? 110 : 80)
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(AyahPositionPreferenceKey.self) { positions in
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
                .onChange(of: recitationPlayer.currentAyahNumber) { newAyah in
                    guard let newAyah = newAyah,
                          recitationPlayer.isPlaying,
                          recitationPlayer.currentSurahId == surah else { return }
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(newAyah, anchor: .center)
                    }
                }

                // Floating live recitation bar showing current Ayah being read by the Sheikh
                if recitationPlayer.currentSurahId == surah, let activeAyah = recitationPlayer.currentAyahNumber {
                    HStack(spacing: 14) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo(activeAyah, anchor: .center)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "waveform")
                                    .symbolEffect(.variableColor.iterative, options: .repeating)
                                    .foregroundStyle(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    let totalCount = quranManager.verses.count > 0 ? quranManager.verses.count : SurahMetadata.get(surah).totalAyahs
                                    Text("Ayah \(activeAyah) of \(totalCount)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.primary)
                                    Text(recitationPlayer.activeReciter.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Current Ayah \(activeAyah), tap to center")

                        Spacer()

                        HStack(spacing: 12) {
                            Button {
                                recitationPlayer.previousAyah()
                            } label: {
                                Image(systemName: "backward.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(activeAyah > 1 ? Color.primary : Color.secondary.opacity(0.3))
                            }
                            .disabled(activeAyah <= 1)
                            .accessibilityLabel("Previous ayah")

                            Button {
                                if recitationPlayer.isPlaying {
                                    recitationPlayer.pause()
                                } else {
                                    recitationPlayer.resume()
                                }
                            } label: {
                                Image(systemName: recitationPlayer.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.green, in: Circle())
                            }
                            .accessibilityLabel(recitationPlayer.isPlaying ? "Pause recitation" : "Resume recitation")

                            Button {
                                recitationPlayer.nextAyah()
                            } label: {
                                Image(systemName: "forward.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.primary)
                            }
                            .accessibilityLabel("Next ayah")

                            Button {
                                recitationPlayer.stop()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            .accessibilityLabel("Stop recitation")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: recitationPlayer.currentAyahNumber)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(surahName ?? SurahMetadata.get(surah).englishName)
                            .font(.headline)

                        let total = quranManager.verses.count > 0 ? quranManager.verses.count : SurahMetadata.get(surah).totalAyahs
                        if total > 0 {
                            let current = max(1, currentAyah)
                            let pct = Int(Double(current) / Double(total) * 100)
                            Text("Ayah \(current) of \(total) • \(pct)%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            recitationPlayer.togglePlay(for: surah, startAyah: 1, totalAyahs: quranManager.verses.count > 0 ? quranManager.verses.count : nil)
                        } label: {
                            Label(
                                recitationPlayer.isPlayingSurah(surahId: surah) ? "Pause Recitation" : "Play Full Surah (from Beginning)",
                                systemImage: recitationPlayer.isPlayingSurah(surahId: surah) ? "pause.fill" : "play.fill"
                            )
                        }

                        if currentAyah > 1 {
                            Button {
                                recitationPlayer.playSurah(surahId: surah, startAyah: currentAyah, totalAyahs: quranManager.verses.count > 0 ? quranManager.verses.count : nil)
                            } label: {
                                Label("Play from Ayah \(currentAyah)", systemImage: "arrow.right.to.line")
                            }
                        }

                        Section("Sheikh / Reciter") {
                            ForEach(Reciter.allCases) { reciter in
                                Button {
                                    recitationPlayer.setReciter(reciter)
                                    if !recitationPlayer.isPlaying {
                                        recitationPlayer.playSurah(surahId: surah, startAyah: currentAyah > 1 ? currentAyah : 1, totalAyahs: quranManager.verses.count > 0 ? quranManager.verses.count : nil, reciter: reciter)
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
                        recitationPlayer.togglePlay(for: surah, startAyah: currentAyah > 1 ? currentAyah : 1, totalAyahs: quranManager.verses.count > 0 ? quranManager.verses.count : nil)
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
                if keepScreenAwake {
                    #if canImport(UIKit)
                    UIApplication.shared.isIdleTimerDisabled = true
                    #endif
                }
                
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
                translationNarrator.stop()
                #if canImport(UIKit)
                UIApplication.shared.isIdleTimerDisabled = false
                #endif
            }
            .sheet(isPresented: $showDisplaySettings) {
                NavigationStack {
                    Form {
                        Section("Audio Narrators") {
                            HStack {
                                Text("Arabic Sheikh")
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

                            HStack {
                                Text("English Voice")
                                Spacer()
                                Picker("Translation Voice", selection: $translationNarrator.activeVoice) {
                                    ForEach(TranslationVoice.allCases) { voice in
                                        Text(voice.shortName).tag(voice)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.blue)

                                Button {
                                    translationNarrator.preview(voice: translationNarrator.activeVoice)
                                } label: {
                                    Image(systemName: translationNarrator.isPreviewing ? "speaker.wave.3.fill" : "play.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Preview translation voice")
                            }
                        }

                        Section("Reading Theme") {
                            Picker("Theme", selection: $readingTheme) {
                                Text("Standard").tag("standard")
                                Text("Warm Sepia").tag("sepia")
                                Text("AMOLED Night").tag("black")
                            }
                            .pickerStyle(.segmented)
                        }

                        Section("Font Sizing") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Arabic Font Size")
                                    Spacer()
                                    Text("\(Int(arabicFontSize)) pt")
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $arabicFontSize, in: 18...38, step: 2)
                            }
                            .padding(.vertical, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Translation Font Size")
                                    Spacer()
                                    Text("\(Int(translationFontSize)) pt")
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $translationFontSize, in: 13...24, step: 1)
                            }
                            .padding(.vertical, 4)
                        }

                        Section("Preferences") {
                            Toggle("Show English Translation", isOn: $showTranslation)
                            Toggle("Keep Screen Awake", isOn: $keepScreenAwake)
                                .onChange(of: keepScreenAwake) { enabled in
                                    #if canImport(UIKit)
                                    UIApplication.shared.isIdleTimerDisabled = enabled
                                    #endif
                                }
                        }
                    }
                    .navigationTitle("Reader Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showDisplaySettings = false
                            }
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        }
                    }
                }
                .presentationDetents([.fraction(0.65), .large])
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
        if parts.count == 2, let ayah = Int(parts[1]) {
            return ayah
        }
        return 0
    }
    
    private func saveAyah(_ ayah: Int) {
        RecentlyReadManager.shared.save(
            surah: surah,
            surahName: surahName ?? SurahMetadata.get(surah).englishName,
            verse: ayah
        )
    }
}
