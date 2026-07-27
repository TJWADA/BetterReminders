import Foundation

@MainActor
final class RecordingCoordinator {
    static let shared = RecordingCoordinator()

    private var meterTimer: Timer?
    private var lowAudioTicks = 0

    private init() {}

    func startMeterTimer() {
        meterTimer?.invalidate()
        lowAudioTicks = 0
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.tickMeter()
            }
        }
        if let meterTimer {
            RunLoop.main.add(meterTimer, forMode: .common)
        }
    }

    func stopMeterTimer() {
        meterTimer?.invalidate()
        meterTimer = nil
        lowAudioTicks = 0
    }

    func handleStoppedRecording(at url: URL) async {
        NotificationCenter.default.post(
            name: .recordingDidFinish,
            object: nil,
            userInfo: ["audioURL": url]
        )
    }

    private func tickMeter() async {
        let recorder = AudioRecordingService.shared
        guard recorder.isRecording else { return }

        if RecordingSessionStore.consumeStopRequest() {
            try? await RecordingStopHandler.stopIfRecording()
            return
        }

        let level = recorder.currentAudioLevel()
        let elapsed = Int(recorder.elapsedTime)

        if level < 0.08 {
            lowAudioTicks += 1
        } else {
            lowAudioTicks = 0
        }

        let message = lowAudioTicks >= 12 ? "Speak now…" : "Recording…"
        await RecordingLiveActivityManager.updateRecording(
            elapsedSeconds: elapsed,
            audioLevel: level,
            statusMessage: message
        )
    }
}

extension Notification.Name {
    static let recordingDidFinish = Notification.Name("recordingDidFinish")
}
