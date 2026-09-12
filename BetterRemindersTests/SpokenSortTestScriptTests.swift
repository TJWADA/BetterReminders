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

    func testCatalogPresetsHaveUniqueIdsAndIncludeGeneral() {
        let ids = SpokenSortCatalog.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
        XCTAssertEqual(ids, ["fitnessSplit", "firstRun", "student", "household", "minimal"])
        for preset in SpokenSortCatalog.all {
            XCTAssertTrue(preset.lists.contains { $0.name == "General" })
            XCTAssertFalse(preset.utterances.isEmpty)
        }
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

        SpokenSortTestScript.prepareLists(SpokenSortCatalog.fitnessSplit, modelContext: context)

        let lists = try context.fetch(
            FetchDescriptor<ReminderList>(sortBy: [SortDescriptor(\.sortOrder)])
        )
        let names = lists.map(\.name)
        XCTAssertEqual(names, SpokenSortCatalog.fitnessSplit.lists.map(\.name))
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

    func testPrepareListsCreatesFitnessFixtureOnEmptyStore() throws {
        let container = try makeContainer()
        let context = container.mainContext

        SpokenSortTestScript.prepareLists(SpokenSortCatalog.fitnessSplit, modelContext: context)

        let lists = try context.fetch(
            FetchDescriptor<ReminderList>(sortBy: [SortDescriptor(\.sortOrder)])
        )
        XCTAssertEqual(lists.map(\.name), SpokenSortCatalog.fitnessSplit.lists.map(\.name))
        XCTAssertEqual(lists.map(\.listDescription), SpokenSortCatalog.fitnessSplit.lists.map(\.description))
        XCTAssertEqual(lists.first?.name, "General")
        XCTAssertTrue(lists.first?.isDefault ?? false)
    }

    func testPrepareStudentLeavesNoWorkoutOrPersonal() throws {
        let container = try makeContainer()
        let context = container.mainContext
        context.insert(
            ReminderList(
                name: "Workout",
                icon: "figure.run",
                colorHex: "5AC8FA",
                sortOrder: 0
            )
        )
        context.insert(
            ReminderList(
                name: "Personal",
                icon: "person.fill",
                colorHex: "AF52DE",
                sortOrder: 1
            )
        )
        try context.save()

        SpokenSortTestScript.prepareLists(SpokenSortCatalog.student, modelContext: context)

        let names = try context.fetch(
            FetchDescriptor<ReminderList>(sortBy: [SortDescriptor(\.sortOrder)])
        ).map(\.name)
        XCTAssertEqual(names, SpokenSortCatalog.student.lists.map(\.name))
        XCTAssertFalse(names.contains("Workout"))
        XCTAssertFalse(names.contains("Personal"))
        XCTAssertTrue(names.contains("CSE 121"))
    }

    func testPrepareMinimalIsExactlyGeneralGroceriesWorkout() throws {
        let container = try makeContainer()
        let context = container.mainContext

        SpokenSortTestScript.prepareLists(SpokenSortCatalog.minimal, modelContext: context)

        let lists = try context.fetch(
            FetchDescriptor<ReminderList>(sortBy: [SortDescriptor(\.sortOrder)])
        )
        XCTAssertEqual(lists.map(\.name), ["General", "Groceries", "Workout"])
    }

    func testPrepareFirstRunHasPersonalAndNoWorkout() throws {
        let container = try makeContainer()
        let context = container.mainContext

        SpokenSortTestScript.prepareLists(SpokenSortCatalog.firstRun, modelContext: context)

        let lists = try context.fetch(
            FetchDescriptor<ReminderList>(sortBy: [SortDescriptor(\.sortOrder)])
        )
        let names = lists.map(\.name)
        XCTAssertTrue(names.contains("Personal"))
        XCTAssertTrue(names.contains("Health"))
        XCTAssertFalse(names.contains("Workout"))
        XCTAssertEqual(names, ListSeeder.defaultLists.map(\.name))

        let health = try XCTUnwrap(ListSeeder.findList(named: "Health", in: lists))
        XCTAssertEqual(
            health.listDescription,
            "Exercise, appointments, medications, and wellness."
        )
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Reminder.self, ReminderList.self, ProcessingJob.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
