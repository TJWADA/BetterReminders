import SwiftUI
import BetterRemindersCore

struct RecordingSheetView: View {
    @Bindable var recorder: AudioRecordingService
    var displayTick: Int
    var onStop: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text("Recording")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.red)

                Text(DurationFormatter.mmss(from: recorder.elapsedTime))
                    .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .id(displayTick)
            }

            Spacer()

            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(Color.red, in: Circle())
            }
            .padding(.bottom, 52)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
