//
//  QiblaCompassDials.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/12/26.
//

import SwiftUI

// MARK: - Main Interactive Compass Container

struct QiblaCompassDiscView: View {
    @ObservedObject var qiblaManager: QiblaManager
    let dialStyle: QiblaCompassDialStyle
    let needleStyle: QiblaNeedleStyle
    let showLevel: Bool
    let accentColor: Color

    private let discSize: CGFloat = 260

    var body: some View {
        ZStack {
            // 1. Ambient Glow Aura on Alignment
            if qiblaManager.isFacingQibla {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.35), accentColor.opacity(0.0)],
                            center: .center,
                            startRadius: 70,
                            endRadius: 145
                        )
                    )
                    .frame(width: discSize + 30, height: discSize + 30)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // 2. Rotating Compass Rose / Dial (Turns realistically with phone heading)
            ZStack {
                switch dialStyle {
                case .modern:
                    ModernPrecisionDial(qiblaDirection: qiblaManager.qiblaDirection, accentColor: accentColor)
                case .arabesque:
                    ArabesqueHeritageDial(qiblaDirection: qiblaManager.qiblaDirection, accentColor: accentColor)
                case .astrolabe:
                    AstrolabeNavigationalDial(qiblaDirection: qiblaManager.qiblaDirection, accentColor: accentColor)
                case .oled:
                    MinimalOLEDDial(qiblaDirection: qiblaManager.qiblaDirection, accentColor: accentColor)
                }
            }
            .frame(width: discSize, height: discSize)
            .rotationEffect(.degrees(-qiblaManager.continuousHeading))
            .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.85), value: qiblaManager.continuousHeading)

            // 3. Central Qibla Pointer / Needle (Points directly toward the Kaaba, perfectly centered)
            ZStack {
                switch needleStyle {
                case .kaaba:
                    KaabaNeedleView(isAligned: qiblaManager.isFacingQibla, accentColor: accentColor)
                case .crescent:
                    CrescentNeedleView(isAligned: qiblaManager.isFacingQibla, accentColor: accentColor)
                case .aero:
                    AeroNeedleView(isAligned: qiblaManager.isFacingQibla, accentColor: accentColor)
                case .orbital:
                    OrbitalNeedleView(isAligned: qiblaManager.isFacingQibla, accentColor: accentColor)
                }
            }
            .frame(width: discSize, height: discSize)
            .rotationEffect(.degrees(qiblaManager.continuousNeedleAngle))
            .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.85), value: qiblaManager.continuousNeedleAngle)

            // 4. Fixed Top Lubber Line / 12 O'Clock Phone Notch
            TopLubberLine(isAligned: qiblaManager.isFacingQibla, accentColor: accentColor)
                .offset(y: -(discSize / 2 + 10))

            // 5. Optional Center Tilt Bubble Level
            if showLevel {
                CompassLevelBubbleView(
                    pitch: qiblaManager.pitch,
                    roll: qiblaManager.roll,
                    isLevel: qiblaManager.isLevel,
                    accentColor: accentColor
                )
            }
        }
        .frame(width: discSize + 30, height: discSize + 30)
    }
}

// MARK: - Top Lubber Line (12 O'Clock Index)

struct TopLubberLine: View {
    let isAligned: Bool
    let accentColor: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "triangle.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(isAligned ? accentColor : Color.primary)
                .rotationEffect(.degrees(180))

            Rectangle()
                .fill(isAligned ? accentColor : Color.primary.opacity(0.8))
                .frame(width: 2.5, height: 7)
                .clipShape(RoundedRectangle(cornerRadius: 1))
        }
        .shadow(color: isAligned ? accentColor.opacity(0.6) : Color.clear, radius: 4)
    }
}

// MARK: - Modern Precision Dial

struct ModernPrecisionDial: View {
    let qiblaDirection: Double
    let accentColor: Color

