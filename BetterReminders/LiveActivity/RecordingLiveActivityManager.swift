import ActivityKit
import Foundation

enum RecordingLiveActivityManager {
    private static var currentActivity: Activity<RecordingActivityAttributes>?

    static func start(sessionID: String = UUID().uuidString) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
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
        } catch {
            print("Failed to start Live Activity: \(error)")
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
