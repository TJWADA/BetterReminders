import AppIntents
import Foundation

public struct StopRecordingIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Stop Recording"
    public static var description = IntentDescription("Stop the current voice recording.")
    public static var openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        try await RecordingStopHandler.stopIfRecording()
        return .result()
    }
}
