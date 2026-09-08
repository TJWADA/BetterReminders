import Foundation

@Observable
final class AppSettings {
    static let shared = AppSettings()

    private enum Keys {
        static let retainAudio = "retainAudio"
        static let hasSeededLists = "hasSeededLists"
        static let hideCompleted = "hideCompleted"
    }

    var retainAudio: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.retainAudio) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.retainAudio) }
    }

    var hasSeededLists: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasSeededLists) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasSeededLists) }
    }

    var hideCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hideCompleted) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hideCompleted) }
    }

    private init() {}
}
