import Foundation

enum RecordingStopHandler {
    static func stopIfRecording() async throws {
        let recorder = AudioRecordingService.shared
        guard recorder.isRecording else { return }

        HapticHelper.recordingStopped()
        guard let url = recorder.stopRecording() else {
            throw RecordingStopError.stopFailed
        }

        guard recordingFileIsUsable(at: url) else {
            await RecordingCoordinator.shared.stopMeterTimer()
            await RecordingLiveActivityManager.showFailed(
                message: "Recording was too short. Speak clearly, then stop."
            )
            throw RecordingStopError.recordingTooShort
        }

        await RecordingCoordinator.shared.stopMeterTimer()
        await RecordingLiveActivityManager.showTranscribing()
        PendingRecordingStore.enqueue(url)
        BackgroundRecordingScheduler.scheduleProcessing()
        await RecordingCoordinator.shared.handleStoppedRecording(at: url)
    }

    static func recordingFileIsUsable(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path),
              let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return false
        }
        return size > 1024
    }

    enum RecordingStopError: LocalizedError {
        case stopFailed
        case recordingTooShort

        var errorDescription: String? {
            switch self {
            case .stopFailed:
                return "Could not stop recording. Open BetterReminders and try in-app Record once."
            case .recordingTooShort:
                return "Recording was too short or empty. Speak clearly, then stop."
            }
        }
    }
}
