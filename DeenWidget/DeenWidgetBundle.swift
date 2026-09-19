//
//  DeenWidgetBundle.swift
//  DeenWidget
//
//  Created by Reyyan Bereka on 9/19/26.
//

import WidgetKit
import SwiftUI

@main
struct DeenWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesWidget()
        AyahWidget()
        PrayerLiveActivityWidget()
    }
}
