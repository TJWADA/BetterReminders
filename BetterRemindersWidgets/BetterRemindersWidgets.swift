import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit
import BetterRemindersCore

struct RecordingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { context in
            RecordingLiveActivityViews.lockScreenCompact(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    RecordingLiveActivityViews.phaseIcon(context: context, size: .title3)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.statusMessage)
                            .font(.caption)
                            .lineLimit(2)
                        RecordingLiveActivityViews.phaseSubtitle(context: context)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    RecordingLiveActivityViews.compactTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    RecordingLiveActivityViews.expandedBottom(context: context)
                }
            } compactLeading: {
                RecordingLiveActivityViews.phaseIcon(context: context, size: .caption)
            } compactTrailing: {
                RecordingLiveActivityViews.compactTrailing(context: context)
            } minimal: {
                RecordingLiveActivityViews.minimalIcon(context: context)
            }
        }
    }
}

@main
struct BetterRemindersWidgetsBundle: WidgetBundle {
    var body: some Widget {
        RecordingLiveActivityWidget()
    }
}
