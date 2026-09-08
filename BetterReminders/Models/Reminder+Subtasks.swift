import Foundation

extension Reminder {
    var isSubtask: Bool { parent != nil }

    var orderedSubtasks: [Reminder] {
        subtasks.sorted { lhs, rhs in
            if lhs.subtaskSortOrder != rhs.subtaskSortOrder {
                return lhs.subtaskSortOrder < rhs.subtaskSortOrder
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    func canIndent(preceding: Reminder?) -> Bool {
        guard parent == nil else { return false }
        guard subtasks.isEmpty else { return false }
        guard let preceding, preceding.id != id else { return false }
        return true
    }

    @discardableResult
    func indent(preceding: Reminder?) -> Bool {
        guard canIndent(preceding: preceding), let preceding else { return false }

        let targetParent = preceding.parent ?? preceding
        attach(to: targetParent, after: preceding.parent == nil ? nil : preceding)
        list = targetParent.list
        return true
    }

    func outdent() {
        guard let currentParent = parent else { return }
        currentParent.subtasks.removeAll { $0.id == id }
        parent = nil
        subtaskSortOrder = 0
    }

    func syncSubtasksList() {
        let destination = list
        for child in subtasks {
            child.list = destination
        }
    }

    private func attach(to targetParent: Reminder, after precedingSibling: Reminder?) {
        if let precedingSibling {
            let insertOrder = precedingSibling.subtaskSortOrder + 1
            for sibling in targetParent.subtasks where sibling.subtaskSortOrder >= insertOrder && sibling.id != id {
                sibling.subtaskSortOrder += 1
            }
            subtaskSortOrder = insertOrder
        } else {
            let nextOrder = (targetParent.subtasks.filter { $0.id != id }.map(\.subtaskSortOrder).max() ?? -1) + 1
            subtaskSortOrder = nextOrder
        }

        parent = targetParent
        if !targetParent.subtasks.contains(where: { $0.id == id }) {
            targetParent.subtasks.append(self)
        }
    }
}
