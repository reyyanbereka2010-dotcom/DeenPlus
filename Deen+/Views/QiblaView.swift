//
//  QiblaView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI
import CoreHaptics
#if canImport(UIKit)
import UIKit
#endif

struct QiblaView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var qiblaManager: QiblaManager
    @EnvironmentObject var locationManager: LocationManager

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

    @State private var qiblaViewActive = false
    @State private var hasVibrated = false
    @State private var showCustomizationSheet = false
    @State private var isRecalculating = false

    private var activeDialStyle: QiblaCompassDialStyle {
        QiblaCompassDialStyle(rawValue: compassStyle) ?? .modern
    }

    private var activeNeedleStyle: QiblaNeedleStyle {
        QiblaNeedleStyle(rawValue: needleStyle) ?? .kaaba
    }

    private var activeDistanceUnit: QiblaDistanceUnit {
        if configMode == QiblaConfigurationMode.automatic.rawValue {
            return QiblaAutoSettings.autoDistanceUnit()
        }
        return QiblaDistanceUnit(rawValue: distanceUnit) ?? .kilometers
    }

    private var accent: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    private var isAligned: Bool {
        qiblaManager.isFacingQibla(tolerance: alignmentTolerance)
    }

    // MARK: - Haptic Feedback

    private func playAlignmentHaptic() {
        guard hapticEnabled else { return }
        #if canImport(UIKit)
        switch hapticIntensity {
        case "subtle":
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred(intensity: 0.6)
        case "strong":
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred(intensity: 1.0)
        default:
            let notify = UINotificationFeedbackGenerator()
            notify.notificationOccurred(.success)
        }
        #endif
    }

    private func recalculateLocationAndQibla() {
        #if canImport(UIKit)
        let notify = UINotificationFeedbackGenerator()
        notify.notificationOccurred(.success)
        #endif

        isRecalculating = true

        locationManager.recalculateLocation()

        let lat = locationManager.latitude != 0 ? locationManager.latitude : QiblaManager.kaabaLatitude
        let lon = locationManager.longitude != 0 ? locationManager.longitude : QiblaManager.kaabaLongitude
        qiblaManager.recalculateQibla(latitude: lat, longitude: lon)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isRecalculating = false
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Simple, High-Visibility Direction Guidance Banner (Fixed height to prevent vertical jitter)
                        SimpleDirectionBanner(
                            isAligned: isAligned,
                            offset: qiblaManager.relativeOffsetToQibla,
                            accentColor: accent
                        )
                        .padding(.horizontal, 18)
                        .padding(.top, 4)

                        // 2. Precision Interactive Compass Disc (Fixed center pivot, no up/down wobbling)
                        VStack(spacing: 8) {
                            QiblaCompassDiscView(
                                qiblaManager: qiblaManager,
                                dialStyle: activeDialStyle,
                                needleStyle: activeNeedleStyle,
                                showLevel: showLevelBubble,
                                accentColor: accent
                            )
                            .padding(.vertical, 4)

                            // Clean Forward Heading Readout
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(Int(qiblaManager.heading.rounded()))°")
                                    .font(.system(size: 34, weight: .light, design: .rounded))
                                    .foregroundStyle(.primary)

                                Text(qiblaManager.headingCardinalShort)
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            // Reserved Flat Guidance Row (Fixed height 22pt so layout NEVER jumps up and down)
                            HStack(spacing: 6) {
                                if !qiblaManager.isLevel {
                                    Image(systemName: "iphone.gen1")
                                        .font(.caption2)
                                    Text("Hold phone flat for accurate direction")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                            .foregroundStyle(Color.orange)
                            .frame(height: 22)
                        }

                        // 3. Normal Person Friendly Information Cards (Simple, useful, zero confusing jargon)
                        VStack(spacing: 10) {
                            // Distance to Kaaba Card
                            HStack {
                                Label("Distance to Kaaba", systemImage: "arrow.triangle.swap")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(qiblaManager.formattedDistanceToKaaba(
                                    userLat: locationManager.latitude != 0 ? locationManager.latitude : QiblaManager.kaabaLatitude,
                                    userLon: locationManager.longitude != 0 ? locationManager.longitude : QiblaManager.kaabaLongitude,
                                    unit: activeDistanceUnit
                                ))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            // Qibla Direction Bearing Card
                            HStack {
                                Label("Qibla Direction", systemImage: "safari.fill")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.0f° %@", qiblaManager.qiblaDirection, qiblaManager.qiblaCardinalShort))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            // Location Card
                            HStack {
                                Label("Current Location", systemImage: "location.fill")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(locationManager.city == "Unknown" ? "Locating..." : locationManager.city)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal, 18)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: horizontalSizeClass == .regular ? 580 : .infinity)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Qibla")
            .navigationBarTitleDisplayMode(.large)
            .safeAreaPadding(.bottom, 60)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Quick Compass Dial & Needle Chooser Menu
                    Menu {
                        Section("Compass Dial") {
                            ForEach(QiblaCompassDialStyle.allCases) { style in
                                Button {
                                    compassStyle = style.rawValue
                                } label: {
                                    if compassStyle == style.rawValue {
                                        Label(style.displayName, systemImage: "checkmark")
                                    } else {
                                        Label(style.displayName, systemImage: style.icon)
                                    }
                                }
                            }
                        }

                        Section("Needle Pointer") {
                            ForEach(QiblaNeedleStyle.allCases) { needle in
                                Button {
                                    needleStyle = needle.rawValue
                                } label: {
                                    if needleStyle == needle.rawValue {
                                        Label(needle.displayName, systemImage: "checkmark")
                                    } else {
                                        Label(needle.displayName, systemImage: needle.icon)
                                    }
                                }
                            }
                        }

                        Divider()

                        Button {
                            showCustomizationSheet = true
                        } label: {
                            Label("More Settings...", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel("Compass Options")

                    Button {
                        recalculateLocationAndQibla()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(.degrees(isRecalculating ? 360 : 0))
                            .animation(isRecalculating ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isRecalculating)
                    }
                    .disabled(isRecalculating)
                    .accessibilityLabel("Recalibrate compass")
                }
            }
            .sheet(isPresented: $showCustomizationSheet) {
                QiblaCustomizationSheet()
            }
            .onAppear {
                qiblaViewActive = true
                qiblaManager.startUpdatingHeading()
                locationManager.requestLocation()
                let lat = locationManager.latitude != 0 ? locationManager.latitude : QiblaManager.kaabaLatitude
                let lon = locationManager.longitude != 0 ? locationManager.longitude : QiblaManager.kaabaLongitude
                qiblaManager.recalculateQibla(latitude: lat, longitude: lon)
            }
            .onDisappear {
                qiblaViewActive = false
                hasVibrated = false
                qiblaManager.stopUpdatingHeading()
            }
            .onChange(of: locationManager.latitude) { _, newLat in
                if newLat != 0 {
                    qiblaManager.calculateQibla(latitude: newLat, longitude: locationManager.longitude)
                }
            }
            .onChange(of: locationManager.longitude) { _, newLon in
                if newLon != 0 {
                    qiblaManager.calculateQibla(latitude: locationManager.latitude, longitude: newLon)
                }
            }
            .onChange(of: isAligned) { _, aligned in
                if aligned && !hasVibrated && qiblaViewActive {
                    hasVibrated = true
                    playAlignmentHaptic()
                } else if !aligned {
                    hasVibrated = false
                }
            }
        }
    }
}

// MARK: - Simple Direction Banner (Locked Height - Never Jumps Up & Down)

struct SimpleDirectionBanner: View {
    let isAligned: Bool
    let offset: Double
    let accentColor: Color

    private var degreesToTurn: Int {
        Int(abs(offset).rounded())
    }

    private var isTurnRight: Bool {
        offset > 0
    }

    var body: some View {
        HStack(spacing: 12) {
            if isAligned {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(.green)

                Text("Facing the Kaaba")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)

                Spacer()

                Image(systemName: "cube.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            } else {
                Image(systemName: isTurnRight ? "arrow.turn.up.right" : "arrow.turn.up.left")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)

                Text(isTurnRight ? "Turn \(degreesToTurn)° Right" : "Turn \(degreesToTurn)° Left")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Spacer()

                Text("Align with Kaaba")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isAligned ? Color.green.opacity(0.14) : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isAligned ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.15), value: isAligned)
    }
}
