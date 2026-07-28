import Foundation

public enum PendingRecordingStore {
    private static let key = "pendingRecordingURL"
    private static let defaults = SharedUserDefaults.store

    public static func enqueue(_ url: URL) {
        defaults.set(url.path, forKey: key)
    }

    public static func dequeue() -> URL? {
        guard let path = defaults.string(forKey: key) else { return nil }
        defaults.removeObject(forKey: key)
        return URL(fileURLWithPath: path)
    }
}
