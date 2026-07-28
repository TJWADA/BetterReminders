import Foundation

public enum ActionButtonFlowCoordinator {
    @MainActor
    public static func startRecording() async throws {
        let recorder = AudioRecordingService.shared
        guard !recorder.isRecording else { return }

        if !recorder.hasMicrophonePermission {
            let granted = await recorder.requestMicrophonePermission()
            guard granted else {
                throw AudioRecordingService.RecordingError.permissionDenied
            }
        }

        HapticHelper.recordingStarted()
        _ = try recorder.startRecording()
        NotificationCenter.default.post(name: .actionButtonRecordingStarted, object: nil)
    }

    @MainActor
    public static func stopRecording() async throws -> URL {
        let recorder = AudioRecordingService.shared
        guard recorder.isRecording else {
            throw RecordingStopHandler.RecordingStopError.stopFailed
        }

        HapticHelper.recordingStopped()
        guard let url = recorder.stopRecording() else {
            throw RecordingStopHandler.RecordingStopError.stopFailed
        }

        guard RecordingStopHandler.recordingFileIsUsable(at: url) else {
            throw RecordingStopHandler.RecordingStopError.recordingTooShort
        }

        NotificationCenter.default.post(
            name: .actionButtonRecordingStopped,
            object: nil,
            userInfo: ["audioURL": url]
        )
        return url
    }
}

public extension Notification.Name {
    static let actionButtonRecordingStarted = Notification.Name("actionButtonRecordingStarted")
    static let actionButtonRecordingStopped = Notification.Name("actionButtonRecordingStopped")
    static let actionButtonRecordingFailed = Notification.Name("actionButtonRecordingFailed")
    static let actionButtonOpenRecordingRequested = Notification.Name("actionButtonOpenRecordingRequested")
}
