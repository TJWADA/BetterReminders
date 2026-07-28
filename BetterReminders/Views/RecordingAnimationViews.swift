import SwiftUI
import BetterRemindersCore

struct RecordingWaveformBars: View {
    let level: Double
    var barCount: Int = 5
    var color: Color = .red

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color.gradient)
                    .frame(width: 3, height: barHeight(for: index))
                    .animation(.easeOut(duration: 0.08), value: level)
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let t = Date().timeIntervalSinceReferenceDate
        let wave = sin(t * 9 + Double(index) * 0.9) * 0.22
        let stagger = 0.65 + Double(index % 3) * 0.12
        let normalized = min(1, max(0.08, (level * stagger) + wave))
        return 6 + CGFloat(normalized) * 22
    }
}

private enum CornerActionMetrics {
    static let size: CGFloat = 44
}

struct RecordButtonView: View {
    @Bindable var recorder: AudioRecordingService
    var isProcessing: Bool
    var namespace: Namespace.ID? = nil
    var isExpanded: Bool = false
    var action: () -> Void

    private var iconColor: Color {
        recorder.isRecording ? .red : .accentColor
    }

    private var backgroundColor: Color {
        iconColor.opacity(0.12)
    }

    var body: some View {
        Button(action: action) {
            Group {
                if let namespace, !isExpanded {
                    ZStack {
                        Circle()
                            .fill(backgroundColor)
                            .matchedGeometryEffect(id: "recordingExpand", in: namespace, isSource: !recorder.isRecording)
                        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.title3)
                            .foregroundStyle(iconColor)
                    }
                    .frame(width: CornerActionMetrics.size, height: CornerActionMetrics.size)
                    .matchedGeometryEffect(id: "recordButton", in: namespace, isSource: !recorder.isRecording)
                } else if !isExpanded {
                    Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.title3)
                        .foregroundStyle(iconColor)
                        .frame(width: CornerActionMetrics.size, height: CornerActionMetrics.size)
                        .background(backgroundColor, in: Circle())
                } else {
                    Color.clear.frame(width: CornerActionMetrics.size, height: CornerActionMetrics.size)
                }
            }
        }
        .disabled(isProcessing || isExpanded)
        .opacity(isExpanded ? 0 : 1)
    }
}

struct CornerActionButton: View {
    let icon: String
    var color: Color = .secondary
    var namespace: Namespace.ID? = nil
    var geometryID: String? = nil
    var isExpanded: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: CornerActionMetrics.size, height: CornerActionMetrics.size)
                .background {
                    if let namespace, let geometryID {
                        Circle()
                            .fill(color.opacity(0.12))
                            .matchedGeometryEffect(id: geometryID, in: namespace, isSource: !isExpanded)
                    } else {
                        Circle()
                            .fill(color.opacity(0.12))
                    }
                }
        }
        .opacity(isExpanded ? 0 : 1)
        .disabled(isExpanded)
    }
}

struct ProcessingBannerView: View {
    let status: String

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text(status)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

struct RecordingErrorBannerView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .lineLimit(2)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
