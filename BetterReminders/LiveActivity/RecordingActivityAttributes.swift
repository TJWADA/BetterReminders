import ActivityKit
import Foundation

struct RecordingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isRecording: Bool
        var elapsedSeconds: Int
        var statusMessage: String
    }

    var sessionID: String
}
