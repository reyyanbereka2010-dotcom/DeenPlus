//
//  BackgroundTaskManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/9/26.
//

import Foundation
import BackgroundTasks
import UserNotifications
import CoreLocation

final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    static let refreshPrayersTaskId = "com.deenplus.refreshPrayers"
    static let syncDuasTaskId = "com.deenplus.syncDuas"

    private init() {}

    // MARK: - Registration (Must be invoked before app finishes launching)

    func registerBackgroundTasks() {
        // 1. Prayer Times & Notifications Refresh Task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshPrayersTaskId,
            using: nil
        ) { [weak self] task in
            guard let appRefreshTask = task as? BGAppRefreshTask else { return }
            self?.handlePrayerRefresh(task: appRefreshTask)
        }

        // 2. Duas Network Synchronization Processing Task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.syncDuasTaskId,
            using: nil
        ) { [weak self] task in
            guard let processingTask = task as? BGProcessingTask else { return }
            self?.handleDuaSync(task: processingTask)
        }
    }

    // MARK: - Scheduling

    func scheduleAllTasks() {
        schedulePrayerRefresh()
        scheduleDuaSync()
    }

    func schedulePrayerRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshPrayersTaskId)
        // Refresh every 4 hours to keep prayer notifications fresh
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 3600)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Silently handle if background tasks are restricted
        }
    }

    func scheduleDuaSync() {
        let request = BGProcessingTaskRequest(identifier: Self.syncDuasTaskId)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        // Sync once or twice a day in background
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 3600)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Silently handle if background tasks are restricted
        }
    }

    // MARK: - Task Handlers

    private func handlePrayerRefresh(task: BGAppRefreshTask) {
        // Reschedule next background occurrence
        schedulePrayerRefresh()

        let workTask = Task { @MainActor in
            let defaults = UserDefaults.standard
            let savedLat = defaults.double(forKey: "cached_location_lat")
            let savedLon = defaults.double(forKey: "cached_location_lon")

            let activeLat = savedLat != 0 ? savedLat : 21.4225
            let activeLon = savedLon != 0 ? savedLon : 39.8262

            let isAuto = defaults.object(forKey: "prayer_auto_detect_settings") as? Bool ?? true
            let cachedCountry = defaults.string(forKey: "cached_location_country_code")

            let method: String
            let juristic: PrayTimes.AdjustmentMethod
            let highLats: PrayTimes.ElavationMethod

            if isAuto {
                let auto = PrayerAutoSettings.autoDetect(
                    countryCode: cachedCountry,
                    latitude: activeLat,
                    longitude: activeLon
                )
                method = auto.method
                juristic = auto.juristic
                highLats = auto.highLats
            } else {
                let savedMethod = defaults.string(forKey: "prayer_calc_method") ?? "ISNA"
                let savedJuristicRaw = defaults.string(forKey: "prayer_juristic_method") ?? PrayTimes.AdjustmentMethod.Standard.rawValue
                let savedHighLatsRaw = defaults.string(forKey: "prayer_high_lats_method") ?? PrayTimes.ElavationMethod.NightMiddle.rawValue

                method = savedMethod
                juristic = PrayTimes.AdjustmentMethod(rawValue: savedJuristicRaw) ?? .Standard
                highLats = PrayTimes.ElavationMethod(rawValue: savedHighLatsRaw) ?? .NightMiddle
            }

            let pt = PrayTimes(method: method, juristic: juristic, highLats: highLats)
            let updatedTimes = pt.calculate(for: [activeLat, activeLon], date: Date())
            NotificationManager.shared.schedulePrayerNotifications(prayerTimes: updatedTimes)

            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            workTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    private func handleDuaSync(task: BGProcessingTask) {
        scheduleDuaSync()

        let syncTask = Task { @MainActor in
            await DuaManager.shared.syncOnlineDuas()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            syncTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
