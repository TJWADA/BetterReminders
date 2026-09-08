import XCTest
@testable import BetterReminders

final class ReminderSubtaskTests: XCTestCase {
    private let list = TestFixtures.makeList()
    private let otherList = TestFixtures.makeList(name: "Work")

    func testIndentNestsUnderPrecedingTopLevel() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)

        XCTAssertTrue(child.indent(preceding: parent))
        XCTAssertTrue(child.isSubtask)
        XCTAssertEqual(child.parent?.id, parent.id)
        XCTAssertEqual(parent.orderedSubtasks.map(\.id), [child.id])
        XCTAssertEqual(child.list?.id, list.id)
    }

    func testIndentBesideSubtaskBecomesSibling() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let first = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        let second = TestFixtures.makeReminder(title: "Chargers", list: list)

        XCTAssertTrue(first.indent(preceding: parent))
        XCTAssertTrue(second.indent(preceding: first))

        XCTAssertEqual(second.parent?.id, parent.id)
        XCTAssertEqual(parent.orderedSubtasks.map(\.title), ["Sunscreen", "Chargers"])
        XCTAssertGreaterThan(second.subtaskSortOrder, first.subtaskSortOrder)
    }

    func testCannotIndentAnExistingSubtask() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        let other = TestFixtures.makeReminder(title: "Call", list: list)

        XCTAssertTrue(child.indent(preceding: parent))
        XCTAssertFalse(child.canIndent(preceding: other))
        XCTAssertFalse(child.indent(preceding: other))
        XCTAssertEqual(child.parent?.id, parent.id)
    }

    func testCannotIndentAParentWithChildren() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        let neighbor = TestFixtures.makeReminder(title: "Trip", list: list)

        XCTAssertTrue(child.indent(preceding: parent))
        XCTAssertFalse(parent.canIndent(preceding: neighbor))
        XCTAssertFalse(parent.indent(preceding: neighbor))
        XCTAssertNil(parent.parent)
    }

    func testCannotIndentFirstRow() {
        let reminder = TestFixtures.makeReminder(title: "Pack", list: list)
        XCTAssertFalse(reminder.canIndent(preceding: nil))
        XCTAssertFalse(reminder.indent(preceding: nil))
        XCTAssertNil(reminder.parent)
    }

    func testOutdentClearsParent() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)

        XCTAssertTrue(child.indent(preceding: parent))
        child.outdent()

        XCTAssertNil(child.parent)
        XCTAssertFalse(child.isSubtask)
        XCTAssertTrue(parent.subtasks.isEmpty)
        XCTAssertEqual(child.subtaskSortOrder, 0)
    }

    func testIndentCopiesParentList() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: otherList)

        XCTAssertTrue(child.indent(preceding: parent))
        XCTAssertEqual(child.list?.id, list.id)
    }

    func testSyncSubtasksListMovesChildren() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        XCTAssertTrue(child.indent(preceding: parent))

        parent.list = otherList
        parent.syncSubtasksList()

        XCTAssertEqual(child.list?.id, otherList.id)
    }
}
