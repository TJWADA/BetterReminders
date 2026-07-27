import AppIntents
import Foundation

struct ToggleRecordingIntent: AppIntent, AudioRecordingIntent {
    static var title: LocalizedStringResource = "Toggle Recording"
    static var description = IntentDescription("Start or stop recording a voice reminder.")
    static var openAppWhenRun: Bool = false

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
            try await RecordingStopHandler.stopIfRecording()
        } else {
            try await RecordingLiveActivityManager.start()
            do {
                HapticHelper.recordingStarted()
                _ = try recorder.startRecording()
            } catch {
                await RecordingLiveActivityManager.endImmediate()
                throw error
            }
            await RecordingCoordinator.shared.startMeterTimer()
        }

        return .result()
    }
}
