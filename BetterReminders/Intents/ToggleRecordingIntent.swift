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
            do {
                _ = try await ActionButtonFlowCoordinator.stopRecording()
            } catch {
                postFailure(error)
                throw error
            }
            return .result()
        }

        if !RecordingSessionStore.isActionButtonArmed {
            ActionButtonFlowCoordinator.armAndOpenRecordTab()
            return .result()
        }

        if KeychainHelper.loadAPIKey()?.isEmpty ?? true {
            let error = ActionButtonIntentError.apiKeyMissing
            postFailure(error)
            throw error
        }

        if !recorder.hasMicrophonePermission {
            let granted = await recorder.requestMicrophonePermission()
            guard granted else {
                let error = AudioRecordingService.RecordingError.permissionDenied
                postFailure(error)
                throw error
            }
        }

        let speechStatus = await SpeechService.requestAuthorization()
        guard speechStatus == .authorized else {
            let error = ActionButtonIntentError.speechPermissionDenied
            postFailure(error)
            throw error
        }

        do {
            try await ActionButtonFlowCoordinator.startRecording()
        } catch {
            postFailure(error)
            throw error
        }

        return .result()
    }

    private func postFailure(_ error: Error) {
        NotificationCenter.default.post(
            name: .actionButtonRecordingFailed,
            object: nil,
            userInfo: [
                "message": (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            ]
        )
    }
}

enum ActionButtonIntentError: LocalizedError {
    case apiKeyMissing
    case speechPermissionDenied

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "OpenAI API key not configured. Add it in Settings first."
        case .speechPermissionDenied:
            return "Enable speech recognition in Settings to record reminders."
        }
    }
}
