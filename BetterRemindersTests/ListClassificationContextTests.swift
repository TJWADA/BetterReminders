import XCTest
@testable import BetterReminders

final class ListClassificationContextTests: XCTestCase {
    func testFormatListsBlockIncludesDescriptionExamplesAndCorrections() {
        let contexts = [
            ListClassificationContext(
                name: "Groceries",
                description: "Food and household shopping items.",
                exampleTitles: ["milk", "eggs"],
                misclassificationNotes: ["Belongs here (moved from General): 'buy oat milk'"]
            ),
            ListClassificationContext(
                name: "CSE 121",
                description: "",
                exampleTitles: [],
                misclassificationNotes: []
            ),
        ]

        let formatted = ListClassificationContext.formatListsBlock(contexts)

        XCTAssertTrue(formatted.contains("- Groceries"))
        XCTAssertTrue(formatted.contains("Description: Food and household shopping items."))
        XCTAssertTrue(formatted.contains("Current incomplete reminders: milk, eggs"))
        XCTAssertTrue(formatted.contains("Past corrections: Belongs here (moved from General): 'buy oat milk'"))
        XCTAssertTrue(formatted.contains("- CSE 121"))
        XCTAssertTrue(formatted.contains("Description: (none)"))
        XCTAssertTrue(formatted.contains("Current incomplete reminders: (none)"))
        XCTAssertTrue(formatted.contains("Past corrections: (none)"))
    }

    func testMakeSystemPromptMentionsListContextGuidance() {
        let listsText = ListClassificationContext.formatListsBlock([
            ListClassificationContext(
                name: "Work",
                description: "Job tasks",
                exampleTitles: ["Send report"],
                misclassificationNotes: []
            )
        ])

        let prompt = ReminderParserService.makeSystemPrompt(
            now: "2026-08-09T00:00:00Z",
            listsText: listsText,
            fallbackList: "General"
        )

        XCTAssertTrue(prompt.contains("Available lists:"))
        XCTAssertTrue(prompt.contains("Description: Job tasks"))
        XCTAssertTrue(prompt.contains("Current incomplete reminders: Send report"))
        XCTAssertTrue(prompt.contains("Use each list's description, current incomplete reminders, and past corrections"))
        XCTAssertTrue(prompt.contains("If none fit, use \"General\"."))
    }

    func testRecordMoveCorrectionUpdatesSourceAndDestinationLogs() {
        let source = TestFixtures.makeList(name: "General")
        let destination = ReminderList(
            name: "Groceries",
            icon: "cart.fill",
            colorHex: "34C759",
            sortOrder: 1
        )

        ReminderList.recordMoveCorrection(
            from: source,
            to: destination,
            reminderTitle: "Buy milk"
        )

        XCTAssertEqual(source.misclassificationLog.count, 1)
        XCTAssertEqual(
            source.misclassificationLog.first,
            "Does not belong here (moved to Groceries): 'Buy milk'"
        )
        XCTAssertEqual(destination.misclassificationLog.count, 1)
        XCTAssertEqual(
            destination.misclassificationLog.first,
            "Belongs here (moved from General): 'Buy milk'"
        )
    }

    func testMisclassificationLogIsCapped() {
        let list = TestFixtures.makeList()
        for index in 1...20 {
            list.appendMisclassificationNote("note \(index)")
        }

        XCTAssertEqual(list.misclassificationLog.count, ReminderList.misclassificationLogLimit)
        XCTAssertEqual(list.misclassificationLog.first, "note 20")
        XCTAssertEqual(list.misclassificationLog.last, "note 6")
    }

    func testContextFromListUsesNewestIncompleteTitles() {
        let list = TestFixtures.makeList(name: "Work")
        list.listDescription = "Job tasks"
        let older = TestFixtures.makeReminder(
            title: "Older task",
            list: list,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let newer = TestFixtures.makeReminder(
            title: "Newer task",
            list: list,
            createdAt: Date(timeIntervalSince1970: 200)
        )
        let completed = TestFixtures.makeReminder(
            title: "Done task",
            isCompleted: true,
            list: list,
            createdAt: Date(timeIntervalSince1970: 300)
        )
        list.reminders = [older, newer, completed]
        list.misclassificationLog = ["Belongs here (moved from General): 'Send invoice'"]

        let context = ListClassificationContext.from(list: list)

        XCTAssertEqual(context.name, "Work")
        XCTAssertEqual(context.description, "Job tasks")
        XCTAssertEqual(context.exampleTitles, ["Newer task", "Older task"])
        XCTAssertEqual(context.misclassificationNotes, ["Belongs here (moved from General): 'Send invoice'"])
    }
}
