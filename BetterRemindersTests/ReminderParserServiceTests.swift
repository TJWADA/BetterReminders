import XCTest
@testable import BetterReminders

final class ReminderParserServiceTests: XCTestCase {
    func testPriorityValueMapsStringsAndNumbers() {
        XCTAssertEqual(ReminderParserService.priorityValue(from: "high"), 3)
        XCTAssertEqual(ReminderParserService.priorityValue(from: "medium"), 2)
        XCTAssertEqual(ReminderParserService.priorityValue(from: "low"), 1)
        XCTAssertEqual(ReminderParserService.priorityValue(from: "none"), 0)
        XCTAssertEqual(ReminderParserService.priorityValue(from: nil), 0)
    }

    func testParseDueDateAcceptsISO8601Values() {
        let parsed = ReminderParserService.parseDueDate("2026-07-28T09:00:00Z")
        XCTAssertNotNil(parsed)

        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 28
        components.hour = 9
        components.minute = 0
        components.timeZone = TimeZone(secondsFromGMT: 0)
        XCTAssertTrue(calendar.isDate(parsed!, equalTo: calendar.date(from: components)!, toGranularity: .minute))
    }

    func testParseDueDateReturnsNilForEmptyValues() {
        XCTAssertNil(ReminderParserService.parseDueDate(nil))
        XCTAssertNil(ReminderParserService.parseDueDate(""))
        XCTAssertNil(ReminderParserService.parseDueDate("null"))
    }

    func testParsedReminderDecodesNumericPriority() throws {
        let data = """
        {
            "title": "Buy milk",
            "list": "Groceries",
            "priority": 3
        }
        """.data(using: .utf8)!

        let reminder = try JSONDecoder().decode(ParsedReminder.self, from: data)
        XCTAssertEqual(reminder.title, "Buy milk")
        XCTAssertEqual(reminder.priority, "3")
    }

    func testFormatListsBlockEmptyReturnsNone() {
        XCTAssertEqual(ListClassificationContext.formatListsBlock([]), "None")
    }
}
