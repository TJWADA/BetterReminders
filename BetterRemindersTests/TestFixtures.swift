import Foundation
@testable import BetterReminders

enum TestFixtures {
    static func makeList(name: String = "Groceries") -> ReminderList {
        ReminderList(name: name, icon: "cart.fill", colorHex: "34C759", sortOrder: 0)
    }

    static func makeReminder(
        title: String,
        transcript: String = "",
        dueDate: Date? = nil,
        priority: Int = 0,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        needsManualSort: Bool = false,
        list: ReminderList? = nil,
        createdAt: Date = Date(),
        subtaskSortOrder: Int = 0
    ) -> Reminder {
        let reminder = Reminder(
            title: title,
            rawTranscript: transcript,
            dueDate: dueDate,
            priority: priority,
            isCompleted: isCompleted,
            completedAt: completedAt,
            needsManualSort: needsManualSort,
            createdAt: createdAt,
            list: list,
            subtaskSortOrder: subtaskSortOrder
        )
        if let list, !list.reminders.contains(where: { $0.id == reminder.id }) {
            list.reminders.append(reminder)
        }
        return reminder
    }
}
