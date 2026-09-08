import XCTest
@testable import BetterReminders

final class ReminderFiltersTests: XCTestCase {
    private let list = TestFixtures.makeList()
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testPriorityFilterMatchesExpectedLevels() {
        XCTAssertTrue(PriorityFilter.all.matches(priority: 0))
        XCTAssertTrue(PriorityFilter.lowOrHigher.matches(priority: 1))
        XCTAssertFalse(PriorityFilter.highOnly.matches(priority: 2))
        XCTAssertTrue(PriorityFilter.highOnly.matches(priority: 3))
    }

    func testApplyHidesCompletedReminders() {
        let reminders = [
            TestFixtures.makeReminder(title: "Open", list: list),
            TestFixtures.makeReminder(title: "Done", isCompleted: true, list: list),
        ]

        let filtered = ReminderFilters.apply(
            to: reminders,
            searchText: "",
            hideCompleted: true,
            priorityFilter: .all
        )

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "Open")
    }

    func testApplyFiltersByPriorityAndSearch() {
        let reminders = [
            TestFixtures.makeReminder(title: "Buy milk", transcript: "groceries run", priority: 1, list: list),
            TestFixtures.makeReminder(title: "Ship release", priority: 3, list: TestFixtures.makeList(name: "Work")),
            TestFixtures.makeReminder(title: "Stretch", priority: 0, list: TestFixtures.makeList(name: "Health")),
        ]

        let filtered = ReminderFilters.apply(
            to: reminders,
            searchText: "milk",
            hideCompleted: false,
            priorityFilter: .lowOrHigher
        )

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "Buy milk")
    }

    func testIsOverdueRequiresIncompletePastDueDate() {
        let overdue = TestFixtures.makeReminder(
            title: "Late",
            dueDate: now.addingTimeInterval(-3600),
            list: list
        )
        let completed = TestFixtures.makeReminder(
            title: "Done late",
            dueDate: now.addingTimeInterval(-3600),
            isCompleted: true,
            list: list
        )

        XCTAssertTrue(ReminderFilters.isOverdue(overdue, now: now))
        XCTAssertFalse(ReminderFilters.isOverdue(completed, now: now))
    }

    func testIsDueTodayIncludesLaterTodayOnly() {
        let calendar = Calendar.current
        let laterToday = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now)!
        let earlierToday = calendar.date(bySettingHour: 0, minute: 1, second: 0, of: now)!

        let upcomingToday = TestFixtures.makeReminder(title: "Later", dueDate: laterToday, list: list)
        let missedToday = TestFixtures.makeReminder(title: "Missed", dueDate: earlierToday, list: list)

        XCTAssertTrue(ReminderFilters.isDueToday(upcomingToday, now: now))
        XCTAssertFalse(ReminderFilters.isDueToday(missedToday, now: now))
    }

    func testIsUpcomingCoversFutureDatesWithinWindow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 8, to: now)!

        let upcoming = TestFixtures.makeReminder(title: "Tomorrow", dueDate: tomorrow, list: list)
        let tooFar = TestFixtures.makeReminder(title: "Later", dueDate: nextWeek, list: list)

        XCTAssertTrue(ReminderFilters.isUpcoming(upcoming, now: now))
        XCTAssertFalse(ReminderFilters.isUpcoming(tooFar, now: now))
    }

    func testSortByDueDateOrdersSoonestFirst() {
        let later = TestFixtures.makeReminder(
            title: "Later",
            dueDate: now.addingTimeInterval(7200),
            list: list,
            createdAt: now
        )
        let sooner = TestFixtures.makeReminder(
            title: "Sooner",
            dueDate: now.addingTimeInterval(3600),
            list: list,
            createdAt: now
        )

        let sorted = ReminderFilters.sortByDueDate([later, sooner])
        XCTAssertEqual(sorted.map(\.title), ["Sooner", "Later"])
    }

    func testVisibleInListKeepsGracePeriodCompletions() {
        let open = TestFixtures.makeReminder(title: "Open", list: list)
        let inGrace = TestFixtures.makeReminder(
            title: "Grace",
            isCompleted: true,
            completedAt: now.addingTimeInterval(-1),
            list: list
        )
        let expired = TestFixtures.makeReminder(
            title: "Gone",
            isCompleted: true,
            completedAt: now.addingTimeInterval(-4),
            list: list
        )

        let visible = ReminderFilters.visibleInList([open, inGrace, expired], now: now)
        XCTAssertEqual(visible.map(\.title), ["Open", "Grace"])
    }

    func testRecentlyCompletedFiltersLastSevenDays() {
        let recent = TestFixtures.makeReminder(
            title: "Recent",
            isCompleted: true,
            completedAt: now.addingTimeInterval(-86_400),
            list: list
        )
        let old = TestFixtures.makeReminder(
            title: "Old",
            isCompleted: true,
            completedAt: now.addingTimeInterval(-864_000),
            list: list
        )

        let recentItems = ReminderFilters.recentlyCompleted([recent, old], now: now)
        XCTAssertEqual(recentItems.map(\.title), ["Recent"])
    }

    func testSortForListViewKeepsSubtasksUnderParent() {
        let parent = TestFixtures.makeReminder(
            title: "Pack",
            dueDate: now.addingTimeInterval(7200),
            list: list,
            createdAt: now
        )
        let child = TestFixtures.makeReminder(
            title: "Sunscreen",
            dueDate: now.addingTimeInterval(3600),
            list: list,
            createdAt: now.addingTimeInterval(-1)
        )
        let other = TestFixtures.makeReminder(
            title: "Call mom",
            dueDate: now.addingTimeInterval(1800),
            list: list,
            createdAt: now
        )
        XCTAssertTrue(child.indent(preceding: parent))

        let sorted = ReminderFilters.sortForListView([parent, child, other])
        XCTAssertEqual(sorted.map(\.title), ["Call mom", "Pack", "Sunscreen"])
    }

    func testVisibleInListKeepsCompletedParentWithIncompleteSubtask() {
        let parent = TestFixtures.makeReminder(
            title: "Pack",
            isCompleted: true,
            completedAt: now.addingTimeInterval(-10),
            list: list
        )
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        XCTAssertTrue(child.indent(preceding: parent))

        let visible = ReminderFilters.visibleInList([parent, child], now: now)
        XCTAssertEqual(Set(visible.map(\.title)), ["Pack", "Sunscreen"])
    }
}
