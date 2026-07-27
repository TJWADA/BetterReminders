import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct RecordingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { context in
            RecordingLiveActivityViews.lockScreenContent(context: context)
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
            if context.state.phase == .recording {
                Button(intent: StopRecordingWidgetIntent()) {
                            Label("Stop Recording", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    } else if context.state.phase == .completed,
                              let title = context.state.resultTitle {
                        VStack(spacing: 4) {
                            Text(title)
                                .font(.caption.bold())
                            if let listName = context.state.resultListName {
                                ListResultBadge(
                                    name: listName,
                                    icon: context.state.resultListIcon ?? "folder.fill"
                                )
                            }
                        }
                    }
                }
            } compactLeading: {
                RecordingLiveActivityViews.phaseIcon(context: context, size: .caption)
            } compactTrailing: {
                RecordingLiveActivityViews.compactTrailing(context: context)
            } minimal: {
                Image(systemName: context.state.phase == .completed ? "checkmark" : "mic.fill")
                    .foregroundStyle(context.state.phase == .completed ? .green : .red)
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
