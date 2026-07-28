import ActivityKit
import Foundation

enum RecordingPhase: String, Codable, Hashable {
    case recording
    case transcribing
    case parsing
    case completed
    case failed
}

struct RecordingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: RecordingPhase
        var elapsedSeconds: Int
        var audioLevel: Double
        var statusMessage: String
        var resultTitle: String?
        var resultListName: String?
        var resultListIcon: String?

        static var recording: ContentState {
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

    var sessionID: String
    var recordingStartDate: Date
}
