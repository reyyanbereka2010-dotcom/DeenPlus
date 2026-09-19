//
//  QiblaCustomizationSheet.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/12/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct QiblaCustomizationSheet: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("qiblaConfigMode") private var configMode: String = QiblaConfigurationMode.automatic.rawValue
    @AppStorage("qiblaCompassStyle") private var compassStyle: String = QiblaCompassDialStyle.modern.rawValue
    @AppStorage("qiblaNeedleStyle") private var needleStyle: String = QiblaNeedleStyle.kaaba.rawValue
    @AppStorage("qiblaDistanceUnit") private var distanceUnit: String = QiblaAutoSettings.autoDistanceUnit().rawValue
    @AppStorage("qiblaNorthReference") private var northReference: String = QiblaNorthReference.trueNorth.rawValue
    @AppStorage("qiblaHapticEnabled") private var hapticEnabled: Bool = true
    @AppStorage("qiblaHapticIntensity") private var hapticIntensity: String = QiblaHapticIntensity.crisp.rawValue
    @AppStorage("qiblaShowLevelBubble") private var showLevelBubble: Bool = false
    @AppStorage("qiblaAlignmentTolerance") private var alignmentTolerance: Double = 4.0

    @AppStorage("appAccentColor") private var appAccentColor = "emerald"

    private var accent: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Setup Mode Chooser
                Section {
                    Picker("Configuration Mode", selection: $configMode) {
                        Text("Automatic").tag(QiblaConfigurationMode.automatic.rawValue)
                        Text("Custom").tag(QiblaConfigurationMode.custom.rawValue)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: configMode) { _, newMode in
                        triggerHaptic()
                        if newMode == QiblaConfigurationMode.automatic.rawValue {
                            QiblaAutoSettings.applyRecommended()
                        }
                    }

                    if configMode == QiblaConfigurationMode.automatic.rawValue {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(accent)
                                Text("Auto Mode Enabled")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            Text("Deen+ automatically optimizes distance units, True North calibration, and sensor precision. You can freely choose your preferred compass dial and needle design below.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Compass Mode")
                } footer: {
                    if configMode == QiblaConfigurationMode.automatic.rawValue {
                        Text("Auto mode handles calculations and calibration, but you can still customize your compass style below.")
                    } else {
                        Text("Custom mode gives you manual control over north reference, distance units, and alignment tolerance.")
                    }
                }

                // MARK: - Compass Dial Theme (Always Available in Both Auto & Custom)
                Section("Compass Dial Theme") {
                    ForEach(QiblaCompassDialStyle.allCases) { style in
                        Button {
                            triggerHaptic()
                            compassStyle = style.rawValue
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: style.icon)
                                    .font(.title3)
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(compassStyle == style.rawValue ? accent : .secondary)

                                Text(style.displayName)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if compassStyle == style.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(accent)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: - Needle Pointer (Always Available in Both Auto & Custom)
                Section("Needle Pointer") {
                    ForEach(QiblaNeedleStyle.allCases) { needle in
                        Button {
                            triggerHaptic()
                            needleStyle = needle.rawValue
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: needle.icon)
                                    .font(.title3)
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(needleStyle == needle.rawValue ? accent : .secondary)

                                Text(needle.displayName)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if needleStyle == needle.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(accent)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: - Alignment Vibration Feedback (Always Available)
                Section("Alignment Feedback") {
                    Toggle("Vibrate on Kaaba Alignment", isOn: $hapticEnabled)

                    if hapticEnabled {
                        Picker("Vibration Strength", selection: $hapticIntensity) {
                            ForEach(QiblaHapticIntensity.allCases) { item in
                                Text(item.displayName).tag(item.rawValue)
                            }
                        }
                    }
                }

                // MARK: - Advanced Sections (Available in Custom Mode)
                if configMode == QiblaConfigurationMode.custom.rawValue {
                    Section("Units & Direction Reference") {
                        Picker("North Reference", selection: $northReference) {
                            ForEach(QiblaNorthReference.allCases) { ref in
                                Text(ref.displayName).tag(ref.rawValue)
                            }
                        }

                        Picker("Distance Unit", selection: $distanceUnit) {
                            ForEach(QiblaDistanceUnit.allCases) { unit in
                                Text(unit.displayName).tag(unit.rawValue)
                            }
                        }

                        Toggle("Center Reticle Bubble", isOn: $showLevelBubble)
                    }

                    Section("Sensitivity") {
                        Picker("Alignment Tolerance", selection: $alignmentTolerance) {
                            Text("Precise (±2°)").tag(2.0)
                            Text("Standard (±4°)").tag(4.0)
                            Text("Relaxed (±6°)").tag(6.0)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Compass Settings")
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

    private func triggerHaptic() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
    }
}
