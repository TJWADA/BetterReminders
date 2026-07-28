import Foundation

enum SharedUserDefaults {
    static let suiteName = AppConfiguration.appGroupID

    static var store: UserDefaults {
        storage
    }

    private static let storage: UserDefaults = {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName),
              FileManager.default.isWritableFile(atPath: container.path),
              let suite = UserDefaults(suiteName: suiteName) else {
            return .standard
        }
        return suite
    }()
}
