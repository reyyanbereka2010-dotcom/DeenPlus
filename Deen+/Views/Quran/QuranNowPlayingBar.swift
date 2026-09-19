//
//  QuranNowPlayingBar.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/9/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct QuranNowPlayingBar: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var player = RecitationPlayer.shared
    var onAyahTap: ((Int) -> Void)? = nil

    @State private var showExpandedSheet = false

    private var currentSurah: Int? {
        player.currentSurahId
    }

    private var currentAyah: Int {
        player.currentAyahNumber ?? 1
    }

    private var totalAyahs: Int {
        guard let surah = currentSurah else { return 1 }
        let total = player.totalAyahsForCurrentSurah
        return total > 0 ? total : SurahMetadata.get(surah).totalAyahs
    }

    private var progress: Double {
        guard totalAyahs > 0 else { return 0 }
        return Double(currentAyah) / Double(totalAyahs)
    }

    private var surahName: String {
        guard let surah = currentSurah else { return "Quran Recitation" }
        return SurahMetadata.get(surah).englishName
    }

    private var arabicSurahName: String {
        guard let surah = currentSurah else { return "" }
        return SurahNames.name(for: surah)
    }

    var body: some View {
        if player.currentSurahId != nil, player.currentAyahNumber != nil {
            VStack(spacing: 0) {
                // Subtle thin progress bar along top edge
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 3)

                        Rectangle()
                            .fill(Color.green)
                            .frame(width: max(0, min(geo.size.width * CGFloat(progress), geo.size.width)), height: 3)
                            .animation(.linear(duration: 0.25), value: progress)
                    }
                }
                .frame(height: 3)

                HStack(spacing: 12) {
                    // Tap left content to expand full player or center on ayah
                    Button {
                        #if canImport(UIKit)
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        #endif
                        showExpandedSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            // Animated waveform
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.18))
                                    .frame(width: 38, height: 38)

                                if player.isPlaying {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color.green)
                                        .symbolEffect(.variableColor.iterative, options: .repeating)
                                } else {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color.secondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(surahName) • Ayah \(currentAyah)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text(player.activeReciter.shortName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Playback Controls
                    HStack(spacing: 14) {
                        // Previous Ayah
                        Button {
                            #if canImport(UIKit)
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            #endif
                            player.previousAyah()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(currentAyah > 1 ? Color.primary : Color.secondary.opacity(0.3))
                        }
                        .disabled(currentAyah <= 1)
                        .buttonStyle(.plain)
                        .accessibilityLabel("Previous ayah")

                        // Play/Pause
                        Button {
                            #if canImport(UIKit)
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            #endif
                            if player.isPlaying {
                                player.pause()
                            } else {
                                player.resume()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 36, height: 36)

                                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(player.isPlaying ? "Pause recitation" : "Resume recitation")

                        // Next Ayah
                        Button {
                            #if canImport(UIKit)
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            #endif
                            player.nextAyah()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(currentAyah < totalAyahs ? Color.primary : Color.secondary.opacity(0.3))
                        }
                        .disabled(currentAyah >= totalAyahs)
                        .buttonStyle(.plain)
                        .accessibilityLabel("Next ayah")

                        // Close / Stop
                        Button {
                            #if canImport(UIKit)
                            let impact = UIImpactFeedbackGenerator(style: .rigid)
                            impact.impactOccurred()
                            #endif
                            player.stop()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.secondary)
                                .padding(6)
                                .background(Color.secondary.opacity(0.12), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Dismiss now playing")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 12)
            .frame(maxWidth: horizontalSizeClass == .regular ? 560 : .infinity)
            .frame(maxWidth: .infinity, alignment: .bottom)
            .sheet(isPresented: $showExpandedSheet) {
                QuranNowPlayingFullSheet(
                    onJumpToAyah: { ayah in
                        onAyahTap?(ayah)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Full Expanded Now Playing Sheet

struct QuranNowPlayingFullSheet: View {
    @ObservedObject var player = RecitationPlayer.shared
    @Environment(\.dismiss) private var dismiss
    var onJumpToAyah: ((Int) -> Void)? = nil

    private var currentSurah: Int {
        player.currentSurahId ?? 1
    }

    private var currentAyah: Int {
        player.currentAyahNumber ?? 1
    }

    private var totalAyahs: Int {
        let total = player.totalAyahsForCurrentSurah
        return total > 0 ? total : SurahMetadata.get(currentSurah).totalAyahs
    }

    private var surahName: String {
        SurahMetadata.get(currentSurah).englishName
    }

    private var arabicSurahName: String {
        SurahNames.name(for: currentSurah)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer(minLength: 10)

                // Calligraphic Hero Disc
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.25), Color.teal.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 170, height: 170)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
                        )

                    VStack(spacing: 8) {
                        Text(arabicSurahName)
                            .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 38))
                            .foregroundStyle(.green)
                            .multilineTextAlignment(.center)

                        Text("Surah \(currentSurah)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .shadow(color: Color.green.opacity(0.18), radius: 16, x: 0, y: 8)

                // Title & Ayah Info
                VStack(spacing: 4) {
                    Text(surahName)
                        .font(.title2.weight(.bold))

                    Text("Ayah \(currentAyah) of \(totalAyahs)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                // Ayah Scrubber Slider
                VStack(spacing: 6) {
                    Slider(
                        value: Binding(
                            get: { Double(currentAyah) },
                            set: { newValue in
                                let target = Int(newValue)
                                if target != currentAyah {
                                    player.jumpToAyah(target)
                                    onJumpToAyah?(target)
                                }
                            }
                        ),
                        in: 1...Double(max(1, totalAyahs)),
                        step: 1
                    )
                    .tint(.green)

                    HStack {
                        Text("Ayah 1")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("Ayah \(totalAyahs)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 28)

                // Large Transport Controls
                HStack(spacing: 36) {
                    // Previous Ayah
                    Button {
                        #if canImport(UIKit)
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        #endif
                        player.previousAyah()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(currentAyah > 1 ? Color.primary : Color.secondary.opacity(0.3))
                    }
                    .disabled(currentAyah <= 1)

                    // Main Play/Pause
                    Button {
                        #if canImport(UIKit)
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        #endif
                        if player.isPlaying {
                            player.pause()
                        } else {
                            player.resume()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 68, height: 68)

                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 6)
                    }

                    // Next Ayah
                    Button {
                        #if canImport(UIKit)
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        #endif
                        player.nextAyah()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(currentAyah < totalAyahs ? Color.primary : Color.secondary.opacity(0.3))
                    }
                    .disabled(currentAyah >= totalAyahs)
                }

                // Reciter Selector Pill
                Menu {
                    ForEach(Reciter.allCases) { reciter in
                        Button {
                            player.setReciter(reciter)
                            if !player.isPlaying {
                                player.playSurah(surahId: currentSurah, startAyah: currentAyah, reciter: reciter)
                            }
                        } label: {
                            HStack {
                                Text(reciter.displayName)
                                if player.activeReciter == reciter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.wave.2.fill")
                            .font(.subheadline)
                        Text(player.activeReciter.displayName)
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
                    .foregroundStyle(.primary)
                }

                // Audio Modifiers: Speed, Repeat, Timer
                HStack(spacing: 16) {
                    // Speed Menu
                    Menu {
                        Button("0.75x") { player.setPlaybackSpeed(0.75) }
                        Button("1.0x (Normal)") { player.setPlaybackSpeed(1.0) }
                        Button("1.25x") { player.setPlaybackSpeed(1.25) }
                        Button("1.5x") { player.setPlaybackSpeed(1.5) }
                    } label: {
                        Label(String(format: "%.2gx", player.playbackSpeed), systemImage: "gauge.with.dots.needle.bottom.50percent")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1), in: Capsule())
                    }

                    // Repeat Menu
                    Menu {
                        Button("Play Once (1x)") { player.setRepeatCount(1) }
                        Button("Repeat 2x") { player.setRepeatCount(2) }
                        Button("Repeat 3x") { player.setRepeatCount(3) }
                        Button("Repeat 5x") { player.setRepeatCount(5) }
                        Button("Loop Ayah (∞)") { player.setRepeatCount(0) }
                    } label: {
                        Label(player.repeatCount == 0 ? "∞" : "\(player.repeatCount)x", systemImage: "repeat")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1), in: Capsule())
                    }

                    // Sleep Timer
                    Menu {
                        Button("Off") { player.setSleepTimer(minutes: 0) }
                        Button("15 Minutes") { player.setSleepTimer(minutes: 15) }
                        Button("30 Minutes") { player.setSleepTimer(minutes: 30) }
                        Button("45 Minutes") { player.setSleepTimer(minutes: 45) }
                        Button("60 Minutes") { player.setSleepTimer(minutes: 60) }
                    } label: {
                        Label(
                            player.sleepTimerRemainingMinutes > 0 ? "\(player.sleepTimerRemainingMinutes)m" : "Timer",
                            systemImage: "moon.zzz"
                        )
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.1), in: Capsule())
                    }
                }

                Spacer(minLength: 10)
            }
            .padding()
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
