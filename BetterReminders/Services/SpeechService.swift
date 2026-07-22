import Foundation
import Speech

enum SpeechService {
    static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    static func transcribe(audioURL: URL) async throws -> String {
        guard let recognizer = SFSpeechRecognizer(locale: Locale.current), recognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result, result.isFinal else { return }
                let transcript = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                if transcript.isEmpty {
                    continuation.resume(throwing: SpeechError.emptyTranscript)
                } else {
                    continuation.resume(returning: transcript)
                }
            }
        }
    }

    enum SpeechError: LocalizedError {
        case recognizerUnavailable
        case emptyTranscript

        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable: return "Speech recognizer is unavailable"
            case .emptyTranscript: return "No speech detected in recording"
            }
        }
    }
}
