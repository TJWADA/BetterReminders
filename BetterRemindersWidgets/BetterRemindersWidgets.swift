import ActivityKit
import SwiftUI
import WidgetKit

struct RecordingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { context in
            HStack(spacing: 12) {
                Image(systemName: context.state.isRecording ? "mic.fill" : "waveform")
                    .foregroundStyle(context.state.isRecording ? .red : .blue)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.statusMessage)
                        .font(.headline)
                    if context.state.isRecording {
                        Text(formatElapsed(context.state.elapsedSeconds))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.red)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.statusMessage)
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isRecording {
                        Text(formatElapsed(context.state.elapsedSeconds))
                            .font(.caption.monospacedDigit())
                    }
                }
            } compactLeading: {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
            } compactTrailing: {
                if context.state.isRecording {
                    Text(formatElapsed(context.state.elapsedSeconds))
                        .font(.caption2.monospacedDigit())
                }
            } minimal: {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

@main
struct BetterRemindersWidgetsBundle: WidgetBundle {
    var body: some Widget {
        RecordingLiveActivityWidget()
    }
}
