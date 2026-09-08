import Foundation
import SwiftData

@Model
final class Reminder {
    var id: UUID
    var title: String
    var rawTranscript: String
    var dueDate: Date?
    var priority: Int
    var isCompleted: Bool
    var completedAt: Date?
    var needsManualSort: Bool = false
    var createdAt: Date
    var audioFilePath: String?
    var list: ReminderList?
    var parent: Reminder?
    var subtaskSortOrder: Int = 0
    @Relationship(deleteRule: .cascade, inverse: \Reminder.parent)
    var subtasks: [Reminder] = []

    init(
        id: UUID = UUID(),
        title: String,
        rawTranscript: String = "",
        dueDate: Date? = nil,
        priority: Int = 0,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        needsManualSort: Bool = false,
        createdAt: Date = Date(),
        audioFilePath: String? = nil,
        list: ReminderList? = nil,
        parent: Reminder? = nil,
        subtaskSortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.rawTranscript = rawTranscript
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.completedAt = completedAt ?? (isCompleted ? createdAt : nil)
        self.needsManualSort = needsManualSort
        self.createdAt = createdAt
        self.audioFilePath = audioFilePath
        self.list = list
        self.parent = parent
        self.subtaskSortOrder = subtaskSortOrder
        self.subtasks = []
    }

    var priorityLabel: String {
        switch priority {
        case 3: return "High"
        case 2: return "Medium"
        case 1: return "Low"
        default: return "None"
        }
    }

    func setCompleted(_ completed: Bool, at date: Date = Date()) {
        isCompleted = completed
        completedAt = completed ? date : nil
    }
}
