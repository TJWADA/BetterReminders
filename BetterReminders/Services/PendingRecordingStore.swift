import Foundation

enum PendingRecordingStore {
    private static let key = "pendingRecordingURL"
    private static let defaults = UserDefaults(suiteName: "group.com.betterreminders.shared") ?? .standard

    static func enqueue(_ url: URL) {
        defaults.set(url.path, forKey: key)
    }

    static func dequeue() -> URL? {
        guard let path = defaults.string(forKey: key) else { return nil }
        defaults.removeObject(forKey: key)
        return URL(fileURLWithPath: path)
    }

    static var hasPending: Bool {
        defaults.string(forKey: key) != nil
    }
}
