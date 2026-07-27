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
        try await waitForRecordingFile(at: audioURL)

        guard let recognizer = SFSpeechRecognizer(locale: Locale.current), recognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }

        if recognizer.supportsOnDeviceRecognition {
            do {
                return try await recognize(audioURL: audioURL, recognizer: recognizer, onDevice: true)
            } catch {
                return try await recognize(audioURL: audioURL, recognizer: recognizer, onDevice: false)
            }
        }

        return try await recognize(audioURL: audioURL, recognizer: recognizer, onDevice: false)
    }

    private static func waitForRecordingFile(at url: URL) async throws {
        for _ in 0..<20 {
            if FileManager.default.fileExists(atPath: url.path),
               let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
               size > 0 {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        throw SpeechError.fileNotReady
    }

    private static func recognize(
        audioURL: URL,
        recognizer: SFSpeechRecognizer,
        onDevice: Bool
    ) async throws -> String {
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = onDevice

        let box = ContinuationBox<String>()

        return try await withCheckedThrowingContinuation { continuation in
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    box.resumeOnce(continuation) { $0.resume(throwing: error) }
                    return
                }

                guard let result else { return }

                if result.isFinal {
                    let transcript = result.bestTranscription.formattedString
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if transcript.isEmpty {
                        box.resumeOnce(continuation) { $0.resume(throwing: SpeechError.emptyTranscript) }
                    } else {
                        box.resumeOnce(continuation) { $0.resume(returning: transcript) }
                    }
                }
            }

            Task {
                try await Task.sleep(nanoseconds: 30_000_000_000)
                task.cancel()
                box.resumeOnce(continuation) {
                    $0.resume(throwing: SpeechError.transcriptionTimedOut)
                }
            }
        }
    }

    enum SpeechError: LocalizedError {
        case recognizerUnavailable
        case emptyTranscript
        case fileNotReady
        case transcriptionTimedOut

        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable:
                return "Speech recognizer is unavailable"
            case .emptyTranscript:
                return "No speech detected in recording"
            case .fileNotReady:
                return "Recording file was not ready to transcribe"
            case .transcriptionTimedOut:
                return "Speech transcription timed out"
            }
        }
    }
}

private final class ContinuationBox<T>: @unchecked Sendable {
    private var resumed = false
    private let lock = NSLock()

    func resumeOnce(_ continuation: CheckedContinuation<T, Error>, _ action: (CheckedContinuation<T, Error>) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard !resumed else { return }
        resumed = true
        action(continuation)
    }
}
