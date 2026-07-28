import Foundation
import UserNotifications

extension Reminder {
    func updateNotificationForCompletion() async {
        if isCompleted {
            await NotificationSchedulingService.cancel(for: id)
        } else {
            await NotificationSchedulingService.schedule(for: self)
        }
    }
}
