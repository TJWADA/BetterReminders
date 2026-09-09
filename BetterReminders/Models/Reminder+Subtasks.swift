import Foundation

extension Reminder {
    var isSubtask: Bool { parent != nil }

    var orderedSubtasks: [Reminder] {
        subtasks.sorted(by: Self.siblingSort)
    }

    static func siblingSort(_ lhs: Reminder, _ rhs: Reminder) -> Bool {
        if lhs.subtaskSortOrder != rhs.subtaskSortOrder {
            return lhs.subtaskSortOrder < rhs.subtaskSortOrder
        }
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    static func orderedTopLevel(from reminders: [Reminder]) -> [Reminder] {
        reminders.filter { $0.parent == nil }.sorted(by: siblingSort)
    }

    static func backfillTopLevelSortOrder(from reminders: [Reminder]) {
        let topLevel = orderedTopLevel(from: reminders)
        guard topLevel.count > 1, topLevel.allSatisfy({ $0.subtaskSortOrder == 0 }) else { return }
        for (index, reminder) in topLevel.enumerated() {
            reminder.subtaskSortOrder = index
        }
    }

    static func nextTopLevelSortOrder(from reminders: [Reminder]) -> Int {
        backfillTopLevelSortOrder(from: reminders)
        return (orderedTopLevel(from: reminders).map(\.subtaskSortOrder).max() ?? -1) + 1
    }

    func canNest(under target: Reminder) -> Bool {
        guard target.id != id else { return false }
        guard subtasks.isEmpty else { return false }
        guard target.parent == nil else { return false }
        return true
    }

    @discardableResult
    func nest(under parent: Reminder) -> Bool {
        move(under: parent, before: nil, topLevel: [])
    }

    @discardableResult
    func outdent(before neighbor: Reminder? = nil, topLevel: [Reminder] = []) -> Bool {
        let siblings = topLevel.isEmpty ? fallbackTopLevelSiblings(adding: neighbor) : topLevel
        return move(under: nil, before: neighbor, topLevel: siblings)
    }

    @discardableResult
    func moveAmongSiblings(before neighbor: Reminder?, topLevel: [Reminder] = []) -> Bool {
        move(under: parent, before: neighbor, topLevel: topLevel)
    }

    @discardableResult
    func apply(_ action: ReminderDropAction, topLevel: [Reminder]) -> Bool {
        switch action {
        case .nest(let parent):
            return move(under: parent, before: nil, topLevel: topLevel)
        case .move(let newParent, let neighbor):
            return move(under: newParent, before: neighbor, topLevel: topLevel)
        }
    }

    func syncSubtasksList() {
        let destination = list
        for child in subtasks {
            child.list = destination
        }
    }

    @discardableResult
    func move(under newParent: Reminder?, before neighbor: Reminder?, topLevel: [Reminder]) -> Bool {
        if let newParent {
            guard canNest(under: newParent) || (parent?.id == newParent.id && subtasks.isEmpty) else {
                return false
            }
        }
        if newParent?.id == id { return false }
        if let neighbor, neighbor.id == id { return false }

        let destinationList = newParent?.list ?? neighbor?.list ?? list
        detachFromHierarchy(topLevel: topLevel)

        if let newParent {
            parent = newParent
            if !newParent.subtasks.contains(where: { $0.id == id }) {
                newParent.subtasks.append(self)
            }
            list = newParent.list
            reindex(newParent.orderedSubtasks, inserting: self, before: neighbor)
            newParent.areSubtasksCollapsed = false
        } else {
            parent = nil
            if let destinationList {
                list = destinationList
            }
            var siblings = orderedTopLevel(from: topLevel)
            if !siblings.contains(where: { $0.id == id }) {
                siblings.append(self)
            }
            reindex(siblings, inserting: self, before: neighbor)
        }
        return true
    }

    private func orderedTopLevel(from topLevel: [Reminder]) -> [Reminder] {
        let reminders = topLevel.isEmpty ? fallbackTopLevelSiblings(adding: nil) : topLevel
        return Self.orderedTopLevel(from: reminders)
    }

    private func fallbackTopLevelSiblings(adding extra: Reminder?) -> [Reminder] {
        var reminders = list?.reminders ?? []
        if let extra, !reminders.contains(where: { $0.id == extra.id }) {
            reminders.append(extra)
        }
        if !reminders.contains(where: { $0.id == id }) {
            reminders.append(self)
        }
        return reminders
    }

    private func detachFromHierarchy(topLevel: [Reminder]) {
        if let currentParent = parent {
            let remaining = currentParent.orderedSubtasks.filter { $0.id != id }
            currentParent.subtasks.removeAll { $0.id == id }
            parent = nil
            for (index, sibling) in remaining.enumerated() {
                sibling.subtaskSortOrder = index
            }
            if remaining.isEmpty {
                currentParent.areSubtasksCollapsed = false
            }
        } else {
            let remaining = orderedTopLevel(from: topLevel).filter { $0.id != id }
            for (index, sibling) in remaining.enumerated() {
                sibling.subtaskSortOrder = index
            }
        }
    }

    private func reindex(_ siblings: [Reminder], inserting item: Reminder, before neighbor: Reminder?) {
        var items = siblings.filter { $0.id != item.id }
        if let neighbor, let index = items.firstIndex(where: { $0.id == neighbor.id }) {
            items.insert(item, at: index)
        } else {
            items.append(item)
        }
        for (index, reminder) in items.enumerated() {
            reminder.subtaskSortOrder = index
        }
    }
}

enum ReminderDropZone: Equatable {
    case before
    case onto
    case after
}

enum ReminderDropAction {
    case nest(under: Reminder)
    case move(under: Reminder?, before: Reminder?)
}

enum ReminderDropResolver {
    static func zone(y: CGFloat, height: CGFloat) -> ReminderDropZone {
        guard height > 1 else { return .onto }
        let ratio = y / height
        if ratio < 0.28 { return .before }
        if ratio > 0.72 { return .after }
        return .onto
    }

