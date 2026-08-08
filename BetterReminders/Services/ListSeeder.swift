import Foundation
import SwiftData
import BetterRemindersCore

enum ListSeeder {
    static let defaultLists: [(name: String, icon: String, colorHex: String)] = [
        ("General", "tray.fill", "8E8E93"),
        ("Groceries", "cart.fill", "34C759"),
        ("Work", "briefcase.fill", "007AFF"),
        ("Personal", "person.fill", "AF52DE"),
        ("Health", "heart.fill", "FF3B30"),
        ("Errands", "car.fill", "FF9500"),
        ("Ideas", "lightbulb.fill", "FFD60A"),
    ]

    @MainActor
    static func seedIfNeeded(modelContext: ModelContext) {
        guard !AppSettings.shared.hasSeededLists else { return }

        for (index, list) in defaultLists.enumerated() {
            let reminderList = ReminderList(
                name: list.name,
                icon: list.icon,
                colorHex: list.colorHex,
                sortOrder: index,
                isDefault: true
            )
            modelContext.insert(reminderList)
        }

        AppSettings.shared.hasSeededLists = true
        try? modelContext.save()
    }

    @MainActor
    static func ensureGeneralListExists(modelContext: ModelContext) {
        let lists = (try? modelContext.fetch(FetchDescriptor<ReminderList>())) ?? []
        if findList(named: AppConfiguration.fallbackListName, in: lists) != nil {
            return
        }

        let minOrder = lists.map(\.sortOrder).min() ?? 0
        let general = ReminderList(
            name: "General",
            icon: "tray.fill",
            colorHex: "8E8E93",
            sortOrder: minOrder - 1,
            isDefault: true
        )
        modelContext.insert(general)
        try? modelContext.save()
    }

    static func findList(named name: String, in lists: [ReminderList]) -> ReminderList? {
        lists.first { $0.name.lowercased() == name.lowercased() }
    }

    static func fallbackList(from lists: [ReminderList]) -> ReminderList? {
        findList(named: AppConfiguration.fallbackListName, in: lists) ?? lists.first
    }
}