    var body: some View {
        ZStack {
            // Outer Bezel Ring
            Circle()
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1.5)
                .background(Circle().fill(Color(.secondarySystemGroupedBackground)))

            // Inner Track
            Circle()
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                .frame(width: 190, height: 190)

            // Degree Ticks (Every 5°)
            ForEach(0..<72) { i in
                let deg = i * 5
                let isMajor = deg % 30 == 0
                let isCardinal = deg % 90 == 0

                Rectangle()
                    .fill(isCardinal ? Color.primary : Color.primary.opacity(isMajor ? 0.45 : 0.18))
                    .frame(width: isCardinal ? 2.2 : (isMajor ? 1.5 : 1), height: isCardinal ? 11 : (isMajor ? 7 : 4))
                    .offset(y: -118)
                    .rotationEffect(.degrees(Double(deg)))
            }

            // Cardinal Letters
            Text("N")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.92, green: 0.26, blue: 0.26))
                .offset(y: -98)

            Text("S")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .offset(y: 98)

            Text("E")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .offset(x: 98)

            Text("W")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .offset(x: -98)

            // Kaaba Direction Marker on Dial Perimeter
            VStack(spacing: 2) {
                Image(systemName: "cube.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(accentColor)
                Circle()
                    .fill(accentColor)
                    .frame(width: 4, height: 4)
            }
            .offset(y: -118)
            .rotationEffect(.degrees(qiblaDirection))
        }
        .frame(width: 250, height: 250)
    }
}

// MARK: - Islamic Heritage Arabesque Dial

struct ArabesqueHeritageDial: View {
    let qiblaDirection: Double
    let accentColor: Color

    var body: some View {
        ZStack {
            // Background Medallion
            Circle()
                .strokeBorder(Color(red: 0.85, green: 0.70, blue: 0.30).opacity(0.3), lineWidth: 2)
                .background(Circle().fill(Color(.secondarySystemGroupedBackground)))

            // 8-Pointed Star Rosette Medallion (Islamic Khatim)
            ZStack {
                Rectangle()
                    .stroke(Color(red: 0.85, green: 0.70, blue: 0.30).opacity(0.25), lineWidth: 1.2)
                    .frame(width: 125, height: 125)

                Rectangle()
                    .stroke(Color(red: 0.85, green: 0.70, blue: 0.30).opacity(0.25), lineWidth: 1.2)
                    .frame(width: 125, height: 125)
                    .rotationEffect(.degrees(45))

                Circle()
                    .stroke(Color(red: 0.85, green: 0.70, blue: 0.30).opacity(0.18), lineWidth: 1)
                    .frame(width: 125, height: 125)
            }

            // Dial Graduations (Every 15°)
            ForEach(0..<24) { i in
                let deg = i * 15
                let isCardinal = deg % 90 == 0

                Rectangle()
                    .fill(isCardinal ? Color(red: 0.90, green: 0.75, blue: 0.30) : Color.primary.opacity(0.25))
                    .frame(width: isCardinal ? 2.5 : 1.2, height: isCardinal ? 10 : 5)
                    .offset(y: -118)
                    .rotationEffect(.degrees(Double(deg)))
            }

            // Arabic / Latin Cardinal Points
            VStack(spacing: 0) {
                Text("شمال")
                    .font(.system(size: 8, weight: .bold))
                Text("N")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Color(red: 0.90, green: 0.25, blue: 0.25))
            .offset(y: -98)

            VStack(spacing: 0) {
                Text("S")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text("جنوب")
                    .font(.system(size: 8, weight: .medium))
            }
            .foregroundStyle(.primary)
            .offset(y: 98)

            HStack(spacing: 2) {
                Text("E")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text("شرق")
                    .font(.system(size: 8, weight: .medium))
            }
            .foregroundStyle(.primary)
            .offset(x: 98)

            HStack(spacing: 2) {
                Text("غرب")
                    .font(.system(size: 8, weight: .medium))
                Text("W")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.primary)
            .offset(x: -98)

            // Kaaba Direction Marker
            VStack(spacing: 2) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(red: 0.90, green: 0.75, blue: 0.30))
                Circle()
                    .fill(Color(red: 0.90, green: 0.75, blue: 0.30))
                    .frame(width: 4, height: 4)
            }
            .offset(y: -118)
            .rotationEffect(.degrees(qiblaDirection))
        }
        .frame(width: 250, height: 250)
    }
}

