import ActivityKit
import Foundation

public enum RecordingPhase: String, Codable, Hashable {
    case recording
    case transcribing
    case parsing
    case completed
    case failed
}

public struct RecordingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var phase: RecordingPhase
        public var elapsedSeconds: Int
        public var audioLevel: Double
        public var statusMessage: String
        public var resultTitle: String?
        public var resultListName: String?
        public var resultListIcon: String?

        public init(
            phase: RecordingPhase,
            elapsedSeconds: Int,
            audioLevel: Double,
            statusMessage: String,
            resultTitle: String?,
            resultListName: String?,
            resultListIcon: String?
        ) {
            self.phase = phase
            self.elapsedSeconds = elapsedSeconds
            self.audioLevel = audioLevel
            self.statusMessage = statusMessage
            self.resultTitle = resultTitle
            self.resultListName = resultListName
            self.resultListIcon = resultListIcon
        }

        public static var recording: ContentState {
            ContentState(
                phase: .recording,
                elapsedSeconds: 0,
                audioLevel: 0,
                statusMessage: "Recording…",
                resultTitle: nil,
                resultListName: nil,
                resultListIcon: nil
            )
        }
    }

    public var sessionID: String
    public var recordingStartDate: Date

    public init(sessionID: String, recordingStartDate: Date) {
        self.sessionID = sessionID
        self.recordingStartDate = recordingStartDate
    }
}
