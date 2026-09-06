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
    var translationSize: CGFloat = 16
    let showTranslation: Bool
    let highlighted: Bool

    @ObservedObject private var recitationPlayer = RecitationPlayer.shared
    @ObservedObject private var translationNarrator = TranslationNarrator.shared

    @State private var isBookmarked = false
    @State private var showCopiedAlert = false

    #if canImport(UIKit)
    @State private var showShareSheet = false
    #endif

    private var isPlayingRecitation: Bool {
        recitationPlayer.isPlayingAyah(surahId: verse.surah, ayahNumber: verse.ayah)
    }

    private var isSpeakingTranslation: Bool {
        translationNarrator.isSpeaking(surah: verse.surah, ayah: verse.ayah)
    }

    private var ayahNumber: String {
        String(verse.verseKey.split(separator: ":").last ?? "")
    }

    private var accessibilityVerseLabel: String {
        let surahNameText = verse.surahName ?? "Surah \(verse.surah)"
        return "\(surahNameText), Ayah \(ayahNumber)"
    }

    private var recitationAccessibilityLabel: String {
        isPlayingRecitation ? "Pause recitation" : "Play recitation by \(recitationPlayer.activeReciter.displayName)"
    }

    private var shareText: String {
        var parts: [String] = []
        parts.append(verse.verseKey)
        parts.append(verse.arabic)
        if showTranslation {
            parts.append(verse.translation)
        }
        return parts.joined(separator: "\n\n")
    }

    private var cardBackgroundColor: Color {
        if isPlayingRecitation {
            return Color.green.opacity(0.18)
        } else if isSpeakingTranslation {
            return Color.blue.opacity(0.15)
        } else if highlighted {
            return Color.green.opacity(0.18)
        } else {
            return Color(.secondarySystemBackground)
        }
    }

    private var cardBorderColor: Color {
        if isPlayingRecitation {
            return Color.green.opacity(0.7)
        } else if isSpeakingTranslation {
            return Color.blue.opacity(0.6)
        } else if highlighted {
            return Color.green.opacity(0.4)
        } else {
            return Color.clear
        }
    }

    private var cardBorderWidth: CGFloat {
        (isPlayingRecitation || isSpeakingTranslation) ? 2 : 1
    }

    private var cardShadowColor: Color {
        if isPlayingRecitation {
            return Color.green.opacity(0.16)
        } else if isSpeakingTranslation {
            return Color.blue.opacity(0.14)
        } else {
            return Color.black.opacity(0.06)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 18) {
            headerRow
            arabicView
            verseSeparator
            if showTranslation {
                translationView
            }
            actionBar
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(cardBorderColor, lineWidth: cardBorderWidth)
        )
        .shadow(
            color: cardShadowColor,
            radius: (isPlayingRecitation || isSpeakingTranslation) ? 12 : 8,
            x: 0,
            y: 4
        )
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .contextMenu {
            contextMenuItems
        }
        .animation(.easeInOut(duration: 0.3), value: highlighted || isPlayingRecitation || isSpeakingTranslation)
        .onAppear {
            checkBookmark()
        }
        .onChange(of: verse.id) { _ in
            checkBookmark()
        }
        .onDisappear {
            if isSpeakingTranslation {
                translationNarrator.stop()
            }
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [shareText])
        }
        #endif
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack {
            if isPlayingRecitation {
                HStack(spacing: 5) {
                    Image(systemName: "waveform")
                        .font(.caption2)
                        .foregroundStyle(.green)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                    Text(recitationPlayer.activeReciter.shortName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12), in: Capsule())
            } else if isSpeakingTranslation {
                HStack(spacing: 5) {
                    Image(systemName: "waveform")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                    Text(translationNarrator.activeVoice.shortName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.12), in: Capsule())
            }

            Spacer()

            if showCopiedAlert {
                Text("Copied!")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.14), in: Capsule())
            }

            HStack(spacing: 4) {
                Text("Ayah")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(ayahNumber)
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.14), in: Capsule())
        }
        .padding(.horizontal, 4)
    }

    private var arabicView: some View {
        Text(verse.arabic)
            .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: arabicSize))
            .multilineTextAlignment(.trailing)
            .lineSpacing(18)
            .environment(\.layoutDirection, .rightToLeft)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .textSelection(.enabled)
            .accessibilityLabel(accessibilityVerseLabel)
            .accessibilityHint("Double tap to toggle bookmark or play audio")
    }

    private var verseSeparator: some View {
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
    }

    private var translationView: some View {
        Text(verse.translation)
            .font(.system(size: translationSize))
            .lineSpacing(5)
            .multilineTextAlignment(.leading)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .accessibilityLabel("Translation: \(verse.translation)")
    }

    private var actionBar: some View {
        HStack(spacing: 24) {
            Button {
                playRecitation()
            } label: {
                Image(systemName: isPlayingRecitation ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isPlayingRecitation ? Color.green : Color.primary)
                    .accessibilityLabel(recitationAccessibilityLabel)
            }

            if showTranslation {
                Button {
                    speakTranslation()
                } label: {
                    Image(systemName: isSpeakingTranslation ? "speaker.wave.3.circle.fill" : "speaker.wave.2.circle")
                        .font(.title2)
                        .foregroundStyle(isSpeakingTranslation ? Color.blue : Color.secondary)
                        .accessibilityLabel(isSpeakingTranslation ? "Stop English narration" : "Listen to translation by \(translationNarrator.activeVoice.shortName)")
                }
            }

            Button {
                toggleBookmark()
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.title3)
                    .foregroundStyle(isBookmarked ? Color.orange : Color.primary)
                    .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
            }

            Button {
                copyVerse()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Copy ayah and translation")
            }

            Button {
                shareVerse()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Share ayah")
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            copyArabic()
        } label: {
            Label("Copy Arabic", systemImage: "doc.on.doc")
        }

        if showTranslation {
            Button {
                copyTranslation()
            } label: {
                Label("Copy Translation", systemImage: "doc.on.doc")
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

        if showTranslation {
            Button {
                speakTranslation()
            } label: {
                Label(
                    isSpeakingTranslation ? "Stop English Narration" : "Listen in English (\(translationNarrator.activeVoice.shortName))",
                    systemImage: isSpeakingTranslation ? "speaker.slash.fill" : "speaker.wave.2.fill"
                )
            }
        }

        Divider()

        Button {
            toggleBookmark()
        } label: {
            Label(isBookmarked ? "Remove Bookmark" : "Add Bookmark", systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
        }
    }

    // MARK: - Actions

    private func playRecitation() {
        #if canImport(UIKit)
        #if !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        #endif

        if isSpeakingTranslation {
            translationNarrator.stop()
        }

        recitationPlayer.togglePlayAyah(surahId: verse.surah, ayahNumber: verse.ayah)
    }

    private func speakTranslation() {
        #if canImport(UIKit)
        #if !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        #endif

        if isPlayingRecitation {
            recitationPlayer.pause()
        }

        let text = showTranslation ? verse.translation : ""
        translationNarrator.togglePlay(surah: verse.surah, ayah: verse.ayah, text: text)
    }

    private func copyVerse() {
        #if canImport(UIKit)
        UIPasteboard.general.string = shareText
        #if !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        #endif
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showCopiedAlert = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedAlert = false
            }
        }
    }

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
