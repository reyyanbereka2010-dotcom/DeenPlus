//
//  SettingsView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/16/26.
//

import SwiftUI
import CoreLocation
import Combine
import MapKit

struct SettingsView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var prayerManager: PrayerManager
    @ObservedObject private var iconManager = AppIconManager.shared

    @AppStorage("calculationMethod") private var calculationMethod: Int = 2
    @AppStorage("asrCalculationMethod") private var asrCalculationMethod: Int = 0
    @AppStorage("manualLatitude") private var manualLatitude: Double = 0.0
    @AppStorage("manualLongitude") private var manualLongitude: Double = 0.0
    @AppStorage("useManualLocation") private var useManualLocation: Bool = false
    @AppStorage("manualLocationName") private var manualLocationName: String = ""

    @AppStorage("appTheme") private var appTheme: String = "System"
    @AppStorage("appAccentColor") private var appAccentColor: String = "emerald"
    @AppStorage("menuBarStyle") private var menuBarStyle: String = "pill"

    @State private var showLocationSearch = false

    private var accent: Color {
        AppAccentColor(rawValue: appAccentColor)?.color ?? .green
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Location & Calculation Settings
                Section("Location & Prayer Calculations") {
                    HStack(spacing: 14) {
                        SettingsRowBadge(icon: "location.fill", color: .blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Location")
                                .font(.body)
                                .fontWeight(.medium)

                            Text(useManualLocation ? manualLocationName : (locationManager.city.isEmpty ? "Locating..." : locationManager.city))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            triggerSelectionHaptic()
                            showLocationSearch = true
                        } label: {
                            Text("Change")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(accent)
                        }
                    }

                    Picker(selection: $calculationMethod) {
                        Text("ISNA (North America)").tag(2)
                        Text("MWL (Muslim World League)").tag(3)
                        Text("Egyptian General Authority").tag(5)
                        Text("Umm Al-Qura (Makkah)").tag(4)
                        Text("Karachi (Hanafi)").tag(1)
                        Text("Dubai / Gulf Region").tag(8)
                        Text("Moonsighting Committee").tag(7)
                        Text("Tehran (Geophysics Institute)").tag(7)
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "function", color: .indigo)
                            Text("Calculation Method")
                        }
                    }
                    .onChange(of: calculationMethod) { _, _ in
                        triggerSelectionHaptic()
                        prayerManager.fetchPrayerTimes(latitude: locationManager.latitude, longitude: locationManager.longitude)
                    }

                    Picker(selection: $asrCalculationMethod) {
                        Text("Shafi / Hanbali / Maliki (Standard)").tag(0)
                        Text("Hanafi (Later Asr)").tag(1)
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "sun.haze.fill", color: .orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Asr Calculation")
                                Text("Juristic method for Asr time")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onChange(of: asrCalculationMethod) { _, _ in
                        triggerSelectionHaptic()
                        prayerManager.fetchPrayerTimes(latitude: locationManager.latitude, longitude: locationManager.longitude)
                    }
                }

                // MARK: - Appearance & Customization
                Section("Appearance & Icons") {
                    NavigationLink {
                        AppIconSelectionView()
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "app.gift.fill", color: .indigo)
                            Text("App Icon")
                            Spacer()
                            Text(iconManager.selectedOption.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "paintbrush.fill", color: .purple)
                            Text("Theme & Styling")
                        }
                    }

                    // Direct Accent Color Row
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "paintpalette.fill", color: .pink)
                            Text("Accent Color")
                        }

                        HStack(spacing: 12) {
                            ForEach(AppAccentColor.allCases) { item in
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: appAccentColor == item.rawValue ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        triggerSelectionHaptic()
                                        appAccentColor = item.rawValue
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.leading, 42)
                    }

                    Picker(selection: $appTheme) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "circle.lefthalf.filled", color: .blue)
                            Text("Color Scheme")
                        }
                    }

                    Picker(selection: $menuBarStyle) {
                        Text("Modern Pill").tag("pill")
                        Text("Floating Capsule").tag("floating")
                        Text("Frosted Glass").tag("glass")
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "dock.rectangle", color: .teal)
                            Text("Navigation Menu Style")
                        }
                    }
                }

                // MARK: - Notifications & Sound
                Section("Notifications & Athan Alerts") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "bell.badge.fill", color: .red)
                            Text("Prayer Alerts & Sounds")
                            Spacer()
                            Text("Custom Athan")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Quran & Audio Settings
                Section("Quran & Translation Audio") {
                    NavigationLink {
                        RecitationSettingsView()
                    } label: {
                        HStack(spacing: 14) {
                            SettingsRowBadge(icon: "speaker.wave.3.fill", color: .green)
                            Text("Reciter & Translation Voices")
                        }
                    }
                }

                // MARK: - About & Legal
                Section("About Deen+") {
                    HStack(spacing: 14) {
                        SettingsRowBadge(icon: "info.circle.fill", color: .gray)
                        Text("Version")
                        Spacer()
                        Text("1.0 (19)")
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 14) {
                        SettingsRowBadge(icon: "shield.checkerboard", color: .emeraldGreen)
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .tint(accent)
            .sheet(isPresented: $showLocationSearch) {
                LocationSearchView(isPresented: $showLocationSearch)
                    .environmentObject(locationManager)
                    .environmentObject(prayerManager)
            }
        }
    }

    private func triggerSelectionHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Color Extension for Badge

private extension Color {
    static let emeraldGreen = Color(red: 0.05, green: 0.65, blue: 0.45)
}

// MARK: - Settings Row Badge Component

struct SettingsRowBadge: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .frame(width: 28, height: 28)

            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Location Search Sheet

struct LocationSearchView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var prayerManager: PrayerManager
    @Binding var isPresented: Bool

    @State private var searchQuery = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var searchCompleter = MKLocalSearchCompleter()
    @StateObject private var completerDelegate = LocationSearchCompleterDelegate()

    @AppStorage("manualLatitude") private var manualLatitude: Double = 0.0
    @AppStorage("manualLongitude") private var manualLongitude: Double = 0.0
    @AppStorage("useManualLocation") private var useManualLocation: Bool = false
    @AppStorage("manualLocationName") private var manualLocationName: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                // Auto Location Button
                Button {
                    useManualLocation = false
                    locationManager.requestLocation()
                    prayerManager.fetchPrayerTimes(latitude: locationManager.latitude, longitude: locationManager.longitude)
                    isPresented = false
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use Current GPS Location")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text("Automatically detect city & coordinates")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if !useManualLocation {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal)
                .padding(.top)

                // Search Results List
                List(completerDelegate.results, id: \.self) { result in
                    Button {
                        selectLocation(result: result)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)

                            Text(result.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            .searchable(text: $searchQuery, prompt: "Search city or location")
            .onChange(of: searchQuery) { _, newValue in
                completerDelegate.completer.queryFragment = newValue
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func selectLocation(result: MKLocalSearchCompletion) {
        let req = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: req)
        search.start { response, error in
            guard let item = response?.mapItems.first else { return }
            let coord = item.placemark.coordinate
            manualLatitude = coord.latitude
            manualLongitude = coord.longitude
            useManualLocation = true
            manualLocationName = result.title

            locationManager.latitude = coord.latitude
            locationManager.longitude = coord.longitude
            locationManager.city = result.title

            prayerManager.fetchPrayerTimes(latitude: coord.latitude, longitude: coord.longitude)
            isPresented = false
        }
    }
}

class LocationSearchCompleterDelegate: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        #if DEBUG
        print("Location completer error:", error)
        #endif
    }
}
