import ActivityKit
import Foundation

public enum RecordingLiveActivityError: LocalizedError, CustomNSError {
    case disabled
    case failed(String)

    public static var errorDomain: String { "BetterReminders.RecordingLiveActivityError" }

    public var errorCode: Int {
        switch self {
        case .disabled: return 1
        case .failed: return 2
        }
    }

    public var errorDescription: String? {
        switch self {
        case .disabled:
            return "Live Activities are turned off. Enable them in Settings → BetterReminders → Live Activities."
        case .failed(let message):
            return "Could not start recording indicator: \(message)"
        }
    }
}

public enum RecordingLiveActivityManager {
    private static var currentActivity: Activity<RecordingActivityAttributes>?

    @discardableResult
    public static func start(sessionID: String = UUID().uuidString) async throws -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw RecordingLiveActivityError.disabled
        }
        await endImmediate()

        let attributes = RecordingActivityAttributes(
            sessionID: sessionID,
            recordingStartDate: Date()
        )
        let state = RecordingActivityAttributes.ContentState.recording

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

    public static func updateRecording(
        elapsedSeconds: Int,
        audioLevel: Double,
        statusMessage: String = "Recording…"
    ) async {
        await update(state: RecordingActivityAttributes.ContentState(
            phase: .recording,
            elapsedSeconds: elapsedSeconds,
            audioLevel: audioLevel,
            statusMessage: statusMessage,
            resultTitle: nil,
            resultListName: nil,
            resultListIcon: nil
        ))
    }

    public static func showTranscribing() async {
        await update(state: RecordingActivityAttributes.ContentState(
            phase: .transcribing,
            elapsedSeconds: 0,
            audioLevel: 0,
            statusMessage: "Transcribing voice…",
            resultTitle: nil,
            resultListName: nil,
            resultListIcon: nil
        ))
    }

    public static func showParsing() async {
        await update(state: RecordingActivityAttributes.ContentState(
            phase: .parsing,
            elapsedSeconds: 0,
            audioLevel: 0,
            statusMessage: "Sorting into list…",
            resultTitle: nil,
            resultListName: nil,
            resultListIcon: nil
        ))
    }

    public static func showCompleted(title: String, listName: String, listIcon: String) async {
        let state = RecordingActivityAttributes.ContentState(
            phase: .completed,
            elapsedSeconds: 0,
            audioLevel: 0,
            statusMessage: "Added to \(listName)",
            resultTitle: title,
            resultListName: listName,
            resultListIcon: listIcon
        )
        await update(state: state)
        await endAfterDelay(seconds: 4, state: state)
    }

    public static func showFailed(message: String) async {
        let state = RecordingActivityAttributes.ContentState(
            phase: .failed,
            elapsedSeconds: 0,
            audioLevel: 0,
            statusMessage: message,
            resultTitle: nil,
            resultListName: nil,
            resultListIcon: nil
        )
        await update(state: state)
        await endAfterDelay(seconds: 6, state: state)
    }

    public static func endImmediate() async {
        guard let activity = resolveActivity() else { return }
        let state = RecordingActivityAttributes.ContentState(
            phase: .failed,
            elapsedSeconds: 0,
            audioLevel: 0,
            statusMessage: "Done",
            resultTitle: nil,
            resultListName: nil,
            resultListIcon: nil
        )
        await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
        currentActivity = nil
    }

    private static func endAfterDelay(seconds: TimeInterval, state: RecordingActivityAttributes.ContentState) async {
        guard let activity = resolveActivity() else { return }
        await activity.end(
            .init(state: state, staleDate: nil),
            dismissalPolicy: .after(Date().addingTimeInterval(seconds))
        )
        currentActivity = nil
    }

    private static func update(state: RecordingActivityAttributes.ContentState) async {
        guard let activity = resolveActivity() else { return }
        await activity.update(.init(state: state, staleDate: nil))
    }

    private static func resolveActivity() -> Activity<RecordingActivityAttributes>? {
        if let currentActivity {
            return currentActivity
        }
        let existing = Activity<RecordingActivityAttributes>.activities.first
        currentActivity = existing
        return existing
    }
}
