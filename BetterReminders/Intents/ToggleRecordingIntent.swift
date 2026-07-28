import AppIntents
import Foundation
import BetterRemindersCore

struct ToggleRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Recording"
    static var description = IntentDescription("Open BetterReminders to record, start, or stop a voice reminder.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        let recorder = AudioRecordingService.shared
        recorder.resetStaleSession()

        if recorder.isRecording {
            guard ActionButtonRecordingHandler.shouldStopRecording(recorder) else {
                return .result()
            }

            do {
                _ = try await ActionButtonFlowCoordinator.stopRecording()
            } catch {
                ActionButtonRecordingHandler.postFailure(error)
                throw error
            }
            return .result()
        }

        await ActionButtonRecordingHandler.prepareAppOpenForRecording()
        return .result()
    }
}
