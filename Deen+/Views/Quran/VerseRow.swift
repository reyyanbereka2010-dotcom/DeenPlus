//
//  VerseRow.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(UIKit)
import UIKit
#endif


struct VerseRow: View {

    let verse: QuranVerse
    let arabicSize: CGFloat
    let showTranslation: Bool
    let highlighted: Bool

    private var accessibilityVerseLabel: String {
        let surahNameText = verse.surahName ?? "Surah \(verse.surah)"
        return "\(surahNameText), Ayah \(verse.verseKey.split(separator: ":").last ?? "")"
    }
    private var ayahNumber: String {
        String(verse.verseKey.split(separator: ":").last ?? "")
    }


    @State private var isBookmarked = false

    #if canImport(AVFoundation)
    @State private var speechSynth = AVSpeechSynthesizer()
    @State private var isSpeakingTranslation = false
    @State private var isSpeakingArabic = false
    #endif

    #if canImport(UIKit)
    @State private var showShareSheet = false
    #endif

    private var shareText: String {
        var parts: [String] = []
        parts.append(verse.verseKey)
        parts.append(verse.arabic)
        if showTranslation {
            parts.append(verse.translation)
        }
        return parts.joined(separator: "\n\n")
    }


    var body: some View {
        VStack(spacing: 18) {
            // Top Row Header with Ayah Number Badge aligned on the RIGHT
            HStack {
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Ayah")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(ayahNumber)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.14))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            Text(verse.arabic)
                .font(
                    .custom(
                        "KFGQPC Uthmanic Script HAFS Regular",
                        size: arabicSize
                    )
                )
                .multilineTextAlignment(.trailing)
                .lineSpacing(18)
                .environment(
                    \.layoutDirection,
                    .rightToLeft
                )
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .minimumScaleFactor(0.5)
                .textSelection(.enabled)
                .accessibilityLabel(accessibilityVerseLabel)
                .accessibilityHint("Double tap to toggle bookmark or play audio")

            HStack(spacing: 6) {
                Capsule()
                    .fill(Color.green.opacity(0.4))
                    .frame(width: 24, height: 2)
                Circle()
                    .fill(Color.green.opacity(0.4))
                    .frame(width: 4, height: 4)
                Capsule()
                    .fill(Color.green.opacity(0.4))
                    .frame(width: 24, height: 2)
            }
            .padding(.top, 2)
            .accessibilityHidden(true)

            if showTranslation {
                Text(verse.translation)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .textSelection(.enabled)
                    .accessibilityLabel("Translation: \(verse.translation)")
            }

            HStack(spacing: 28) {
                Button {
                    playRecitation()
                } label: {
                    Image(
                        systemName: "play.circle.fill"
                    )
                    .font(.title2)
                    .accessibilityLabel("Play recitation")
                    .accessibilityHint("Plays audio for this ayah")
                }

                Button {
                    toggleBookmark()
                } label: {
                    Image(
                        systemName:
                            isBookmarked
                            ? "bookmark.fill"
                            : "bookmark"
                    )
                    .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
                    .accessibilityValue(isBookmarked ? "Bookmarked" : "Not bookmarked")
                    .accessibilityHint("Toggles bookmark for this ayah")
                }

                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(
                cornerRadius: 22
            )
            .fill(
                highlighted
                ? Color.green.opacity(0.18)
                : Color(.secondarySystemBackground)
            )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .accessibilityAddTraits(highlighted ? .isSelected : [])
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                copyArabic()
            } label: {
                Label("Copy Arabic", systemImage: "doc.on.doc")
            }
            if showTranslation {
                Button {
                    copyTranslation()
                } label: {
                    Label("Copy translation", systemImage: "doc.on.doc")
                }
            }
            Button {
                shareVerse()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Divider()
            Button {
                playRecitation()
            } label: {
                Label("Play recitation", systemImage: "play.circle.fill")
            }
            #if canImport(AVFoundation)
            Button {
                speakTranslation()
            } label: {
                Label(isSpeakingTranslation ? "Stop speaking" : "Speak translation", systemImage: "speaker.wave.2.fill")
            }
            #endif
            Divider()
            Button {
                toggleBookmark()
            } label: {
                Label(isBookmarked ? "Remove bookmark" : "Add bookmark", systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                playRecitation()
            } label: {
                Label("Play", systemImage: "play.fill")
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                toggleBookmark()
            } label: {
                Label(isBookmarked ? "Unbookmark" : "Bookmark", systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
            }
            .tint(.orange)
        }
        .animation(
            .easeInOut,
            value: highlighted
        )
        .onAppear {
            checkBookmark()
        }
        .onChange(of: verse.id) { _ in
            checkBookmark()
        }
        .accessibilityActions {
            Button(isBookmarked ? "Remove bookmark" : "Add bookmark") {
                toggleBookmark()
            }
            Button("Play recitation") {
                playRecitation()
            }
            Button("Copy Arabic") {
                copyArabic()
            }
            if showTranslation {
                Button("Copy translation") {
                    copyTranslation()
                }
                #if canImport(AVFoundation)
                Button(isSpeakingTranslation ? "Stop speaking" : "Speak translation") {
                    speakTranslation()
                }
                #endif
            }
            Button("Share") {
                shareVerse()
            }
        }
        .onDisappear {
            #if canImport(AVFoundation)
            stopSpeakingAll()
            deactivateAudioSession()
            #endif
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [shareText])
        }
        #endif
    }

    private func playRecitation() {
        #if canImport(UIKit)
        #if !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        #endif
        #if canImport(AVFoundation)
        speakArabicRecitation()
        #endif
    }

    #if canImport(AVFoundation)
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("AudioSession deactivate error: \(error)")
        }
    }

    private func stopSpeakingAll() {
        speechSynth.stopSpeaking(at: .immediate)
        isSpeakingTranslation = false
        isSpeakingArabic = false
    }

    private func speakArabicRecitation() {
        if isSpeakingArabic {
            stopSpeakingAll()
            deactivateAudioSession()
            return
        }
        let text = verse.arabic
        guard !text.isEmpty else { return }
        configureAudioSession()
        if isSpeakingArabic {
            speechSynth.stopSpeaking(at: .immediate)
            isSpeakingArabic = false
        }
        let utterance = AVSpeechUtterance(string: text)
        if let voice = AVSpeechSynthesisVoice(language: "ar-SA") ?? AVSpeechSynthesisVoice(language: "ar") {
            utterance.voice = voice
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        speechSynth.speak(utterance)
        isSpeakingArabic = true
    }
    #endif

    #if canImport(AVFoundation)
    private func speakTranslation() {
        if isSpeakingTranslation {
            speechSynth.stopSpeaking(at: .immediate)
            isSpeakingTranslation = false
            deactivateAudioSession()
        } else {
            let text = showTranslation ? verse.translation : ""
            guard !text.isEmpty else { return }
            configureAudioSession()
            if isSpeakingArabic {
                speechSynth.stopSpeaking(at: .immediate)
                isSpeakingArabic = false
            }
            let utterance = AVSpeechUtterance(string: text)
            if AVSpeechSynthesisVoice(language: "en") != nil {
                utterance.voice = AVSpeechSynthesisVoice(language: "en")
            }
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            speechSynth.speak(utterance)
            isSpeakingTranslation = true
        }
        #if canImport(UIKit)
        #if !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        #endif
    }
    #endif

    private func copyArabic() {
        #if canImport(UIKit)
        UIPasteboard.general.string = verse.arabic
        #if !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        #endif
    }

    private func copyTranslation() {
        guard showTranslation else { return }
        #if canImport(UIKit)
        UIPasteboard.general.string = verse.translation
        #if !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        #endif
    }

    private func shareVerse() {
        #if canImport(UIKit)
        showShareSheet = true
        #endif
    }

    private func checkBookmark() {
        let saved = QuranStorageManager.shared.loadBookmarks()
        isBookmarked = saved.contains { $0.id == verse.id }
    }

    private func toggleBookmark() {
        var saved = QuranStorageManager.shared.loadBookmarks()
        if isBookmarked {
            saved.removeAll { $0.id == verse.id }
            isBookmarked = false
        } else {
            let bookmarkVerse = QuranVerse(
                id: verse.id,
                verseKey: verse.verseKey,
                arabic: verse.arabic,
                translation: verse.translation,
                surahName: verse.surahName ?? "Surah \(verse.surah)"
            )
            saved.append(bookmarkVerse)
            isBookmarked = true
        }

        QuranStorageManager.shared.saveBookmarks(saved)
        #if canImport(UIKit)
        #if !targetEnvironment(simulator)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        #endif
    }
}

#if canImport(UIKit)
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
