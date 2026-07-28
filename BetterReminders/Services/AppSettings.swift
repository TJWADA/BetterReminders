import Foundation

@Observable
final class AppSettings {
    static let shared = AppSettings()

    private enum Keys {
        static let retainAudio = "retainAudio"
        static let hasSeededLists = "hasSeededLists"
        static let recentCorrections = "recentCorrections"
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

    var recentCorrections: [String] {
        get { UserDefaults.standard.stringArray(forKey: Keys.recentCorrections) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: Keys.recentCorrections) }
    }

    var hideCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hideCompleted) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hideCompleted) }
    }

    func recordCorrection(from oldList: String, to newList: String, reminderTitle: String) {
        var corrections = recentCorrections
        corrections.insert("'\(reminderTitle)' moved from \(oldList) to \(newList)", at: 0)
        recentCorrections = Array(corrections.prefix(5))
    }

    private init() {}
}
