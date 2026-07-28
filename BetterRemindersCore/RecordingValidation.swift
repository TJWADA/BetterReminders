import Foundation

public enum RecordingValidation {
    public static func recordingFileIsUsable(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path),
              let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return false
        }
        return size > AppConfiguration.Recording.minimumUsableFileBytes
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
