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
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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

    private var currentTheme: ReaderTheme {
        ReaderTheme(rawValue: readingTheme) ?? .standard
    }

    private var readerBackgroundColor: Color {
        currentTheme.backgroundColor(colorScheme: colorScheme)
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
        let target = resumeVerse ?? initialVerse ?? highlightVerse
        self.resumeVerse = target
        _currentAyah = State(initialValue: target ?? 0)
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
                                        .font(.system(size: 44))
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Surah Not Available Offline")
                                        .font(.headline)
                                    
                                    Text("Download this surah first or connect to the internet.")
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 32)

                                    Button {
                                        Task {
                                            await quranManager.fetchVerses(
                                                for: surah,
                                                surahName: surahName ?? ""
                                            )
                                        }
                                    } label: {
                                        Label("Try Again", systemImage: "arrow.clockwise")
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.green, in: Capsule())
                                            .foregroundStyle(.white)
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(.top, 60)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(quranManager.verses, id: \.ayah) { verse in
                                        let ayah = verse.ayah
                                        
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
                    .frame(maxWidth: horizontalSizeClass == .regular ? 720 : .infinity)
                    .frame(maxWidth: .infinity)
                }
                .coordinateSpace(name: "scroll")
                .onChange(of: quranManager.verses) { _, verses in
                    guard !verses.isEmpty, !hasFinishedInitialScroll else { return }
                    if let target = resumeVerse ?? highlightVerse, target > 0 {
                        scrollToTargetAyah(target, proxy: proxy)
                    }
                }
                .onPreferenceChange(AyahPositionPreferenceKey.self) { positions in
                    guard hasFinishedInitialScroll, !positions.isEmpty else {
                        return
                    }
                    
                    let closest = positions.min {
                        abs($0.value) < abs($1.value)
                    }
                    
                    if let ayah = closest?.key, ayah != currentAyah {
                        DispatchQueue.main.async {
                            guard self.hasFinishedInitialScroll else { return }
                            guard self.currentAyah != ayah else { return }
                            self.currentAyah = ayah
                            self.saveAyah(ayah)
                        }
                    }
                }
                .onChange(of: recitationPlayer.currentAyahNumber) { _, newAyah in
                    guard let newAyah = newAyah,
                          recitationPlayer.isPlaying,
                          recitationPlayer.currentSurahId == surah else { return }
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(newAyah, anchor: .center)
                    }
                }

                // Modern Floating Now Playing Bar
                QuranNowPlayingBar(onAyahTap: { activeAyah in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(activeAyah, anchor: .center)
                    }
                })
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: recitationPlayer.currentAyahNumber)
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
                        if let targetVerse = targetVerse, targetVerse > 0 {
                            scrollToTargetAyah(targetVerse, proxy: proxy)
                        } else {
                            highlightedAyahNumber = nil
                            hasFinishedInitialScroll = true
                        }
                    }
                }
            }
            .onDisappear {
                // Keep recitationPlayer active so recitation continues when moving between tabs or outside the app
                translationNarrator.stop()
                #if canImport(UIKit)
                UIApplication.shared.isIdleTimerDisabled = false
                #endif
            }
            .sheet(isPresented: $showDisplaySettings) {
                NavigationStack {
                    Form {
                        Section("Audio Narrators") {
                            NavigationLink {
                                RecitationSettingsView()
                            } label: {
                                Label("Recitation & Voices", systemImage: "waveform.badge.mic")
                                    .foregroundStyle(Color.green)
                            }
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
                                Text("Translation Voice")
                                Spacer()
                                Picker("Translation Voice", selection: $translationNarrator.activeVoice) {
                                    ForEach(TranslationVoice.allCases) { voice in
                                        Text(voice.displayName).tag(voice)
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

                        Section("Recitation Playback Options") {
                            Picker("Playback Speed", selection: Binding(
                                get: { recitationPlayer.playbackSpeed },
                                set: { recitationPlayer.setPlaybackSpeed($0) }
                            )) {
                                Text("0.75x").tag(Float(0.75))
                                Text("1.0x (Normal)").tag(Float(1.0))
                                Text("1.25x").tag(Float(1.25))
                                Text("1.5x").tag(Float(1.5))
                            }

                            Picker("Ayah Repeat", selection: Binding(
                                get: { recitationPlayer.repeatCount },
                                set: { recitationPlayer.setRepeatCount($0) }
                            )) {
                                Text("1x (Play Once)").tag(1)
                                Text("2x").tag(2)
                                Text("3x").tag(3)
                                Text("5x").tag(5)
                                Text("Loop Ayah (∞)").tag(0)
                            }

                            Picker("Sleep Timer", selection: Binding(
                                get: { recitationPlayer.sleepTimerRemainingMinutes },
                                set: { recitationPlayer.setSleepTimer(minutes: $0) }
                            )) {
                                Text("Off").tag(0)
                                Text("15 Minutes").tag(15)
                                Text("30 Minutes").tag(30)
                                Text("45 Minutes").tag(45)
                                Text("60 Minutes").tag(60)
                            }
                        }

                        Section("Reading Theme") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(ReaderTheme.allCases) { theme in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            readingTheme = theme.rawValue
                                        }
                                    } label: {
                                        VStack(spacing: 6) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(theme.cardBackgroundColor(colorScheme: colorScheme))
                                                    .frame(height: 52)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(readingTheme == theme.rawValue ? theme.accentColor(colorScheme: colorScheme) : theme.cardBorderColor(colorScheme: colorScheme), lineWidth: readingTheme == theme.rawValue ? 2.5 : 1)
                                                    )

                                                HStack(spacing: 4) {
                                                    Image(systemName: theme.icon)
                                                        .font(.caption2)
                                                        .foregroundStyle(theme.accentColor(colorScheme: colorScheme))
                                                    Text("بِسْمِ اللَّهِ")
                                                        .font(.caption2)
                                                        .foregroundStyle(theme.primaryTextColor(colorScheme: colorScheme))
                                                }

                                                if readingTheme == theme.rawValue {
                                                    VStack {
                                                        HStack {
                                                            Spacer()
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .font(.system(size: 11))
                                                                .foregroundStyle(theme.accentColor(colorScheme: colorScheme))
                                                                .padding(4)
                                                        }
                                                        Spacer()
                                                    }
                                                }
                                            }

                                            Text(theme.shortName)
                                                .font(.caption2.weight(readingTheme == theme.rawValue ? .bold : .medium))
                                                .foregroundStyle(readingTheme == theme.rawValue ? Color.primary : Color.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(theme.displayName) theme")
                                }
                            }
                            .padding(.vertical, 4)
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

                        Section("Global Themes") {
                            NavigationLink {
                                AppearanceSettingsView()
                            } label: {
                                Label("Theme & Appearance", systemImage: "paintbrush.fill")
                                    .foregroundStyle(Color.purple)
                            }
                        }

                        Section("Preferences") {
                            Toggle("Show English Translation", isOn: $showTranslation)
                            Toggle("Keep Screen Awake", isOn: $keepScreenAwake)
                                .onChange(of: keepScreenAwake) { _, enabled in
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
                let total = max(quranManager.verses.count, SurahMetadata.get(surah).totalAyahs)
                NavigationStack {
                    VStack(spacing: 20) {
                        // Quick Jump Shortcut Pills
                        VStack(alignment: .leading, spacing: 8) {
                            Text("QUICK JUMP")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                ForEach([
                                    ("Start", 1),
                                    ("1/4", max(1, total / 4)),
                                    ("Half", max(1, total / 2)),
                                    ("3/4", max(1, (3 * total) / 4)),
                                    ("End", total)
                                ], id: \.0) { label, ayahNum in
                                    Button {
                                        showJumpToAyah = false
                                        targetAyahInput = ""
                                        scrollToTargetAyah(ayahNum, proxy: proxy)
                                    } label: {
                                        VStack(spacing: 2) {
                                            Text(label)
                                                .font(.caption.weight(.semibold))
                                            Text("v. \(ayahNum)")
                                                .font(.system(size: 10, design: .rounded))
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Manual Ayah Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OR ENTER SPECIFIC AYAH (1–\(total))")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                TextField("Ayah number", text: $targetAyahInput)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)

                                Button("Go") {
                                    if let target = Int(targetAyahInput), target >= 1, target <= total {
                                        showJumpToAyah = false
                                        targetAyahInput = ""
                                        scrollToTargetAyah(target, proxy: proxy)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .disabled(Int(targetAyahInput) == nil || (Int(targetAyahInput) ?? 0) < 1 || (Int(targetAyahInput) ?? 0) > total)
                            }
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                    .padding(.top, 20)
                    .navigationTitle("Jump to Ayah")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showJumpToAyah = false
                                targetAyahInput = ""
                            }
                        }
                    }
                }
                .presentationDetents([.fraction(0.45), .medium])
                .presentationDragIndicator(.visible)
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
    

    private func scrollToTargetAyah(_ target: Int, proxy: ScrollViewProxy, animated: Bool = true) {
        hasFinishedInitialScroll = false
        currentAyah = target
        highlightedAyahNumber = target

        // Short delay to ensure LazyVStack has mounted newly loaded verses
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // Pass 1: Immediate jump to force LazyVStack to instantiate intermediate rows
            proxy.scrollTo(target, anchor: .top)

            // Staged iterative adjustments as SwiftUI calculates real verse heights
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                proxy.scrollTo(target, anchor: .top)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    proxy.scrollTo(target, anchor: .top)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        if animated {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                proxy.scrollTo(target, anchor: .top)
                            }
                        } else {
                            proxy.scrollTo(target, anchor: .top)
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            proxy.scrollTo(target, anchor: .top)
                            hasFinishedInitialScroll = true
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                if highlightedAyahNumber == target {
                                    highlightedAyahNumber = nil
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func saveAyah(_ ayah: Int) {
        RecentlyReadManager.shared.save(
            surah: surah,
            surahName: surahName ?? SurahMetadata.get(surah).englishName,
            verse: ayah
        )
    }
}
