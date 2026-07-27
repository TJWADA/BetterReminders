import ActivityKit
import Foundation

enum RecordingLiveActivityError: LocalizedError {
    case disabled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .disabled:
            return "Live Activities are turned off. Enable them in Settings → BetterReminders → Live Activities."
        case .failed(let message):
            return "Could not start recording indicator: \(message)"
        }
    }
}

enum RecordingLiveActivityManager {
    private static var currentActivity: Activity<RecordingActivityAttributes>?

    @discardableResult
    static func start(sessionID: String = UUID().uuidString) async throws -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw RecordingLiveActivityError.disabled
        }
        await end()

        let attributes = RecordingActivityAttributes(sessionID: sessionID)
        let state = RecordingActivityAttributes.ContentState(
            isRecording: true,
            elapsedSeconds: 0,
            statusMessage: "Recording…"
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            return currentActivity != nil
        } catch {
            throw RecordingLiveActivityError.failed(error.localizedDescription)
        }
    }

    static func update(elapsedSeconds: Int, statusMessage: String = "Recording…") async {
        guard let activity = currentActivity else { return }
        let state = RecordingActivityAttributes.ContentState(
            isRecording: true,
            elapsedSeconds: elapsedSeconds,
            statusMessage: statusMessage
        )
        await activity.update(.init(state: state, staleDate: nil))
    }

    static func showProcessing(message: String) async {
        guard let activity = currentActivity else { return }
        let state = RecordingActivityAttributes.ContentState(
            isRecording: false,
            elapsedSeconds: 0,
            statusMessage: message
        )
        await activity.update(.init(state: state, staleDate: nil))
    }

    static func end() async {
        guard let activity = currentActivity else { return }
        let state = RecordingActivityAttributes.ContentState(
            isRecording: false,
            elapsedSeconds: 0,
            statusMessage: "Done"
        )
        await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
        currentActivity = nil
    }
}
