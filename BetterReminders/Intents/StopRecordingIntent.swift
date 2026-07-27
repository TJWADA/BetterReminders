import AppIntents
import Foundation

struct StopRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Recording"
    static var description = IntentDescription("Stop the current voice recording.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        try await RecordingStopHandler.stopIfRecording()
        return .result()
    }
}
