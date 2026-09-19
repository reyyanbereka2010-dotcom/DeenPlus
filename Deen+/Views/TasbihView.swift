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

struct DhikrPreset: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    let arabic: String
    let transliteration: String
    let translation: String
    let defaultTarget: Int
    var isCustom: Bool = false
}

struct TasbihView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @AppStorage("tasbih_total_count") private var totalCount: Int = 0
    @AppStorage("tasbih_haptic_feedback") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("custom_dhikrs_json_v1") private var rawCustomDhikrs: String = "[]"
    
    @State private var currentCount: Int = 0
    @State private var targetCount: Int = 33
    @State private var selectedPresetIndex: Int = 0
    @State private var showResetConfirmation: Bool = false
    @State private var showAddCustomSheet: Bool = false
    
    // Add custom dhikr state
    @State private var newTransliteration: String = ""
    @State private var newArabic: String = ""
    @State private var newTranslation: String = ""
    @State private var newTarget: Int = 33
    
    private let defaultPresets: [DhikrPreset] = [
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
        ),
        DhikrPreset(
            arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ",
            transliteration: "Salawat on Prophet ﷺ",
            translation: "O Allah, send blessings upon Muhammad",
            defaultTarget: 100
        )
    ]
    
    private var customPresets: [DhikrPreset] {
        get {
            guard let data = rawCustomDhikrs.data(using: .utf8),
                  let items = try? JSONDecoder().decode([DhikrPreset].self, from: data) else {
                return []
            }
            return items
        }
    }
    
    private var allPresets: [DhikrPreset] {
        defaultPresets + customPresets
    }
    
    private var safeSelectedPresetIndex: Int {
        if selectedPresetIndex >= allPresets.count {
            return 0
        }
        return selectedPresetIndex
    }
    
    private var currentPreset: DhikrPreset {
        allPresets[safeSelectedPresetIndex]
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
                        // Dhikr Selector Carousel with Add Custom Button
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(allPresets.enumerated()), id: \.element.id) { index, preset in
                                    Button {
                                        triggerSelectionHaptic()
                                        selectedPresetIndex = index
                                        targetCount = preset.defaultTarget
                                        currentCount = 0
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(preset.transliteration)
                                                .font(.headline)
                                                .foregroundStyle(safeSelectedPresetIndex == index ? .white : .primary)
                                            Text(preset.defaultTarget == 0 ? "∞" : "\(preset.defaultTarget)x")
                                                .font(.caption2)
                                                .foregroundStyle(safeSelectedPresetIndex == index ? .white.opacity(0.8) : .secondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            safeSelectedPresetIndex == index
                                            ? Color.green
                                            : Color(.secondarySystemGroupedBackground)
                                        )
                                        .clipShape(Capsule())
                                        .shadow(color: Color.black.opacity(safeSelectedPresetIndex == index ? 0.15 : 0.03), radius: 4, x: 0, y: 2)
                                    }
                                }

                                // Add Custom Dhikr Button
                                Button {
                                    triggerSelectionHaptic()
                                    showAddCustomSheet = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Custom")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }
                        
                        // Main Dhikr Display Card
                        VStack(spacing: 14) {
                            if !currentPreset.arabic.isEmpty {
                                Text(currentPreset.arabic)
                                    .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 36))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.green)
                                    .padding(.top, 8)
                            }
                            
                            Text(currentPreset.transliteration)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if !currentPreset.translation.isEmpty {
                                Text(currentPreset.translation)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }

                            if currentPreset.isCustom {
                                Button(role: .destructive) {
                                    deleteCustomDhikr(currentPreset)
                                } label: {
                                    Label("Remove Custom Dhikr", systemImage: "trash")
                                        .font(.caption)
                                        .foregroundStyle(.red.opacity(0.8))
                                }
                                .padding(.top, 4)
                            }
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
                                Button("500 Times") { setTarget(500) }
                                Button("1,000 Times") { setTarget(1000) }
                                Button("Unlimited (∞)") { setTarget(0) }
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
                    .frame(maxWidth: horizontalSizeClass == .regular ? 580 : .infinity)
                    .frame(maxWidth: .infinity)
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
            .sheet(isPresented: $showAddCustomSheet) {
                NavigationStack {
                    Form {
                        Section("Dhikr Information") {
                            TextField("Name / Transliteration (e.g. Hasbunallahu)", text: $newTransliteration)
                            TextField("Arabic Text (optional)", text: $newArabic)
                            TextField("English Translation (optional)", text: $newTranslation)
                        }

                        Section("Recitation Target") {
                            Picker("Target Count", selection: $newTarget) {
                                Text("33 Times").tag(33)
                                Text("100 Times").tag(100)
                                Text("500 Times").tag(500)
                                Text("1,000 Times").tag(1000)
                                Text("Unlimited (∞)").tag(0)
                            }
                        }
                    }
                    .navigationTitle("Add Custom Dhikr")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showAddCustomSheet = false
                            }
                        }

                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveCustomDhikr()
                            }
                            .disabled(newTransliteration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    private func saveCustomDhikr() {
        let trimmedName = newTransliteration.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let preset = DhikrPreset(
            arabic: newArabic.trimmingCharacters(in: .whitespacesAndNewlines),
            transliteration: trimmedName,
            translation: newTranslation.trimmingCharacters(in: .whitespacesAndNewlines),
            defaultTarget: newTarget,
            isCustom: true
        )

        var list = customPresets
        list.append(preset)
        if let encoded = try? JSONEncoder().encode(list),
           let str = String(data: encoded, encoding: .utf8) {
            rawCustomDhikrs = str
        }

        // Switch to the newly created dhikr
        let newIndex = defaultPresets.count + list.count - 1
        selectedPresetIndex = max(0, newIndex)
        targetCount = preset.defaultTarget
        currentCount = 0

        // Reset form
        newTransliteration = ""
        newArabic = ""
        newTranslation = ""
        newTarget = 33
        showAddCustomSheet = false

        triggerCompletionHaptic()
    }

    private func deleteCustomDhikr(_ preset: DhikrPreset) {
        var list = customPresets
        list.removeAll { $0.id == preset.id }
        if let encoded = try? JSONEncoder().encode(list),
           let str = String(data: encoded, encoding: .utf8) {
            rawCustomDhikrs = str
        }

        selectedPresetIndex = 0
        targetCount = defaultPresets[0].defaultTarget
        currentCount = 0
        triggerResetHaptic()
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
