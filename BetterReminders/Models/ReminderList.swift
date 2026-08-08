import Foundation
import SwiftData

@Model
final class ReminderList {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var sortOrder: Int
    var isDefault: Bool
    var listDescription: String = ""
    var misclassificationLog: [String] = []
    @Relationship(deleteRule: .cascade, inverse: \Reminder.list)
    var reminders: [Reminder]

    static let misclassificationLogLimit = 15

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int,
        isDefault: Bool = false,
        listDescription: String = "",
        misclassificationLog: [String] = [],
        reminders: [Reminder] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.listDescription = listDescription
        self.misclassificationLog = misclassificationLog
        self.reminders = reminders
    }

    var incompleteCount: Int {
        reminders.filter { !$0.isCompleted }.count
    }

    var needsManualSortCount: Int {
        reminders.filter { !$0.isCompleted && $0.needsManualSort }.count
    }

    func appendMisclassificationNote(_ note: String) {
        var log = misclassificationLog
        log.insert(note, at: 0)
        misclassificationLog = Array(log.prefix(Self.misclassificationLogLimit))
    }

    static func recordMoveCorrection(
        from source: ReminderList?,
        to destination: ReminderList,
        reminderTitle: String
    ) {
        let title = reminderTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayTitle = title.isEmpty ? "Untitled" : title
        let sourceName = source?.name ?? "Unknown"

        source?.appendMisclassificationNote(
            "Does not belong here (moved to \(destination.name)): '\(displayTitle)'"
        )
        destination.appendMisclassificationNote(
            "Belongs here (moved from \(sourceName)): '\(displayTitle)'"
        )
    }
}
