import UserNotifications
import XCTest
@testable import BetterReminders

final class NotificationSchedulingServiceTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() async throws {
        try await super.setUp()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func testShouldScheduleRequiresFutureIncompleteDueDate() {
        let list = TestFixtures.makeList()
        let eligible = TestFixtures.makeReminder(
            title: "Future",
            dueDate: now.addingTimeInterval(3600),
            list: list
        )
        let completed = TestFixtures.makeReminder(
            title: "Future done",
            dueDate: now.addingTimeInterval(3600),
            isCompleted: true,
            list: list
        )
        let past = TestFixtures.makeReminder(
            title: "Past",
            dueDate: now.addingTimeInterval(-60),
            list: list
        )
        let noDate = TestFixtures.makeReminder(title: "Anytime", list: list)

        XCTAssertTrue(NotificationSchedulingService.shouldSchedule(for: eligible, at: now))
        XCTAssertFalse(NotificationSchedulingService.shouldSchedule(for: completed, at: now))
        XCTAssertFalse(NotificationSchedulingService.shouldSchedule(for: past, at: now))
        XCTAssertFalse(NotificationSchedulingService.shouldSchedule(for: noDate, at: now))
    }

    func testScheduleDoesNotEnqueueIneligibleReminders() async {
        let reminder = TestFixtures.makeReminder(
            title: "Already done",
            dueDate: Date().addingTimeInterval(3600),
            isCompleted: true,
            list: TestFixtures.makeList()
        )
        let expectedID = "due-\(reminder.id.uuidString)"

        await NotificationSchedulingService.schedule(for: reminder)

        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        XCTAssertNil(pending.first { $0.identifier == expectedID })
    }

    func testCancelRemovesMatchingPendingNotification() async {
        let reminder = TestFixtures.makeReminder(
            title: "Buy milk",
            dueDate: Date().addingTimeInterval(3600),
            list: TestFixtures.makeList(name: "Groceries")
        )
        let expectedID = "due-\(reminder.id.uuidString)"
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.list?.name ?? ""
        let request = UNNotificationRequest(
            identifier: expectedID,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)

        await NotificationSchedulingService.cancel(for: reminder.id)

        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        XCTAssertNil(pending.first { $0.identifier == expectedID })
    }
}
