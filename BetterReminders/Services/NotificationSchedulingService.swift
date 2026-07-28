import Foundation
import UserNotifications

enum NotificationSchedulingService {
    private static func identifier(for reminderID: UUID) -> String {
        "due-\(reminderID.uuidString)"
    }

    static func shouldSchedule(for reminder: Reminder, at now: Date = Date()) -> Bool {
        guard !reminder.isCompleted, let dueDate = reminder.dueDate else { return false }
        return dueDate > now
    }

    static func schedule(for reminder: Reminder) async {
        await cancel(for: reminder.id)

        guard shouldSchedule(for: reminder) else { return }

        let dueDate = reminder.dueDate!

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        if let listName = reminder.list?.name {
            content.body = listName
        }
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier(for: reminder.id),
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancel(for reminderID: UUID) async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier(for: reminderID)])
    }

    static func rescheduleAll(reminders: [Reminder]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let dueIDs = Set(
            pending
                .map(\.identifier)
                .filter { $0.hasPrefix("due-") }
        )

        for reminder in reminders {
            let id = identifier(for: reminder.id)
            if !shouldSchedule(for: reminder) {
                if dueIDs.contains(id) {
                    await cancel(for: reminder.id)
                }
            } else {
                await schedule(for: reminder)
            }
        }
    }
}
