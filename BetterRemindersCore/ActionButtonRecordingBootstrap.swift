import ActivityKit
import Foundation

public enum ActionButtonRecordingBootstrap {
    /// Live Activities often report as disabled until the app is foreground.
    public static func shouldDeferLiveActivityStart() -> Bool {
        !ActivityAuthorizationInfo().areActivitiesEnabled
    }

    public static func markDeferredStart() {
        RecordingSessionStore.markPendingActionButtonStart()
    }

    @MainActor
    public static func beginRecordingIfNeeded() async throws {
        let recorder = AudioRecordingService.shared
        guard !recorder.isRecording else { return }

        if !recorder.hasMicrophonePermission {
            let granted = await recorder.requestMicrophonePermission()
            guard granted else {
                throw AudioRecordingService.RecordingError.permissionDenied
            }
        }

        try await RecordingLiveActivityManager.start()
        HapticHelper.recordingStarted()
        _ = try recorder.startRecording()
        await RecordingCoordinator.shared.startMeterTimer()
    }

    @MainActor
    public static func completePendingStartIfNeeded() async {
        guard RecordingSessionStore.consumePendingActionButtonStart() else { return }

        let recorder = AudioRecordingService.shared
        guard !recorder.isRecording else { return }

        do {
            try await beginRecordingIfNeeded()
        } catch {
            NotificationCenter.default.post(
                name: .actionButtonRecordingFailed,
                object: nil,
                userInfo: [
                    "message": (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                ]
            )
        }
    }
}

public extension Notification.Name {
    static let actionButtonRecordingFailed = Notification.Name("actionButtonRecordingFailed")
}
