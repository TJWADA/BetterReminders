import Foundation
import UserNotifications

extension Reminder {
    func toggleCompletion() {
        setCompleted(!isCompleted)
    }

    func updateNotificationForCompletion() async {
        for reminder in remindersAffectedByCompletionChange() {
            if reminder.isCompleted {
                await NotificationSchedulingService.cancel(for: reminder.id)
            } else {
                await NotificationSchedulingService.schedule(for: reminder)
            }
        }
    }

    private func remindersAffectedByCompletionChange() -> [Reminder] {
        if parent == nil {
            return [self] + subtasks
        }
        if let parent {
            return [self, parent]
        }
        return [self]
    }
}
