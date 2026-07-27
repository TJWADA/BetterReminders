import Foundation

/// Persists recording state across Action Button intent invocations (separate process lifecycles).
enum RecordingSessionStore {
    private static let suiteName = "group.com.betterreminders.shared"
    private static let isActiveKey = "recordingSessionActive"
    private static let pathKey = "recordingSessionPath"
    private static let stopRequestedKey = "recordingStopRequested"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static var isSessionActive: Bool {
        defaults.bool(forKey: isActiveKey)
    }

    static var activeRecordingPath: String? {
        defaults.string(forKey: pathKey)
    }

    static func markStarted(path: String) {
        defaults.set(true, forKey: isActiveKey)
        defaults.set(path, forKey: pathKey)
        defaults.set(false, forKey: stopRequestedKey)
    }

    static func markStopped() {
        defaults.removeObject(forKey: isActiveKey)
        defaults.removeObject(forKey: pathKey)
        defaults.set(false, forKey: stopRequestedKey)
    }

    static func requestStop() {
        defaults.set(true, forKey: stopRequestedKey)
    }

    static func consumeStopRequest() -> Bool {
        guard defaults.bool(forKey: stopRequestedKey) else { return false }
        defaults.set(false, forKey: stopRequestedKey)
        return true
    }
}
