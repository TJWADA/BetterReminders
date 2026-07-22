import Foundation
import SwiftData

@Model
final class ReminderList {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var sortOrder: Int
    var isDefault: Bool
    @Relationship(deleteRule: .cascade, inverse: \Reminder.list)
    var reminders: [Reminder]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int,
        isDefault: Bool = false,
        reminders: [Reminder] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.reminders = reminders
    }

    var incompleteCount: Int {
        reminders.filter { !$0.isCompleted }.count
    }
}
