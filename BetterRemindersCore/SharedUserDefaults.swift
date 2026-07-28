import Foundation

enum SharedUserDefaults {
    static let suiteName = "group.com.betterreminders.shared"

    static let store: UserDefaults = {
        let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName)
        let containerAvailable = containerURL != nil
        let suite = containerAvailable ? UserDefaults(suiteName: suiteName) : nil
        // #region agent log
        DebugSessionLog.write(
            location: "SharedUserDefaults.swift:store",
            message: "App group UserDefaults initialization",
            hypothesisId: "H1",
            data: [
                "containerAvailable": containerAvailable,
                "containerPath": containerURL?.path ?? "nil",
                "suiteResolved": suite != nil,
                "usingStandardFallback": suite == nil,
                "isMainThread": Thread.isMainThread,
            ]
        )
        // #endregion
        return suite ?? .standard
    }()
}
