import ActivityKit
import SwiftUI
import WidgetKit

struct RecordingLiveActivityViews {
    // MARK: - Lock Screen (minimal fallback)

    @ViewBuilder
    static func lockScreenCompact(context: ActivityViewContext<RecordingActivityAttributes>) -> some View {
        HStack(spacing: 8) {
            phaseIcon(context: context, size: .body)
            Text(lockScreenMessage(context: context))
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private static func lockScreenMessage(context: ActivityViewContext<RecordingActivityAttributes>) -> String {
        switch context.state.phase {
        case .completed:
            return "Reminder saved"
        case .failed:
            return context.state.statusMessage
        default:
            return context.state.statusMessage
        }
    }

    // MARK: - Dynamic Island Expanded

    @ViewBuilder
    static func expandedBottom(context: ActivityViewContext<RecordingActivityAttributes>) -> some View {
        switch context.state.phase {
        case .recording:
            VStack(spacing: 10) {
                HStack {
                    recordingMeter(context: context)
                    Spacer()
                    recordingTimer(context: context)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Button(intent: StopRecordingIntent()) {
                    Label("Stop Recording", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        case .transcribing, .parsing:
            ProgressView()
                .progressViewStyle(.linear)
        case .completed:
            if let title = context.state.resultTitle {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(title)
                            .font(.caption.bold())
                            .lineLimit(2)
                    }
                    if let listName = context.state.resultListName {
                        ListResultBadge(
                            name: listName,
                            icon: context.state.resultListIcon ?? "folder.fill"
                        )
                    }
                }
            }
        case .failed:
            Text(context.state.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
    }

    @ViewBuilder
    static func recordingMeter(context: ActivityViewContext<RecordingActivityAttributes>) -> some View {
        if context.state.audioLevel > 0.05 {
            AudioLevelBarsView(level: context.state.audioLevel)
        } else {
            Image(systemName: "mic.fill")
                .font(.title3)
                .foregroundStyle(.red)
                .symbolEffect(.pulse, options: .repeating)
        }
    }

    @ViewBuilder
    static func recordingTimer(context: ActivityViewContext<RecordingActivityAttributes>) -> some View {
        Text(timerInterval: context.attributes.recordingStartDate...Date.distantFuture, countsDown: false)
    }

    // MARK: - Compact / Minimal

    @ViewBuilder
    static func compactTrailing(context: ActivityViewContext<RecordingActivityAttributes>) -> some View {
        switch context.state.phase {
        case .recording:
            HStack(spacing: 4) {
                if context.state.audioLevel > 0.05 {
                    MiniLevelBarsView(level: context.state.audioLevel)
                }
                recordingTimer(context: context)
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
    static func minimalIcon(context: ActivityViewContext<RecordingActivityAttributes>) -> some View {
        switch context.state.phase {
        case .recording:
            Image(systemName: "mic.fill")
                .foregroundStyle(.red)
        case .transcribing:
            Image(systemName: "waveform")
                .foregroundStyle(.blue)
                .symbolEffect(.variableColor.iterative, options: .repeating)
        case .parsing:
            Image(systemName: "sparkles")
                .foregroundStyle(.purple)
                .symbolEffect(.pulse, options: .repeating)
        case .completed:
            Image(systemName: "checkmark")
                .foregroundStyle(.green)
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
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .transcribing:
            Text("On-device transcription")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .parsing:
            Text("Finding the right list")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .completed:
            Text("Reminder saved")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .failed:
            Text("Tap to open BetterReminders")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
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
