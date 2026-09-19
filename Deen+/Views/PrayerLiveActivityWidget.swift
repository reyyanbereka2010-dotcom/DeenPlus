//
//  PrayerLiveActivityWidget.swift
//  Deen+
//
//  Created by Reyyan Bereka on 9/18/26.
//

import SwiftUI
import WidgetKit
import ActivityKit

public struct PrayerLiveActivityWidgetView: View {
    let context: ActivityViewContext<PrayerActivityAttributes>

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: context.state.iconName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Next: \(context.state.nextPrayerName)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)

                    Text(context.attributes.locationName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.formattedTime)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Scheduled")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                        .foregroundStyle(Color.green)
                    Text("Starts in")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Text(context.state.nextPrayerDate, style: .timer)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.green)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(Color(red: 0.08, green: 0.12, blue: 0.10))
    }
}

public struct PrayerLiveActivityWidget: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            PrayerLiveActivityWidgetView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Leading Region
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.iconName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.green)
                        Text(context.state.nextPrayerName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.leading, 8)
                }

                // Trailing Region
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.formattedTime)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(context.attributes.locationName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.trailing, 8)
                }

                // Center / Main Region
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }

                // Bottom Region (Timer)
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.green)
                            Text("Countdown")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.75))
                        }

                        Spacer()

                        Text(context.state.nextPrayerDate, style: .timer)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.green)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: context.state.iconName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.green)
                    Text(context.state.nextPrayerName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.leading, 4)
            } compactTrailing: {
                Text(context.state.nextPrayerDate, style: .timer)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.green)
                    .monospacedDigit()
                    .padding(.trailing, 4)
            } minimal: {
                Image(systemName: context.state.iconName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.green)
            }
        }
    }
}