    static func action(
        dragging: Reminder,
        droppingOn target: Reminder,
        zone: ReminderDropZone,
        visible: [Reminder]
    ) -> ReminderDropAction? {
        guard dragging.id != target.id else { return nil }
        if target.parent?.id == dragging.id { return nil }

        switch zone {
        case .onto:
            if dragging.canNest(under: target) {
                return .nest(under: target)
            }
            if target.isSubtask, dragging.subtasks.isEmpty {
                return insert(dragging, before: nextSibling(after: target, under: target.parent), under: target.parent)
            }
            let unit = target.parent ?? target
            return insert(dragging, before: nextTopLevel(after: unit, in: visible), under: nil)

        case .before:
            return insertBeforeRow(target, dragging: dragging)

        case .after:
            if let next = nextVisible(after: target, in: visible) {
                return insertBeforeRow(next, dragging: dragging)
            }
            return insert(dragging, before: nil, under: nil)
        }
    }

    private static func insertBeforeRow(_ target: Reminder, dragging: Reminder) -> ReminderDropAction {
        if target.isSubtask {
            if dragging.subtasks.isEmpty {
                return insert(dragging, before: target, under: target.parent)
            }
            if let parent = target.parent {
                return insert(dragging, before: parent, under: nil)
            }
        }
        return insert(dragging, before: target, under: nil)
    }

    private static func insert(
        _ dragging: Reminder,
        before neighbor: Reminder?,
        under parent: Reminder?
    ) -> ReminderDropAction {
        if neighbor?.id == dragging.id {
            return .move(under: parent, before: nextSibling(after: dragging, under: parent))
        }
        return .move(under: parent, before: neighbor)
    }

    private static func nextVisible(after target: Reminder, in visible: [Reminder]) -> Reminder? {
        guard let index = visible.firstIndex(where: { $0.id == target.id }) else { return nil }
        let nextIndex = visible.index(after: index)
        guard nextIndex < visible.endIndex else { return nil }
        return visible[nextIndex]
    }

    private static func nextTopLevel(after target: Reminder, in visible: [Reminder]) -> Reminder? {
        guard let index = visible.firstIndex(where: { $0.id == target.id }) else { return nil }
        return visible.dropFirst(index + 1).first { $0.parent == nil }
    }

    private static func nextSibling(after target: Reminder, under parent: Reminder? = nil) -> Reminder? {
        let siblings = parent?.orderedSubtasks ?? []
        guard let index = siblings.firstIndex(where: { $0.id == target.id }) else { return nil }
        let nextIndex = siblings.index(after: index)
        guard nextIndex < siblings.endIndex else { return nil }
        return siblings[nextIndex]
    }
}
