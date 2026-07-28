import Foundation

@MainActor
public final class RecordingCoordinator {
    public static let shared = RecordingCoordinator()

    private init() {}

    public func handleStoppedRecording(at url: URL) async {
        NotificationCenter.default.post(
            name: .recordingDidFinish,
            object: nil,
            userInfo: ["audioURL": url]
        )
    }
}

public extension Notification.Name {
    static let recordingDidFinish = Notification.Name("recordingDidFinish")
}
