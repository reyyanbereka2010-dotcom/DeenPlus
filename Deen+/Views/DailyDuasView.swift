//
//  DailyDuasView.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/5/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct DailyDuasView: View {

    @ObservedObject private var duaManager = DuaManager.shared
    @State private var selectedCategory: DuaCategory = .all
    @State private var searchText: String = ""
    @State private var showResetAlert: Bool = false
    @AppStorage("saved_dua_counts_v1") private var rawDuaCounts: String = "{}"
    @AppStorage("saved_favorite_duas_v1") private var rawFavorites: String = "[]"

    private var duaCounts: [String: Int] {
        get {
            guard let data = rawDuaCounts.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
                return [:]
            }
            return dict
        }
    }

    private var favoriteIds: Set<String> {
        get {
            guard let data = rawFavorites.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return Set(array)
        }
    }

    private func isFavorite(_ id: String) -> Bool {
        favoriteIds.contains(id)
    }

    private func toggleFavorite(_ id: String) {
        var current = favoriteIds
        if current.contains(id) {
            current.remove(id)
        } else {
            current.insert(id)
        }
        if let encoded = try? JSONEncoder().encode(Array(current)),
           let str = String(data: encoded, encoding: .utf8) {
            rawFavorites = str
        }
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    private func setDuaCount(_ count: Int, for id: String) {
        var current = duaCounts
        current[id] = count
        if let encoded = try? JSONEncoder().encode(current),
           let str = String(data: encoded, encoding: .utf8) {
            rawDuaCounts = str
        }
    }

    private func resetAllCounts() {
        rawDuaCounts = "{}"
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    private func filteredDuas(favorites: Set<String>) -> [DuaItem] {
        duaManager.duas.filter { dua in
            // Category filter
            if selectedCategory == .favorites {
                guard favorites.contains(dua.id) else { return false }
            } else if selectedCategory != .all && dua.category != selectedCategory {
                return false
            }

            // Search filter
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if q.isEmpty { return true }
            return dua.title.lowercased().contains(q) ||
                   dua.transliteration.lowercased().contains(q) ||
                   dua.translation.lowercased().contains(q) ||
                   dua.arabic.contains(q) ||
                   dua.reference.lowercased().contains(q)
        }
    }

    var body: some View {
        let cachedFavorites = favoriteIds
        let cachedCounts = duaCounts
        let items = filteredDuas(favorites: cachedFavorites)

        NavigationStack {
            List {
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(DuaCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowBackground(Color.clear)
                }

                if items.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: selectedCategory == .favorites ? "star.slash" : "magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text(selectedCategory == .favorites ? "No Saved Duas" : "No Duas Found")
                                .font(.headline)
                            Text(selectedCategory == .favorites ? "Star any dua to quickly access it here." : "No supplications match '\(searchText)'")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 30)
                    }
                } else {
                    ForEach(items) { dua in
                        DuaCardRow(
                            dua: dua,
                            count: cachedCounts[dua.id] ?? 0,
                            isFavorited: cachedFavorites.contains(dua.id),
                            onToggleFavorite: {
                                toggleFavorite(dua.id)
                            },
                            onIncrement: {
                                let cur = duaCounts[dua.id] ?? 0
                                if cur < dua.targetCount {
                                    let next = cur + 1
                                    setDuaCount(next, for: dua.id)
                                    #if canImport(UIKit)
                                    if next >= dua.targetCount {
                                        let notif = UINotificationFeedbackGenerator()
                                        notif.notificationOccurred(.success)
                                    } else {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                                    #endif
                                } else {
                                    #if canImport(UIKit)
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    #endif
                                }
                            },
                            onReset: {
                                setDuaCount(0, for: dua.id)
                                #if canImport(UIKit)
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                #endif
                            }
                        )
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search supplications & translations...")
            .navigationTitle("Daily Duas")
            .safeAreaPadding(.bottom, 60)
            .refreshable {
                await duaManager.syncOnlineDuas()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Connection Status Pill
                        HStack(spacing: 4) {
                            Circle()
                                .fill(duaManager.isConnected ? (duaManager.isCellular ? Color.orange : Color.green) : Color.gray)
                                .frame(width: 7, height: 7)

                            Text(duaManager.isConnected ? (duaManager.isCellular ? "Cellular" : "Online") : "Offline")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(duaManager.isConnected ? Color.primary : Color.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.12), in: Capsule())

                        Menu {
                            Button {
                                Task {
                                    await duaManager.syncOnlineDuas()
                                }
                            } label: {
                                Label("Sync Duas Online", systemImage: "arrow.triangle.2.circlepath")
                            }

                            Button(role: .destructive) {
                                showResetAlert = true
                            } label: {
                                Label("Reset All Counts", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Reset All Counts?", isPresented: $showResetAlert) {
                Button("Reset All", role: .destructive) {
                    resetAllCounts()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset your recitation progress for all daily supplications.")
            }
        }
    }
}

struct DuaCardRow: View {
    let dua: DuaItem
    let count: Int
    let isFavorited: Bool
    let onToggleFavorite: () -> Void
    let onIncrement: () -> Void
    let onReset: () -> Void

    private var isCompleted: Bool {
        count >= dua.targetCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dua.title)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(dua.reference)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorited ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundStyle(isFavorited ? Color.yellow : Color.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorited ? "Remove from favorites" : "Add to favorites")
            }

            // Arabic Text
            Text(dua.arabic)
                .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 22))
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(Color.green)

            // Transliteration
            Text(dua.transliteration)
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)

            // Translation
            Text(dua.translation)
                .font(.subheadline)
                .foregroundStyle(.primary)

            // Counter Button Bar
            HStack {
                Button(action: onIncrement) {
                    HStack(spacing: 8) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "hand.tap.fill")
                        Text(isCompleted ? "Completed" : "Count: \(count)/\(dua.targetCount)")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isCompleted ? Color.green : Color.green.opacity(0.15))
                    .foregroundStyle(isCompleted ? Color.white : Color.green)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if count > 0 {
                    Button(action: onReset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reset counter")
                }

                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 6)
    }
}
