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

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Title Header
                        VStack(spacing: 6) {
                            Text("Qibla Finder")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            
                            Text("Point your phone towards the Kaaba")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 12)
                        
                        // Main Compass Arrow Card
                        VStack(spacing: 22) {
                            ZStack {
                                Circle()
                                    .fill(qiblaManager.isFacingQibla ? Color.green.opacity(0.15) : Color.green.opacity(0.05))
                                    .frame(width: 220, height: 220)
                                
                                Image(systemName: "location.north.fill")
                                    .font(.system(size: 110, weight: .bold))
                                    .rotationEffect(.degrees(qiblaManager.displayedRotation))
                                    .foregroundStyle(qiblaManager.isFacingQibla ? .green : .primary)
                                    .shadow(color: qiblaManager.isFacingQibla ? .green.opacity(0.4) : .black.opacity(0.1), radius: 10)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: qiblaManager.displayedRotation)
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
                                Text(locationManager.latitude != 0 ? "Location Detected ✓" : "Searching...")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(locationManager.latitude != 0 ? .green : .orange)
                            }
                        }
                        .padding(18)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
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
