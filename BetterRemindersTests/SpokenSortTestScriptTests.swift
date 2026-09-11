import SwiftData
import XCTest
@testable import BetterReminders

@MainActor
final class SpokenSortTestScriptTests: XCTestCase {
    func testScorePassesWhenUniqueListsMatchRegardlessOfDuplicates() {
        XCTAssertTrue(SpokenSortTestScript.score(expected: ["Groceries"], actual: ["Groceries"]))
        XCTAssertTrue(
            SpokenSortTestScript.score(
                expected: ["Groceries"],
                actual: ["groceries", "Groceries"]
            )
        )
        XCTAssertTrue(
            SpokenSortTestScript.score(
                expected: ["Groceries", "Work"],
                actual: ["Work", "Groceries"]
            )
        )
    }

    func testScoreFailsWhenAListIsMissing() {
        XCTAssertFalse(
            SpokenSortTestScript.score(
                expected: ["Groceries", "Work"],
                actual: ["Groceries"]
            )
        )
        XCTAssertFalse(SpokenSortTestScript.score(expected: ["Groceries"], actual: []))
    }

    func testScoreFailsWhenAnUnexpectedListAppears() {
        XCTAssertFalse(
            SpokenSortTestScript.score(
                expected: ["Groceries"],
                actual: ["Groceries", "Work"]
            )
        )
        XCTAssertFalse(
            SpokenSortTestScript.score(
                expected: ["Groceries", "Work"],
                actual: ["Groceries", "Work", "General"]
            )
        )
    }

    func testPrepareListsReplacesExtrasAndClearsReminders() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let general = ReminderList(
            name: "General",
            icon: "tray.fill",
            colorHex: "8E8E93",
            sortOrder: 0,
            isDefault: true,
            listDescription: "old general"
        )
        let groceries = ReminderList(
            name: "Groceries",
            icon: "cart.fill",
            colorHex: "34C759",
            sortOrder: 1,
            listDescription: "old groceries"
        )
        let personal = ReminderList(
            name: "Personal",
            icon: "person.fill",
            colorHex: "AF52DE",
            sortOrder: 2,
            listDescription: "personal life"
        )
        context.insert(general)
        context.insert(groceries)
        context.insert(personal)
        context.insert(TestFixtures.makeReminder(title: "Milk", list: groceries))
        context.insert(TestFixtures.makeReminder(title: "Text Mom", list: personal))
        try context.save()

        SpokenSortTestScript.prepareLists(modelContext: context)

        let lists = try context.fetch(
            FetchDescriptor<ReminderList>(sortBy: [SortDescriptor(\.sortOrder)])
        )
        let names = lists.map(\.name)
        XCTAssertEqual(names, SpokenSortTestScript.lists.map(\.name))
        XCTAssertFalse(names.contains("Personal"))

        let groceriesList = try XCTUnwrap(ListSeeder.findList(named: "Groceries", in: lists))
        XCTAssertEqual(
            groceriesList.listDescription,
            "Food and household shopping items to buy at a store."
        )
        XCTAssertTrue(groceriesList.reminders.isEmpty)

        let workout = try XCTUnwrap(ListSeeder.findList(named: "Workout", in: lists))
        XCTAssertEqual(
            workout.listDescription,
            "Exercise, gym sessions, training, stretches, and sports. Not medical care."
        )

        let remainingReminders = try context.fetch(FetchDescriptor<Reminder>())
        XCTAssertTrue(remainingReminders.isEmpty)
    }

    func testPrepareListsCreatesFixtureOnEmptyStore() throws {
        let container = try makeContainer()
        let context = container.mainContext

        SpokenSortTestScript.prepareLists(modelContext: context)

        let lists = try context.fetch(
            FetchDescriptor<ReminderList>(sortBy: [SortDescriptor(\.sortOrder)])
        )
        XCTAssertEqual(lists.map(\.name), SpokenSortTestScript.lists.map(\.name))
        XCTAssertEqual(lists.map(\.listDescription), SpokenSortTestScript.lists.map(\.description))
        XCTAssertEqual(lists.first?.name, "General")
        XCTAssertTrue(lists.first?.isDefault ?? false)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Reminder.self, ReminderList.self, ProcessingJob.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
