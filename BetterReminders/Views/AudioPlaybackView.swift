import SwiftUI

struct AudioPlaybackView: View {
    let audioPath: String
    @State private var player = AudioPlaybackService.shared
    @State private var playbackFailed = false

    private var isCurrentFile: Bool {
        player.currentURL?.path == audioPath
    }

    private var isPlaying: Bool {
        isCurrentFile && player.isPlaying
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if AudioPlaybackService.shared.fileExists(at: audioPath) {
                Button {
                    playbackFailed = false
                    let started = player.togglePlayback(for: audioPath)
                    if !started {
                        playbackFailed = true
                    }
                } label: {
                    Label(isPlaying ? "Pause Recording" : "Play Recording", systemImage: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.headline)
                }

                if isCurrentFile, player.duration > 0 {
                    ProgressView(value: player.currentTime, total: player.duration)
                    HStack {
                        Text(formatTime(player.currentTime))
                        Spacer()
                        Text(formatTime(player.duration))
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                }

                if playbackFailed {
                    Text("Could not play this recording.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } else {
                Label("Recording no longer available", systemImage: "waveform.slash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .onDisappear {
            if isCurrentFile {
                player.stop()
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        DurationFormatter.mmss(from: time)
    }
}
