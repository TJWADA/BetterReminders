import SwiftUI
import BetterRemindersCore

struct RecordingBannerView: View {
    @Bindable var recorder: AudioRecordingService
    var displayTick: Int = 0

    private let barCount = 7

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { _ in
            HStack(spacing: 16) {
                RecordingWaveformBars(
                    level: recorder.currentAudioLevel(),
                    barCount: barCount,
                    color: .red
                )
                .frame(height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recording")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                    Text(formattedElapsed(Int(recorder.elapsedTime)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .id(displayTick)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.red.opacity(0.08))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.red.opacity(0.18), lineWidth: 1)
                    }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    private func formattedElapsed(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

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

struct RecordButtonView: View {
    @Bindable var recorder: AudioRecordingService
    var isProcessing: Bool
    var namespace: Namespace.ID? = nil
    var isExpanded: Bool = false
    var action: () -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: recorder.isRecording ? 1.0 / 30.0 : 1)) { _ in
            Button(action: action) {
                ZStack {
                    if recorder.isRecording && !isExpanded {
                        let level = recorder.currentAudioLevel()
                        ForEach(0..<3, id: \.self) { ring in
                            Circle()
                                .stroke(Color.red.opacity(0.22 - Double(ring) * 0.06), lineWidth: 2)
                                .frame(width: 56 + CGFloat(ring) * 14, height: 56 + CGFloat(ring) * 14)
                                .scaleEffect(1 + CGFloat(level) * 0.08 + CGFloat(ring) * 0.04)
                        }
                    }

                    Group {
                        if let namespace, !isExpanded {
                            Circle()
                                .fill(recorder.isRecording ? Color.red.gradient : Color.accentColor.gradient)
                                .matchedGeometryEffect(id: "recordingExpand", in: namespace, isSource: !recorder.isRecording)
                                .frame(width: 56, height: 56)
                                .overlay {
                                    Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                                .shadow(color: (recorder.isRecording ? Color.red : Color.accentColor).opacity(0.35), radius: 8, y: 2)
                                .matchedGeometryEffect(id: "recordButton", in: namespace, isSource: !recorder.isRecording)
                        } else if !isExpanded {
                            Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    recorder.isRecording ? Color.red.gradient : Color.accentColor.gradient,
                                    in: Circle()
                                )
                                .shadow(color: (recorder.isRecording ? Color.red : Color.accentColor).opacity(0.35), radius: 8, y: 2)
                        } else {
                            Color.clear.frame(width: 56, height: 56)
                        }
                    }
                }
            }
            .disabled(isProcessing || isExpanded)
            .opacity(isExpanded ? 0 : 1)
        }
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
                .frame(width: 44, height: 44)
                .background {
                    if let namespace, let geometryID {
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
                            .matchedGeometryEffect(id: geometryID, in: namespace, isSource: !isExpanded)
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
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
