import AppIntents
import Foundation

struct ToggleRecordingIntent: AppIntent, AudioRecordingIntent {
    static var title: LocalizedStringResource = "Toggle Recording"
    static var description = IntentDescription("Start or stop recording a voice reminder.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let recorder = AudioRecordingService.shared

        if !recorder.hasMicrophonePermission {
            let granted = await recorder.requestMicrophonePermission()
            guard granted else {
                throw AudioRecordingService.RecordingError.permissionDenied
            }
        }

        if recorder.isRecording {
            guard let url = recorder.stopRecording() else {
                return .result()
            }
            await RecordingLiveActivityManager.showProcessing(message: "Processing…")
            PendingRecordingStore.enqueue(url)
            await RecordingCoordinator.shared.handleStoppedRecording(at: url)
            await RecordingLiveActivityManager.end()
        } else {
            _ = try recorder.startRecording()
            await RecordingLiveActivityManager.start()
            await RecordingCoordinator.shared.startElapsedTimer()
        }

        return .result()
    }
}

@MainActor
final class RecordingCoordinator {
    static let shared = RecordingCoordinator()

    private var elapsedTimer: Timer?
    private var pendingAudioURL: URL?

    private init() {}

    func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task {
                let elapsed = Int(AudioRecordingService.shared.elapsedTime)
                await RecordingLiveActivityManager.update(elapsedSeconds: elapsed)
            }
        }
    }

    func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    func handleStoppedRecording(at url: URL) async {
        stopElapsedTimer()
        pendingAudioURL = url
        NotificationCenter.default.post(
            name: .recordingDidFinish,
            object: nil,
            userInfo: ["audioURL": url]
        )
    }
}

extension Notification.Name {
    static let recordingDidFinish = Notification.Name("recordingDidFinish")
}
