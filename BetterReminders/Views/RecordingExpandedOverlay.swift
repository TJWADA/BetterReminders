import SwiftUI
import BetterRemindersCore

struct RecordingExpandedOverlay: View {
    @Bindable var recorder: AudioRecordingService
    var displayTick: Int
    var namespace: Namespace.ID
    var onStop: () -> Void

    @State private var contentVisible = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: contentVisible ? 0 : 28, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay {
                    LinearGradient(
                        colors: [Color.red.opacity(0.10), Color.red.opacity(0.03), Color.clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }
                .matchedGeometryEffect(id: "recordingExpand", in: namespace)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { _ in
                        RecordingWaveformBars(
                            level: recorder.currentAudioLevel(),
                            barCount: 21,
                            color: .red
                        )
                        .frame(height: 72)
                    }

                    Text(DurationFormatter.mmss(from: recorder.elapsedTime))
                        .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .id(displayTick)

                    Text("Recording")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.red)
                }
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 20)

                Spacer()

                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(Color.red.gradient, in: Circle())
                        .shadow(color: .red.opacity(0.4), radius: 16, y: 4)
                }
                .matchedGeometryEffect(id: "recordButton", in: namespace)
                .padding(.bottom, 52)
            }

            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "mic.fill")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.6))
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                        .opacity(contentVisible ? 1 : 0)
                        .padding(.top, 8)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82).delay(0.12)) {
                contentVisible = true
            }
        }
        .onDisappear {
            contentVisible = false
        }
    }
}
