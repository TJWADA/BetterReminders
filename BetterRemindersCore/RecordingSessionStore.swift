import Foundation

public enum RecordingSessionStore {
    private static let suiteName = "group.com.betterreminders.shared"
    private static let isActiveKey = "recordingSessionActive"
    private static let pathKey = "recordingSessionPath"
    private static let stopRequestedKey = "recordingStopRequested"
    private static let actionButtonArmedKey = "actionButtonArmed"
    private static let openRecordTabKey = "openRecordTab"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    public static var isSessionActive: Bool {
        defaults.bool(forKey: isActiveKey)
    }

    public static var activeRecordingPath: String? {
        defaults.string(forKey: pathKey)
    }

    public static var isActionButtonArmed: Bool {
        defaults.bool(forKey: actionButtonArmedKey)
    }

    public static func markStarted(path: String) {
        defaults.set(true, forKey: isActiveKey)
        defaults.set(path, forKey: pathKey)
        defaults.set(false, forKey: stopRequestedKey)
    }

    public static func markStopped() {
        defaults.removeObject(forKey: isActiveKey)
        defaults.removeObject(forKey: pathKey)
        defaults.set(false, forKey: stopRequestedKey)
    }

    public static func setActionButtonArmed(_ armed: Bool) {
        defaults.set(armed, forKey: actionButtonArmedKey)
    }

    public static func markOpenRecordTab() {
        defaults.set(true, forKey: openRecordTabKey)
    }

    public static func consumeOpenRecordTab() -> Bool {
        guard defaults.bool(forKey: openRecordTabKey) else { return false }
        defaults.set(false, forKey: openRecordTabKey)
        return true
    }

    public static func requestStop() {
        defaults.set(true, forKey: stopRequestedKey)
    }

    public static func consumeStopRequest() -> Bool {
        guard defaults.bool(forKey: stopRequestedKey) else { return false }
        defaults.set(false, forKey: stopRequestedKey)
        return true
    }
}
