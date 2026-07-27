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
        list: ReminderList? = nil,
        createdAt: Date = Date()
    ) -> Reminder {
        Reminder(
            title: title,
            rawTranscript: transcript,
            dueDate: dueDate,
            priority: priority,
            isCompleted: isCompleted,
            createdAt: createdAt,
            list: list
        )
    }
}
