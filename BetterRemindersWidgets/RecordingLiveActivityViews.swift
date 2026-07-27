import ActivityKit
import SwiftUI
import WidgetKit

struct RecordingLiveActivityViews {
    @ViewBuilder
    static func lockScreenContent(context: ActivityViewContext<RecordingActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                phaseIcon(context: context, size: .title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.statusMessage)
                        .font(.headline)
                    phaseSubtitle(context: context)
                }
                Spacer()
            }

            phaseBody(context: context)

            if context.state.phase == .recording {
                Button(intent: StopRecordingWidgetIntent()) {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
    }

    @ViewBuilder
    static func phaseBody(context: ActivityViewContext<RecordingActivityAttributes>) -> some View {
        switch context.state.phase {
        case .recording:
            VStack(alignment: .leading, spacing: 8) {
                AudioLevelBarsView(level: context.state.audioLevel)
                Text(formatElapsed(context.state.elapsedSeconds))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        case .transcribing, .parsing:
            ProgressView()
                .progressViewStyle(.linear)
        case .completed:
            if let title = context.state.resultTitle {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(title)
                        .font(.subheadline.bold())
                }
                if let listName = context.state.resultListName {
                    ListResultBadge(name: listName, icon: context.state.resultListIcon ?? "folder.fill")
                }
            }
        case .failed:
            EmptyView()
        }
    }

    @ViewBuilder
    static func compactTrailing(context: ActivityViewContext<RecordingActivityAttributes>) -> some View {
        switch context.state.phase {
        case .recording:
            HStack(spacing: 4) {
                MiniLevelBarsView(level: context.state.audioLevel)
                Text(formatElapsed(context.state.elapsedSeconds))
                    .font(.caption2.monospacedDigit())
            }
        case .transcribing, .parsing:
            ProgressView()
                .scaleEffect(0.7)
        case .completed:
            if let listName = context.state.resultListName {
                Text(listName)
                    .font(.caption2)
                    .lineLimit(1)
            } else {
                Image(systemName: "checkmark")
                    .foregroundStyle(.green)
            }
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    static func phaseIcon(context: ActivityViewContext<RecordingActivityAttributes>, size: Font) -> some View {
        switch context.state.phase {
        case .recording:
            Image(systemName: "mic.fill")
                .font(size)
                .foregroundStyle(.red)
                .symbolEffect(.pulse, options: .repeating, value: context.state.audioLevel)
        case .transcribing:
            Image(systemName: "waveform")
                .font(size)
                .foregroundStyle(.blue)
                .symbolEffect(.variableColor.iterative, options: .repeating)
        case .parsing:
            Image(systemName: "sparkles")
                .font(size)
                .foregroundStyle(.purple)
                .symbolEffect(.pulse, options: .repeating)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(size)
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(size)
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    static func phaseSubtitle(context: ActivityViewContext<RecordingActivityAttributes>) -> some View {
        switch context.state.phase {
        case .recording:
            Text("BetterReminders")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .transcribing:
            Text("On-device transcription")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .parsing:
            Text("Finding the right list")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .completed:
            Text("Reminder saved")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .failed:
            Text("Tap to open BetterReminders")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    static func formatElapsed(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct AudioLevelBarsView: View {
    let level: Double

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(level > 0.05 ? Color.red : Color.gray.opacity(0.4))
                    .frame(width: 6, height: barHeight(for: index))
            }
        }
        .frame(height: 28, alignment: .bottom)
        .animation(.easeOut(duration: 0.15), value: level)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let jitter = Double(index) * 0.08
        let scaled = min(1.0, max(0.15, level + jitter))
        return 8 + CGFloat(scaled) * 20
    }
}

struct MiniLevelBarsView: View {
    let level: Double

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color.red)
                    .frame(width: 3, height: 4 + CGFloat(min(1, level + Double(index) * 0.1)) * 8)
            }
        }
    }
}

struct ListResultBadge: View {
    let name: String
    let icon: String

    var body: some View {
        Label(name, systemImage: icon)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.15), in: Capsule())
            .foregroundStyle(.blue)
    }
}
