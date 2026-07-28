import Foundation

public enum RecordingStopHandler {
    public static func stopIfRecording() async throws {
        let recorder = AudioRecordingService.shared
        guard recorder.isRecording else { return }

        HapticHelper.recordingStopped()
        guard let url = recorder.stopRecording() else {
            throw RecordingStopError.stopFailed
        }

        guard recordingFileIsUsable(at: url) else {
            throw RecordingStopError.recordingTooShort
        }

        PendingRecordingStore.enqueue(url)
        BackgroundRecordingScheduler.scheduleProcessing()
        await RecordingCoordinator.shared.handleStoppedRecording(at: url)
    }

    public static func recordingFileIsUsable(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path),
              let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return false
        }
        return size > 1024
    }

    public enum RecordingStopError: LocalizedError {
        case stopFailed
        case recordingTooShort

        public var errorDescription: String? {
            switch self {
            case .stopFailed:
                return "Could not stop recording. Open BetterReminders and try in-app Record once."
            case .recordingTooShort:
                return "Recording was too short or empty. Speak clearly, then stop."
            }
        }
    }
}
