//
//  AppLaunchSplashView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/9/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AppLaunchSplashView: View {
    @Binding var isAnimating: Bool
    @State private var scale: CGFloat = 0.75
    @State private var opacity: Double = 0.0
    @State private var haloScale: CGFloat = 0.8
    @State private var haloOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Elegant Deep Background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    // Soft Ethereal Glow
                    Circle()
                        .fill(Color.green.opacity(0.22))
                        .frame(width: 160, height: 160)
                        .scaleEffect(haloScale)
                        .opacity(haloOpacity)
                        .blur(radius: 20)

                    // App Emblem Squircle
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color(red: 0.1, green: 0.55, blue: 0.32)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 104, height: 104)
                        .shadow(color: Color.green.opacity(0.35), radius: 20, x: 0, y: 8)

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(scale)
                .opacity(opacity)

                VStack(spacing: 4) {
                    Text("Deen+")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                        .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 18))
                        .foregroundStyle(.green)
                }
                .opacity(opacity)
            }
        }
        .onTapGesture {
            dismissSplash()
        }
        .onAppear {
            #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }

            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                haloScale = 1.25
                haloOpacity = 0.55
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                dismissSplash()
            }
        }
    }

    private func dismissSplash() {
        withAnimation(.easeInOut(duration: 0.35)) {
            isAnimating = false
        }
    }
}