// MARK: - Astrolabe Navigational Dial

struct AstrolabeNavigationalDial: View {
    let qiblaDirection: Double
    let accentColor: Color

    var body: some View {
        ZStack {
            // Concentric Rings
            Circle()
                .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1.5)
                .background(Circle().fill(Color(.secondarySystemGroupedBackground)))

            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                .frame(width: 210, height: 210)

            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                .frame(width: 170, height: 170)

            Circle()
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                .frame(width: 130, height: 130)

            // Degree marks every 10°
            ForEach(0..<36) { i in
                let deg = i * 10
                let isMajor = deg % 30 == 0

                Rectangle()
                    .fill(isMajor ? Color.primary : Color.primary.opacity(0.3))
                    .frame(width: isMajor ? 1.5 : 1, height: isMajor ? 8 : 4)
                    .offset(y: -118)
                    .rotationEffect(.degrees(Double(deg)))
            }

            Text("N")
                .font(.system(size: 14, weight: .heavy, design: .serif))
                .foregroundStyle(Color.red)
                .offset(y: -98)

            Text("S")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(.primary)
                .offset(y: 98)

            Text("E")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(.primary)
                .offset(x: 98)

            Text("W")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(.primary)
                .offset(x: -98)

            // Kaaba Target
            Circle()
                .fill(accentColor)
                .frame(width: 6, height: 6)
                .offset(y: -118)
                .rotationEffect(.degrees(qiblaDirection))
        }
        .frame(width: 250, height: 250)
    }
}

// MARK: - Minimal OLED Dial

struct MinimalOLEDDial: View {
    let qiblaDirection: Double
    let accentColor: Color

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)

            // Cardinal Notches Only
            ForEach(0..<4) { i in
                Rectangle()
                    .fill(i == 0 ? Color.red : Color.primary.opacity(0.5))
                    .frame(width: 2, height: 12)
                    .offset(y: -118)
                    .rotationEffect(.degrees(Double(i * 90)))
            }

            Text("N")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(Color.red)
                .offset(y: -98)

            Text("S")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .offset(y: 98)

            Text("E")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .offset(x: 98)

            Text("W")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .offset(x: -98)

            // Kaaba Notch
            Rectangle()
                .fill(accentColor)
                .frame(width: 3, height: 14)
                .offset(y: -118)
                .rotationEffect(.degrees(qiblaDirection))
        }
        .frame(width: 250, height: 250)
    }
}

// MARK: - Needle Styles (All Perfectly Centered at (0, 0) - Zero Wobble)

// 1. Holy Kaaba Needle
struct KaabaNeedleView: View {
    let isAligned: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            // Forward Pointer (Extends Upwards from Center Pivot to y: -94)
            VStack(spacing: 0) {
                // Kaaba Cube Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 3.5)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                        .frame(width: 24, height: 24)
                        .shadow(color: isAligned ? accentColor.opacity(0.8) : Color.black.opacity(0.35), radius: 6)

                    // Gold Kiswah Band
                    Rectangle()
                        .fill(Color(red: 0.95, green: 0.82, blue: 0.35))
                        .frame(width: 24, height: 3.5)
                        .offset(y: -3)

                    Image(systemName: "location.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(isAligned ? accentColor : Color.white)
                        .offset(y: 3)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 3.5)
                        .stroke(isAligned ? accentColor : Color(red: 0.85, green: 0.70, blue: 0.30), lineWidth: 1.5)
                )

                // Shaft
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [isAligned ? accentColor : Color.primary, Color.primary.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3.5, height: 58)
            }
            .offset(y: -49) // Top edge at y = -91, bottom connects to center circle

            // Center Pivot Circle (Exact Center (0, 0))
            Circle()
                .fill(isAligned ? accentColor : Color.primary)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))

            // Counterweight Tail (Extends Downwards from Center Pivot to y: +38)
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.primary.opacity(0.25))
                    .frame(width: 2, height: 22)

                Circle()
                    .fill(Color.primary.opacity(0.35))
                    .frame(width: 8, height: 8)
            }
            .offset(y: 19) // Top connects to center circle, bottom at y = +34
        }
        .frame(width: 250, height: 250)
    }
}

