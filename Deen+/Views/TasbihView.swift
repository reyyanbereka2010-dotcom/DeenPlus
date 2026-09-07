//
//  TasbihView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI
import CoreHaptics
#if canImport(UIKit)
import UIKit
#endif

struct DhikrPreset: Identifiable, Hashable {
    let id = UUID()
    let arabic: String
    let transliteration: String
    let translation: String
    let defaultTarget: Int
}

struct TasbihView: View {
    
    @AppStorage("tasbih_total_count") private var totalCount: Int = 0
    @AppStorage("tasbih_haptic_feedback") private var hapticFeedbackEnabled: Bool = true
    @State private var currentCount: Int = 0
    @State private var targetCount: Int = 33
    @State private var selectedPresetIndex: Int = 0
    @State private var showResetConfirmation: Bool = false
    
    private let presets: [DhikrPreset] = [
        DhikrPreset(
            arabic: "سُبْحَانَ ٱللَّٰهِ",
            transliteration: "SubhanAllah",
            translation: "Glory be to Allah",
            defaultTarget: 33
        ),
        DhikrPreset(
            arabic: "ٱلْحَمْدُ لِلَّٰهِ",
            transliteration: "Alhamdulillah",
            translation: "Praise be to Allah",
            defaultTarget: 33
        ),
        DhikrPreset(
            arabic: "ٱللَّٰهُ أَكْبَرُ",
            transliteration: "Allahu Akbar",
            translation: "Allah is the Greatest",
            defaultTarget: 33
        ),
        DhikrPreset(
            arabic: "لَا إِلَٰهَ إِلَّا ٱللَّٰهُ",
            transliteration: "La ilaha illa Allah",
            translation: "There is no god but Allah",
            defaultTarget: 100
        ),
        DhikrPreset(
            arabic: "أَسْتَغْفِرُ ٱللَّٰهَ",
            transliteration: "Astaghfirullah",
            translation: "I seek forgiveness from Allah",
            defaultTarget: 100
        ),
        DhikrPreset(
            arabic: "سُبْحَانَ ٱللَّٰهِ وَبِحَمْدِهِ",
            transliteration: "SubhanAllahi wa Bihamdihi",
            translation: "Glory be to Allah and Praise Him",
            defaultTarget: 100
        )
    ]
    
    private var currentPreset: DhikrPreset {
        presets[selectedPresetIndex]
    }
    
    private var progressRatio: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(currentCount) / Double(targetCount), 1.0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Dhikr Selector Carousel
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<presets.count, id: \.self) { index in
                                    let preset = presets[index]
                                    Button {
                                        triggerSelectionHaptic()
                                        selectedPresetIndex = index
                                        targetCount = preset.defaultTarget
                                        currentCount = 0
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(preset.transliteration)
                                                .font(.headline)
                                                .foregroundStyle(selectedPresetIndex == index ? .white : .primary)
                                            Text("\(preset.defaultTarget)x")
                                                .font(.caption2)
                                                .foregroundStyle(selectedPresetIndex == index ? .white.opacity(0.8) : .secondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedPresetIndex == index
                                            ? Color.green
                                            : Color(.secondarySystemGroupedBackground)
                                        )
                                        .clipShape(Capsule())
                                        .shadow(color: Color.black.opacity(selectedPresetIndex == index ? 0.15 : 0.03), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }
                        
                        // Main Dhikr Display Card
                        VStack(spacing: 14) {
                            Text(currentPreset.arabic)
                                .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 36))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.green)
                                .padding(.top, 8)
                            
                            Text(currentPreset.transliteration)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(currentPreset.translation)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        // Circular Counter Button
                        ZStack {
                            // Progress ring background
                            Circle()
                                .stroke(Color.green.opacity(0.15), lineWidth: 16)
                                .frame(width: 220, height: 220)
                            
                            // Progress ring fill
                            Circle()
                                .trim(from: 0.0, to: CGFloat(progressRatio))
                                .stroke(Color.green, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 220, height: 220)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentCount)
                            
                            Button {
                                incrementCounter()
                            } label: {
                                Circle()
                                    .fill(Color.green.opacity(0.12))
                                    .frame(width: 180, height: 180)
                                    .overlay(
                                        VStack(spacing: 4) {
                                            Text("\(currentCount)")
                                                .font(.system(size: 54, weight: .bold, design: .rounded))
                                                .foregroundStyle(.green)
                                            
                                            Text(targetCount == 0 ? "/ ∞" : "/ \(targetCount)")
                                                .font(.callout)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.secondary)
                                        }
                                    )
                                    .shadow(color: Color.green.opacity(0.2), radius: 10, x: 0, y: 5)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.vertical, 10)
                        
                        // Control Bar (Targets & Reset)
                        HStack(spacing: 24) {
                            // Target Selector
                            Menu {
                                Button("33 Times") { setTarget(33) }
                                Button("99 Times") { setTarget(99) }
                                Button("100 Times") { setTarget(100) }
                                Button("Unlimited") { setTarget(0) }
                            } label: {
                                Label(targetCount == 0 ? "Target: ∞" : "Target: \(targetCount)", systemImage: "target")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                            }
                            
                            // Reset Button
                            Button {
                                triggerResetHaptic()
                                currentCount = 0
                            } label: {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Total Dhikr Stats Card
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("Total Dhikr Completed:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(totalCount)")
                                .font(.headline)
                                .bold()
                                .foregroundStyle(.green)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                    }
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Tasbih Counter")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showResetConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Reset total stats")
                }
            }
            .confirmationDialog(
                "Reset All Tasbih Counts?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset All Counters", role: .destructive) {
                    triggerResetHaptic()
                    totalCount = 0
                    currentCount = 0
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will reset your current session and your lifetime Dhikr count back to zero.")
            }
        }
    }
    
    private func incrementCounter() {
        currentCount += 1
        totalCount += 1
        
        if targetCount > 0 && currentCount >= targetCount {
            triggerCompletionHaptic()
            currentCount = 0 // Silently reset target count without alert popup
        } else {
            triggerTapHaptic()
        }
    }
    
    private func setTarget(_ target: Int) {
        triggerSelectionHaptic()
        targetCount = target
        currentCount = 0
    }
    
    // MARK: - Rich Haptics
    private func triggerTapHaptic() {
        guard hapticFeedbackEnabled else { return }
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        #endif
    }
    
    private func triggerSelectionHaptic() {
        #if canImport(UIKit)
        let selection = UISelectionFeedbackGenerator()
        selection.selectionChanged()
        #endif
    }
    
    private func triggerResetHaptic() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()
        #endif
    }
    
    private func triggerCompletionHaptic() {
        #if canImport(UIKit)
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        #endif
    }
}

#Preview {
    TasbihView()
}
