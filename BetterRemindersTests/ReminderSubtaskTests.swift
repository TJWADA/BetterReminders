import XCTest
@testable import BetterReminders

final class ReminderSubtaskTests: XCTestCase {
    private let list = TestFixtures.makeList()
    private let otherList = TestFixtures.makeList(name: "Work")

    func testNestUnderTopLevelParent() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)

        XCTAssertTrue(child.nest(under: parent))
        XCTAssertTrue(child.isSubtask)
        XCTAssertEqual(child.parent?.id, parent.id)
        XCTAssertEqual(parent.orderedSubtasks.map(\.id), [child.id])
        XCTAssertEqual(child.list?.id, list.id)
        XCTAssertFalse(parent.areSubtasksCollapsed)
    }

    func testDropOntoSubtaskBecomesSibling() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let first = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        let second = TestFixtures.makeReminder(title: "Chargers", list: list)
        XCTAssertTrue(first.nest(under: parent))

        let visible = [parent, first, second]
        let action = ReminderDropResolver.action(
            dragging: second,
            droppingOn: first,
            zone: .onto,
            visible: visible
        )
        XCTAssertNotNil(action)
        XCTAssertTrue(second.apply(action!, topLevel: visible))

        XCTAssertEqual(second.parent?.id, parent.id)
        XCTAssertEqual(parent.orderedSubtasks.map(\.title), ["Sunscreen", "Chargers"])
        XCTAssertGreaterThan(second.subtaskSortOrder, first.subtaskSortOrder)
    }

    func testCannotNestAParentWithChildren() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        let neighbor = TestFixtures.makeReminder(title: "Trip", list: list)
        XCTAssertTrue(child.nest(under: parent))

        XCTAssertFalse(parent.canNest(under: neighbor))
        XCTAssertFalse(parent.nest(under: neighbor))
        XCTAssertNil(parent.parent)
        XCTAssertEqual(child.parent?.id, parent.id)
    }

    func testCannotNestUnderASubtask() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        let other = TestFixtures.makeReminder(title: "Call", list: list)
        XCTAssertTrue(child.nest(under: parent))

        XCTAssertFalse(other.canNest(under: child))
        XCTAssertFalse(other.nest(under: child))
        XCTAssertNil(other.parent)
    }

    func testCannotNestUnderSelf() {
        let reminder = TestFixtures.makeReminder(title: "Pack", list: list)
        XCTAssertFalse(reminder.canNest(under: reminder))
        XCTAssertFalse(reminder.nest(under: reminder))
    }

    func testOutdentClearsParentAndPlacesAmongTopLevel() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list, subtaskSortOrder: 0)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list, subtaskSortOrder: 1)
        XCTAssertTrue(child.nest(under: parent))

        let topLevel = [parent, child]
        XCTAssertTrue(child.outdent(before: nil, topLevel: topLevel))

        XCTAssertNil(child.parent)
        XCTAssertFalse(child.isSubtask)
        XCTAssertTrue(parent.subtasks.isEmpty)
        XCTAssertEqual(parent.subtaskSortOrder, 0)
        XCTAssertEqual(child.subtaskSortOrder, 1)
    }

    func testOutdentBeforeNeighborInsertsAtThatSlot() {
        let first = TestFixtures.makeReminder(title: "A", list: list, subtaskSortOrder: 0)
        let parent = TestFixtures.makeReminder(title: "B", list: list, subtaskSortOrder: 1)
        let child = TestFixtures.makeReminder(title: "Child", list: list, subtaskSortOrder: 2)
        XCTAssertTrue(child.nest(under: parent))

        XCTAssertTrue(child.outdent(before: first, topLevel: [first, parent, child]))
        XCTAssertNil(child.parent)
        XCTAssertEqual(child.subtaskSortOrder, 0)
        XCTAssertEqual(first.subtaskSortOrder, 1)
        XCTAssertEqual(parent.subtaskSortOrder, 2)
    }

    func testNestCopiesParentList() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: otherList)

        XCTAssertTrue(child.nest(under: parent))
        XCTAssertEqual(child.list?.id, list.id)
    }

    func testSyncSubtasksListMovesChildren() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        XCTAssertTrue(child.nest(under: parent))

        parent.list = otherList
        parent.syncSubtasksList()

        XCTAssertEqual(child.list?.id, otherList.id)
    }

    func testMoveAmongTopLevelKeepsChildrenAttached() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list, subtaskSortOrder: 0)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list, subtaskSortOrder: 1)
        let other = TestFixtures.makeReminder(title: "Call", list: list, subtaskSortOrder: 2)
        XCTAssertTrue(child.nest(under: parent))

        XCTAssertTrue(parent.moveAmongSiblings(before: nil, topLevel: [parent, other]))

        XCTAssertEqual(other.subtaskSortOrder, 0)
        XCTAssertEqual(parent.subtaskSortOrder, 1)
        XCTAssertEqual(child.parent?.id, parent.id)
        XCTAssertEqual(parent.orderedSubtasks.map(\.title), ["Sunscreen"])
    }

    func testMoveAmongSubtaskSiblings() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let first = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        let second = TestFixtures.makeReminder(title: "Chargers", list: list)
        XCTAssertTrue(first.nest(under: parent))
        XCTAssertTrue(second.nest(under: parent))

        XCTAssertTrue(second.moveAmongSiblings(before: first, topLevel: [parent]))
        XCTAssertEqual(parent.orderedSubtasks.map(\.title), ["Chargers", "Sunscreen"])
    }

    func testCompletingParentCompletesChildren() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        XCTAssertTrue(child.nest(under: parent))

        parent.setCompleted(true)

        XCTAssertTrue(parent.isCompleted)
        XCTAssertTrue(child.isCompleted)
        XCTAssertNotNil(child.completedAt)
    }

    func testUncompletingParentUncompletesChildren() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        XCTAssertTrue(child.nest(under: parent))
        parent.setCompleted(true)

        parent.setCompleted(false)

        XCTAssertFalse(parent.isCompleted)
        XCTAssertFalse(child.isCompleted)
        XCTAssertNil(child.completedAt)
    }

    func testUncompletingChildUncompletesParent() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let first = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        let second = TestFixtures.makeReminder(title: "Chargers", list: list)
        XCTAssertTrue(first.nest(under: parent))
        XCTAssertTrue(second.nest(under: parent))
        parent.setCompleted(true)

        first.setCompleted(false)

        XCTAssertFalse(parent.isCompleted)
        XCTAssertFalse(first.isCompleted)
        XCTAssertTrue(second.isCompleted)
    }

    func testCompletingChildAloneDoesNotCompleteParent() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        XCTAssertTrue(child.nest(under: parent))

        child.setCompleted(true)

        XCTAssertTrue(child.isCompleted)
        XCTAssertFalse(parent.isCompleted)
    }

    func testDropOntoParentNests() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list, subtaskSortOrder: 0)
        let other = TestFixtures.makeReminder(title: "Sunscreen", list: list, subtaskSortOrder: 1)
        let visible = [parent, other]

        let action = ReminderDropResolver.action(
            dragging: other,
            droppingOn: parent,
            zone: .onto,
            visible: visible
        )

        XCTAssertTrue(other.apply(action!, topLevel: visible))
        XCTAssertEqual(other.parent?.id, parent.id)
    }

    func testDropBeforeTopLevelRowReorders() {
        let first = TestFixtures.makeReminder(title: "A", list: list, subtaskSortOrder: 0)
        let second = TestFixtures.makeReminder(title: "B", list: list, subtaskSortOrder: 1)
        let visible = [first, second]

        let action = ReminderDropResolver.action(
            dragging: second,
            droppingOn: first,
            zone: .before,
            visible: visible
        )

        XCTAssertTrue(second.apply(action!, topLevel: visible))
        XCTAssertNil(second.parent)
        XCTAssertEqual(second.subtaskSortOrder, 0)
        XCTAssertEqual(first.subtaskSortOrder, 1)
    }

    func testDropBeforeTopLevelRowOutdentsSubtask() {
        let first = TestFixtures.makeReminder(title: "A", list: list, subtaskSortOrder: 0)
        let parent = TestFixtures.makeReminder(title: "B", list: list, subtaskSortOrder: 1)
        let child = TestFixtures.makeReminder(title: "Child", list: list, subtaskSortOrder: 2)
        XCTAssertTrue(child.nest(under: parent))
        let visible = [first, parent, child]

        let action = ReminderDropResolver.action(
            dragging: child,
            droppingOn: first,
            zone: .before,
            visible: visible
        )

        XCTAssertTrue(child.apply(action!, topLevel: visible))
        XCTAssertNil(child.parent)
        XCTAssertEqual(child.subtaskSortOrder, 0)
    }

    func testDroppingParentWithChildrenOntoAnotherReordersUnit() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list, subtaskSortOrder: 0)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list, subtaskSortOrder: 1)
        let other = TestFixtures.makeReminder(title: "Call", list: list, subtaskSortOrder: 2)
        XCTAssertTrue(child.nest(under: parent))
        let visible = [parent, child, other]

        let action = ReminderDropResolver.action(
            dragging: parent,
            droppingOn: other,
            zone: .onto,
            visible: visible
        )

        XCTAssertTrue(parent.apply(action!, topLevel: visible))
        XCTAssertNil(parent.parent)
        XCTAssertEqual(child.parent?.id, parent.id)
        XCTAssertEqual(other.subtaskSortOrder, 0)
        XCTAssertEqual(parent.subtaskSortOrder, 1)
    }

    func testDropOnOwnChildIsIgnored() {
        let parent = TestFixtures.makeReminder(title: "Pack", list: list)
        let child = TestFixtures.makeReminder(title: "Sunscreen", list: list)
        XCTAssertTrue(child.nest(under: parent))

        let action = ReminderDropResolver.action(
            dragging: parent,
            droppingOn: child,
            zone: .onto,
            visible: [parent, child]
        )
        XCTAssertNil(action)
    }

    func testDropZoneSplitsBeforeOntoAfter() {
        XCTAssertEqual(ReminderDropResolver.zone(y: 5, height: 50), .before)
        XCTAssertEqual(ReminderDropResolver.zone(y: 25, height: 50), .onto)
        XCTAssertEqual(ReminderDropResolver.zone(y: 45, height: 50), .after)
    }

    func testBackfillAssignsStableTopLevelOrder() {
        let first = TestFixtures.makeReminder(
            title: "First",
            list: list,
            createdAt: Date(timeIntervalSince1970: 1)
        )
        let second = TestFixtures.makeReminder(
            title: "Second",
            list: list,
            createdAt: Date(timeIntervalSince1970: 2)
        )

        Reminder.backfillTopLevelSortOrder(from: [second, first])
        XCTAssertEqual(first.subtaskSortOrder, 0)
        XCTAssertEqual(second.subtaskSortOrder, 1)
    }
}
