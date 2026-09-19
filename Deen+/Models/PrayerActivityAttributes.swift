//
//  PrayerActivityAttributes.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/18/26.
//

import ActivityKit
import Foundation

public struct PrayerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var nextPrayerName: String
        public var nextPrayerDate: Date
        public var formattedTime: String
        public var iconName: String

        public init(nextPrayerName: String, nextPrayerDate: Date, formattedTime: String, iconName: String) {
            self.nextPrayerName = nextPrayerName
            self.nextPrayerDate = nextPrayerDate
            self.formattedTime = formattedTime
            self.iconName = iconName
        }
    }

    public var locationName: String

    public init(locationName: String) {
        self.locationName = locationName
    }
}
