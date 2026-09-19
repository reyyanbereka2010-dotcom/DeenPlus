//
//  PrayerLiveActivityManager.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/18/26.
//

import Foundation
import ActivityKit
import Combine
import os

@MainActor
public class PrayerLiveActivityManager: ObservableObject {
    public static let shared = PrayerLiveActivityManager()

    private let logger = Logger(subsystem: "com.reyber.Deen", category: "LiveActivity")

    @Published public private(set) var isActivityActive = false

    private init() {
        checkActiveActivities()
    }

    public func checkActiveActivities() {
        if #available(iOS 16.1, *) {
            isActivityActive = !Activity<PrayerActivityAttributes>.activities.isEmpty
            logger.info("Active activities count: \(Activity<PrayerActivityAttributes>.activities.count)")
        }
    }

    /// Starts or updates a Live Activity for the next upcoming prayer
    public func updateLiveActivity(
        nextPrayerName: String,
        nextPrayerDate: Date,
        formattedTime: String,
        iconName: String,
        locationName: String
    ) {
        logger.info("updateLiveActivity called with: \(nextPrayerName), \(formattedTime), date: \(nextPrayerDate)")

        let areEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        logger.info("areActivitiesEnabled: \(areEnabled)")

        let contentState = PrayerActivityAttributes.ContentState(
            nextPrayerName: nextPrayerName,
            nextPrayerDate: nextPrayerDate,
            formattedTime: formattedTime,
            iconName: iconName
        )

        let attributes = PrayerActivityAttributes(locationName: locationName)

        if #available(iOS 16.1, *) {
            let existingActivities = Activity<PrayerActivityAttributes>.activities
            logger.info("Existing activities count: \(existingActivities.count)")

            if let existingActivity = existingActivities.first {
                Task {
                    let activityContent = ActivityContent(state: contentState, staleDate: nextPrayerDate)
                    await existingActivity.update(activityContent)
                    await MainActor.run { self.isActivityActive = true }
                    logger.info("Updated existing activity \(existingActivity.id)")
                }
            } else {
                do {
                    let activityContent = ActivityContent(state: contentState, staleDate: nextPrayerDate)
                    let newActivity = try Activity<PrayerActivityAttributes>.request(
                        attributes: attributes,
                        content: activityContent,
                        pushType: nil
                    )
                    isActivityActive = true
                    logger.info("Successfully requested new Live Activity with ID: \(newActivity.id)")
                } catch {
                    logger.error("Failed to start Live Activity: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Ends all active prayer Live Activities
    public func endLiveActivity() {
        if #available(iOS 16.1, *) {
            for activity in Activity<PrayerActivityAttributes>.activities {
                Task {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
            isActivityActive = false
            logger.info("Ended all activities")
        }
    }
}
