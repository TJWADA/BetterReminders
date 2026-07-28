import Foundation
import BetterRemindersCore

enum APIKeyValidator {
    static let missingKeyMessage = "Add your OpenAI API key in Settings."

    static func requireConfigured() throws {
        guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
            throw ValidationError.missingAPIKey
        }
    }

    enum ValidationError: LocalizedError {
        case missingAPIKey

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return APIKeyValidator.missingKeyMessage
            }
        }
    }
}

enum RecordingPermissions {
    static func ensureAuthorized(recorder: AudioRecordingService) async throws {
        if !recorder.hasMicrophonePermission {
            let granted = await recorder.requestMicrophonePermission()
            guard granted else {
                throw AudioRecordingService.RecordingError.permissionDenied
            }
        }

        let speechStatus = await SpeechService.requestAuthorization()
        guard speechStatus == .authorized else {
            throw ValidationError.speechPermissionDenied
        }
    }

    enum ValidationError: LocalizedError {
        case speechPermissionDenied

        var errorDescription: String? {
            switch self {
            case .speechPermissionDenied:
                return "Enable microphone and speech recognition in Settings to record reminders."
            }
        }
    }
}
