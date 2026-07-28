import AppIntents
import Foundation
import BetterRemindersCore

struct ToggleRecordingIntent: AppIntent, AudioRecordingIntent {
    static var title: LocalizedStringResource = "Toggle Recording"
    static var description = IntentDescription("Start or stop recording a voice reminder.")
    /// Opens the app briefly so Live Activity can start reliably from the Action Button.
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        let recorder = AudioRecordingService.shared
        recorder.resetStaleSession()

        if recorder.isRecording {
            try await RecordingStopHandler.stopIfRecording()
            return .result()
        }

        if !recorder.hasMicrophonePermission {
            let granted = await recorder.requestMicrophonePermission()
            guard granted else {
                throw AudioRecordingService.RecordingError.permissionDenied
            }
        }

        if ActionButtonRecordingBootstrap.shouldDeferLiveActivityStart() {
            ActionButtonRecordingBootstrap.markDeferredStart()
            return .result()
        }

        do {
            try await ActionButtonRecordingBootstrap.beginRecordingIfNeeded()
        } catch is RecordingLiveActivityError {
            ActionButtonRecordingBootstrap.markDeferredStart()
            return .result()
        }

        return .result()
    }
}
