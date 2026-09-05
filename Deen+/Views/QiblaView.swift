//
//  QiblaView.swift
//  MuslimPrayer
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI
import CoreHaptics
#if canImport(UIKit)
import UIKit
#endif

struct QiblaView: View {
    
    @State private var qiblaViewActive = false
    @State private var hasVibrated = false
    @EnvironmentObject var qiblaManager: QiblaManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var hapticsEngine: CHHapticEngine?
    @State private var isRecalculating = false
    @State private var wasRecentlyReset = false
    @State private var calibrationSpin: Double = 0
    
    private func playQiblaReachedHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            if hapticsEngine == nil {
                hapticsEngine = try CHHapticEngine()
                try hapticsEngine?.start()
            }
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity], relativeTime: 0)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticsEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
        }
    }

    private func recalculateLocationAndQibla() {
        #if canImport(UIKit)
        let notify = UINotificationFeedbackGenerator()
        notify.notificationOccurred(.success)
        #endif
        
        isRecalculating = true
        wasRecentlyReset = true
        
        // Visually animate compass needle around in a dynamic calibration sweep
        withAnimation(.spring(response: 0.75, dampingFraction: 0.65)) {
            calibrationSpin += 360
        }
        
        locationManager.recalculateLocation()
        
        let lat = locationManager.latitude != 0 ? locationManager.latitude : 21.4225
        let lon = locationManager.longitude != 0 ? locationManager.longitude : 39.8262
        qiblaManager.recalculateQibla(latitude: lat, longitude: lon)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isRecalculating = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                wasRecentlyReset = false
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Title Header with Reset / Recalculate
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Qibla Finder")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                
                                Text("Point your phone towards the Kaaba")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                recalculateLocationAndQibla()
                            } label: {
                                HStack(spacing: 6) {
                                    if wasRecentlyReset && !isRecalculating {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text("Calibrated")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .rotationEffect(.degrees(isRecalculating ? 360 : 0))
                                            .animation(isRecalculating ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isRecalculating)
                                        Text(isRecalculating ? "Calibrating" : "Reset")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(wasRecentlyReset ? Color.green.opacity(0.18) : Color.green.opacity(0.12))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                            }
                            .disabled(isRecalculating)
                            .accessibilityLabel("Recalculate Qibla and reset GPS location")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // Recalibrated Feedback Toast
                        if wasRecentlyReset {
                            HStack(spacing: 8) {
                                Image(systemName: isRecalculating ? "sparkles" : "checkmark.circle.fill")
                                    .font(.footnote)
                                    .foregroundStyle(.green)
                                Text(isRecalculating ? "Recalibrating GPS & Compass Sensors..." : "Compass & GPS Location Recalibrated ✓")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                        
                        // Main Compass Arrow Card
                        VStack(spacing: 22) {
                            ZStack {
                                Circle()
                                    .fill(qiblaManager.isFacingQibla ? Color.green.opacity(0.15) : Color.green.opacity(0.05))
                                    .frame(width: 220, height: 220)
                                
                                Image(systemName: "location.north.fill")
                                    .font(.system(size: 110, weight: .bold))
                                    .rotationEffect(.degrees(qiblaManager.displayedRotation + calibrationSpin))
                                    .foregroundStyle(qiblaManager.isFacingQibla ? .green : .primary)
                                    .shadow(color: qiblaManager.isFacingQibla ? .green.opacity(0.4) : .black.opacity(0.1), radius: 10)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: qiblaManager.displayedRotation + calibrationSpin)
                                    .accessibilityLabel(qiblaManager.isFacingQibla ? "Facing Qibla" : "Turn towards Qibla")
                                    .accessibilityValue("Direction: \(Int(qiblaManager.qiblaDirection)) degrees")
                            }
                            .padding(.top, 10)
                            
                            VStack(spacing: 6) {
                                Text("Qibla Angle")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .textCase(.uppercase)
                                    .foregroundStyle(.secondary)
                                
                                Text("\(Int(round(qiblaManager.qiblaDirection)))°")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundStyle(qiblaManager.isFacingQibla ? .green : .primary)
                            }
                            
                            // Facing Status Badge
                            if qiblaManager.isFacingQibla {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Facing Qibla")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.green)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.15))
                                .clipShape(Capsule())
                            } else {
                                Text("Turn phone until the arrow turns green")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Color(.tertiarySystemGroupedBackground))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 28)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 20)
                        
                        // Location Info Card
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundStyle(.green)
                                Text("Your Location")
                                    .font(.headline)
                                Spacer()
                                if locationManager.latitude != 0 {
                                    Text(locationManager.city)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                } else {
                                    ProgressView()
                                        .onAppear {
                                            locationManager.requestLocation()
                                        }
                                }
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Status")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                                    Text("Location Access Denied")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.red)
                                } else {
                                    Text(locationManager.latitude != 0 ? "Location Detected ✓" : "Searching...")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(locationManager.latitude != 0 ? .green : .orange)
                                }
                            }
                        }
                        .padding(18)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onChange(of: qiblaManager.isFacingQibla) { facing in
            if facing && qiblaViewActive && !hasVibrated {
                playQiblaReachedHaptic()
                hasVibrated = true
            }
            if !facing {
                hasVibrated = false
            }
        }
        .onChange(of: locationManager.latitude) { newLat in
            if newLat != 0 {
                qiblaManager.calculateQibla(
                    latitude: newLat,
                    longitude: locationManager.longitude
                )
            }
        }
        .onAppear {
            qiblaViewActive = true
            if locationManager.latitude != 0 {
                qiblaManager.calculateQibla(
                    latitude: locationManager.latitude,
                    longitude: locationManager.longitude
                )
            } else {
                qiblaManager.calculateQibla(latitude: 21.4225, longitude: 39.8262)
            }
        }
        .onDisappear {
            qiblaViewActive = false
            hasVibrated = false
            try? hapticsEngine?.stop()
            hapticsEngine = nil
        }
    }
}

#Preview {
    QiblaView()
        .environmentObject(QiblaManager())
        .environmentObject(LocationManager())
}
