import Foundation

enum SharedUserDefaults {
    static let suiteName = "group.com.betterreminders.shared"

    static let store: UserDefaults = {
        let containerAvailable = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName) != nil
        let suite = containerAvailable ? UserDefaults(suiteName: suiteName) : nil
        return suite ?? .standard
    }()
}
