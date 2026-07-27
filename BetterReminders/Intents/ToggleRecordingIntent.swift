import AppIntents
import Foundation

struct ToggleRecordingIntent: AppIntent, AudioRecordingIntent {
    static var title: LocalizedStringResource = "Toggle Recording"
    static var description = IntentDescription("Start or stop recording a voice reminder.")
    /// Opens the app briefly so Live Activity and the mic session can start reliably.
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        let recorder = AudioRecordingService.shared
        recorder.resetStaleSession()

        if !recorder.hasMicrophonePermission {
            let granted = await recorder.requestMicrophonePermission()
            guard granted else {
                throw AudioRecordingService.RecordingError.permissionDenied
            }
        }

        if recorder.isRecording {
            HapticHelper.recordingStopped()
            guard let url = recorder.stopRecording() else {
                throw IntentError.stopFailed
            }

            guard Self.recordingFileIsUsable(at: url) else {
                throw IntentError.recordingTooShort
            }

            await RecordingCoordinator.shared.stopElapsedTimer()
            await RecordingLiveActivityManager.showProcessing(message: "Processing…")
            PendingRecordingStore.enqueue(url)
            await RecordingCoordinator.shared.handleStoppedRecording(at: url)
            await RecordingLiveActivityManager.end()
        } else {
            // Live Activity must be active before mic capture (AudioRecordingIntent requirement).
            try await RecordingLiveActivityManager.start()
            do {
                HapticHelper.recordingStarted()
                _ = try recorder.startRecording()
            } catch {
                await RecordingLiveActivityManager.end()
                throw error
            }
            await RecordingCoordinator.shared.startElapsedTimer()
        }

        return .result()
    }

    private static func recordingFileIsUsable(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path),
              let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return false
        }
        return size > 1024
    }

    enum IntentError: LocalizedError {
        case stopFailed
        case recordingTooShort

        var errorDescription: String? {
            switch self {
            case .stopFailed:
                return "Could not stop recording. Open BetterReminders and try in-app Record once."
            case .recordingTooShort:
                return "Recording was too short or empty. Hold the Action Button, speak, then press again."
            }
        }
    }
}

@MainActor
final class RecordingCoordinator {
    static let shared = RecordingCoordinator()

    private var elapsedTimer: Timer?

    private init() {}

    func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task {
                let elapsed = Int(AudioRecordingService.shared.elapsedTime)
                await RecordingLiveActivityManager.update(elapsedSeconds: elapsed)
            }
        }
        if let elapsedTimer {
            RunLoop.main.add(elapsedTimer, forMode: .common)
        }
    }

    func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    func handleStoppedRecording(at url: URL) async {
        stopElapsedTimer()
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
