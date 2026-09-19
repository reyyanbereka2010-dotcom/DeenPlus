//
//  OnboardingSheetView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/9/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct OnboardingSheetView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var prayerManager: PrayerManager

    @AppStorage("hasCompletedOnboardingV1") private var hasCompletedOnboarding: Bool = false
    @AppStorage("appAccentColor") private var appAccentColor: String = "emerald"
    @AppStorage("selectedQuranReciter") private var selectedQuranReciter: String = Reciter.alafasy.rawValue
    @AppStorage("prayerNotificationsEnabled") private var prayerNotificationsEnabled: Bool = false

    @State private var currentStep: Int = 0
    @State private var locationGranted: Bool = false
    @State private var notificationsGranted: Bool = false

    private var accent: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if currentStep == 0 {
                    welcomeStepView
                } else {
                    setupStepView
                }

                Spacer(minLength: 20)

                // Bottom Action Button
                VStack(spacing: 12) {
                    Button {
                        triggerHaptic()
                        if currentStep == 0 {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                currentStep = 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentStep == 0 ? "Continue" : "Get Started")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: accent.opacity(0.35), radius: 8, y: 3)
                    }

                    if currentStep == 1 {
                        Button("Skip for Now") {
                            triggerHaptic()
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if currentStep == 0 {
                        Button("Skip") {
                            triggerHaptic()
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Step 1: Welcome & Highlights

    private var welcomeStepView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Brand Header
                VStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color(red: 0.1, green: 0.5, blue: 0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 88, height: 88)
                            .shadow(color: Color.green.opacity(0.3), radius: 14, y: 6)

                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 24)

                    VStack(spacing: 6) {
                        Text("Welcome to Deen+")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Your Daily Islamic Companion")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }

                // Core Feature Highlights
                VStack(spacing: 18) {
                    OnboardingFeatureRow(
                        icon: "clock.fill",
                        color: .green,
                        title: "Accurate Prayer Times",
                        description: "Offline astronomical calculations with customizable notifications and Tahajjud vigil tracking."
                    )

                    OnboardingFeatureRow(
                        icon: "book.fill",
                        color: .teal,
                        title: "Holy Quran Reader",
                        description: "Full 114 Surahs with Uthmanic script, studio audio recitations, and interactive Now Playing bar."
                    )

                    OnboardingFeatureRow(
                        icon: "location.north.fill",
                        color: .orange,
                        title: "Precision Qibla Finder",
                        description: "Real-time haptic compass pointing directly towards the Holy Kaaba in Makkah."
                    )

                    OnboardingFeatureRow(
                        icon: "hands.sparkles.fill",
                        color: .purple,
                        title: "Daily Duas & Supplications",
                        description: "Authentic supplications with full offline storage and automatic background synchronization."
                    )
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Step 2: Permissions & Quick Preferences

    private var setupStepView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Quick Setup")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.top, 20)

                    Text("Personalize your experience")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                // Permissions Section
                VStack(spacing: 14) {
                    // Location Card
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.blue)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Location Access")
                                .font(.headline)
                            Text("For automatic local prayer calculations")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            triggerHaptic()
                            locationManager.requestLocation()
                            locationGranted = true
                        } label: {
                            Text(locationGranted || locationManager.latitude != 0 ? "Allowed" : "Allow")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(locationGranted || locationManager.latitude != 0 ? Color.green.opacity(0.18) : Color.blue)
                                .foregroundStyle(locationGranted || locationManager.latitude != 0 ? Color.green : Color.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Notifications Card
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.red)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Adhan Notifications")
                                .font(.headline)
                            Text("Receive timely reminders for each prayer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            triggerHaptic()
                            NotificationManager.shared.requestPermission()
                            prayerNotificationsEnabled = true
                            notificationsGranted = true
                        } label: {
                            Text(notificationsGranted || prayerNotificationsEnabled ? "Enabled" : "Enable")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(notificationsGranted || prayerNotificationsEnabled ? Color.green.opacity(0.18) : Color.red)
                                .foregroundStyle(notificationsGranted || prayerNotificationsEnabled ? Color.green : Color.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 20)

                // Quick Preferences Section
                VStack(alignment: .leading, spacing: 14) {
                    Text("Reciter")
                        .font(.headline)
                        .padding(.horizontal, 24)

                    Picker("Sheikh", selection: $selectedQuranReciter) {
                        ForEach(Reciter.allCases) { reciter in
                            Text(reciter.displayName).tag(reciter.rawValue)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 110)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        isPresented = false
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
    }
}

// MARK: - Onboarding Feature Row Component

struct OnboardingFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
