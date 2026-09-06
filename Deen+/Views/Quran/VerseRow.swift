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

    @ObservedObject private var recitationPlayer = RecitationPlayer.shared

    private var isPlayingRecitation: Bool {
        recitationPlayer.isPlayingAyah(surahId: verse.surah, ayahNumber: verse.ayah)
    }

    private var accessibilityVerseLabel: String {
        let surahNameText = verse.surahName ?? "Surah \(verse.surah)"
        return "\(surahNameText), Ayah \(verse.verseKey.split(separator: ":").last ?? "")"
    }

    private var ayahNumber: String {
        String(verse.verseKey.split(separator: ":").last ?? "")
    }

    private var recitationAccessibilityLabel: String {
        if isPlayingRecitation {
            return "Pause recitation"
        } else {
            return "Play recitation by \(recitationPlayer.activeReciter.displayName)"
        }
    }

    @State private var isBookmarked = false

    #if canImport(AVFoundation)
    @State private var speechSynth = AVSpeechSynthesizer()
    @State private var isSpeakingTranslation = false
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
                if isPlayingRecitation {
                    HStack(spacing: 5) {
                        Image(systemName: "waveform")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text(recitationPlayer.activeReciter.shortName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                }

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
                        systemName: isPlayingRecitation ? "pause.circle.fill" : "play.circle.fill"
                    )
                    .font(.title2)
                    .foregroundStyle(isPlayingRecitation ? Color.green : Color.primary)
                    .accessibilityLabel(recitationAccessibilityLabel)
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
                    .foregroundStyle(isBookmarked ? Color.orange : Color.primary)
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
                isPlayingRecitation
                ? Color.green.opacity(0.16)
                : (highlighted ? Color.green.opacity(0.18) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(isPlayingRecitation ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .accessibilityAddTraits(highlighted || isPlayingRecitation ? .isSelected : [])
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
                Label(
                    isPlayingRecitation ? "Pause Recitation" : "Play Recitation (\(recitationPlayer.activeReciter.shortName))",
                    systemImage: isPlayingRecitation ? "pause.circle.fill" : "play.circle.fill"
                )
            }
            #if canImport(AVFoundation)
            if showTranslation {
                Button {
                    speakTranslation()
                } label: {
                    Label(isSpeakingTranslation ? "Stop speaking English" : "Speak English translation", systemImage: "speaker.wave.2.fill")
                }
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
                Label(isPlayingRecitation ? "Pause" : "Play", systemImage: isPlayingRecitation ? "pause.fill" : "play.fill")
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
            value: highlighted || isPlayingRecitation
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
            Button(isPlayingRecitation ? "Pause recitation" : "Play recitation") {
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
                Button(isSpeakingTranslation ? "Stop speaking English" : "Speak English translation") {
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
            if isSpeakingTranslation {
                speechSynth.stopSpeaking(at: .immediate)
                isSpeakingTranslation = false
            }
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
        if isSpeakingTranslation {
            speechSynth.stopSpeaking(at: .immediate)
            isSpeakingTranslation = false
        }
        #endif

        recitationPlayer.togglePlayAyah(surahId: verse.surah, ayahNumber: verse.ayah)
    }

    #if canImport(AVFoundation)
    private func speakTranslation() {
        if isSpeakingTranslation {
            speechSynth.stopSpeaking(at: .immediate)
            isSpeakingTranslation = false
        } else {
            let text = showTranslation ? verse.translation : ""
            guard !text.isEmpty else { return }
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
        } else {
            saved.append(verse)
        }
        QuranStorageManager.shared.saveBookmarks(saved)
        isBookmarked.toggle()
        #if canImport(UIKit)
        #if !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
