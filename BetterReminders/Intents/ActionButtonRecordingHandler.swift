import Foundation
import BetterRemindersCore

enum ActionButtonRecordingHandler {
    @MainActor
    static func prepareAppOpenForRecording() {
        RecordingSessionStore.clearActionButtonState()
        RecordingSessionStore.markOpenRecordTab()
        NotificationCenter.default.post(name: .actionButtonOpenRecordingRequested, object: nil)
    }

    @MainActor
    static func continueFromAppOpenIfNeeded() async {
        guard RecordingSessionStore.consumeOpenRecordTab() else { return }
        guard !AudioRecordingService.shared.isRecording else { return }

        do {
            try await validateAndStartRecording()
        } catch {
            postFailure(error)
        }
    }

    static func shouldStopRecording(_ recorder: AudioRecordingService) -> Bool {
        guard recorder.isRecording else { return false }
        return RecordingSessionStore.shouldAllowActionButtonStop
    }

    @MainActor
    private static func validateAndStartRecording() async throws {
        let recorder = AudioRecordingService.shared
        guard !recorder.isRecording else { return }

        try APIKeyValidator.requireConfigured()
        try await RecordingPermissions.ensureAuthorized(recorder: recorder)
        try await ActionButtonFlowCoordinator.startRecording()
    }

    static func postFailure(_ error: Error) {
        NotificationCenter.default.post(
            name: .actionButtonRecordingFailed,
            object: nil,
            userInfo: [
                "message": (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            ]
        )
    }
}
