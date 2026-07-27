import AppIntents
import Foundation

/// Widget-target intent: sets a shared flag read by RecordingCoordinator in the app process.
struct StopRecordingWidgetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Recording"
    static var description = IntentDescription("Stop the current voice recording.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        RecordingSessionStore.requestStop()
        return .result()
    }
}
