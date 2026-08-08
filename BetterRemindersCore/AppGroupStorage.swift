import Foundation

public enum AppGroupStorage {
    /// Ensures the App Group Application Support directory exists before SwiftData opens its store.
    public static func prepareApplicationSupportDirectory() {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConfiguration.appGroupID
        ) else {
            return
        }

        let appSupport = container
            .appendingPathComponent("Library/Application Support", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: appSupport,
            withIntermediateDirectories: true
        )
    }
}
