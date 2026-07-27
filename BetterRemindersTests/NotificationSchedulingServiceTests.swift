import XCTest
@testable import BetterReminders

final class NotificationSchedulingServiceTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

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

    func testCancelAndScheduleDoNotCrash() async {
        let reminder = TestFixtures.makeReminder(
            title: "Future",
            dueDate: Date().addingTimeInterval(3600),
            list: TestFixtures.makeList()
        )

        await NotificationSchedulingService.schedule(for: reminder)
        await NotificationSchedulingService.cancel(for: reminder.id)
    }
}
