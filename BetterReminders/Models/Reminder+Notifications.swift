import Foundation
import UserNotifications

extension Reminder {
    func toggleCompletion() {
        setCompleted(!isCompleted)
    }

    func updateNotificationForCompletion() async {
        if isCompleted {
            await NotificationSchedulingService.cancel(for: id)
        } else {
            await NotificationSchedulingService.schedule(for: self)
        }
    }
}