// 2. Golden Crescent Needle
struct CrescentNeedleView: View {
    let isAligned: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            // Forward Pointer with Golden Crescent
            VStack(spacing: 0) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: isAligned ? [accentColor, accentColor.opacity(0.8)] : [Color(red: 0.95, green: 0.82, blue: 0.35), Color(red: 0.75, green: 0.55, blue: 0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: (isAligned ? accentColor : Color.yellow).opacity(0.5), radius: 6)
                    .frame(height: 28)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [isAligned ? accentColor : Color(red: 0.85, green: 0.70, blue: 0.30), Color.primary.opacity(0.25)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: 54)
            }
            .offset(y: -48)

            // Center Pivot Circle
            Circle()
                .fill(isAligned ? accentColor : Color(red: 0.85, green: 0.70, blue: 0.30))
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))

            // Tail
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.primary.opacity(0.2))
                    .frame(width: 2, height: 22)

                Circle()
                    .fill(Color.primary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            .offset(y: 18)
        }
        .frame(width: 250, height: 250)
    }
}

// 3. Precision Aero Needle
struct AeroNeedleView: View {
    let isAligned: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            // Forward Arrow
            VStack(spacing: 0) {
                Path { path in
                    path.move(to: CGPoint(x: 10, y: 0))
                    path.addLine(to: CGPoint(x: 20, y: 70))
                    path.addLine(to: CGPoint(x: 10, y: 60))
                    path.addLine(to: CGPoint(x: 0, y: 70))
                    path.closeSubpath()
                }
                .fill(isAligned ? accentColor : Color.green)
                .frame(width: 20, height: 70)
                .shadow(color: (isAligned ? accentColor : Color.green).opacity(0.4), radius: 5)
            }
            .offset(y: -42)

            // Reverse Tail
            VStack(spacing: 0) {
                Path { path in
                    path.move(to: CGPoint(x: 10, y: 40))
                    path.addLine(to: CGPoint(x: 18, y: 0))
                    path.addLine(to: CGPoint(x: 10, y: 8))
                    path.addLine(to: CGPoint(x: 2, y: 0))
                    path.closeSubpath()
                }
                .fill(Color.secondary.opacity(0.45))
                .frame(width: 20, height: 40)
            }
            .offset(y: 26)

            // Center Pin
            Circle()
                .fill(Color.primary)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
        }
        .frame(width: 250, height: 250)
    }
}

// 4. Orbital Bezel Needle
struct OrbitalNeedleView: View {
    let isAligned: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            // Laser Guide Beam
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [isAligned ? accentColor : Color.primary.opacity(0.7), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: 72)
                .offset(y: -42)

            // Orbital Kaaba Pip
            Circle()
                .fill(isAligned ? accentColor : Color.primary)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 2)
                )
                .shadow(color: (isAligned ? accentColor : Color.primary).opacity(0.6), radius: 6)
                .offset(y: -88)

            // Center Pin
            Circle()
                .fill(isAligned ? accentColor : Color.primary)
                .frame(width: 10, height: 10)
        }
        .frame(width: 250, height: 250)
    }
}

// MARK: - Center Tilt & Bubble Level Crosshair (Optional in Custom Settings)

struct CompassLevelBubbleView: View {
    let pitch: Double
    let roll: Double
    let isLevel: Bool
    let accentColor: Color

    private var clampedX: CGFloat {
        CGFloat(max(-18.0, min(18.0, roll * 1.2)))
    }

    private var clampedY: CGFloat {
        CGFloat(max(-18.0, min(18.0, pitch * 1.2)))
    }

    var body: some View {
        ZStack {
            // Reticle
            Circle()
                .stroke(isLevel ? accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
                .frame(width: 24, height: 24)

            // Bubble
            Circle()
                .fill(isLevel ? accentColor : Color.secondary.opacity(0.5))
                .frame(width: 10, height: 10)
                .offset(x: clampedX, y: clampedY)
                .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.8), value: clampedX)
                .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.8), value: clampedY)
        }
    }
}
