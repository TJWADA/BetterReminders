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
    var areSubtasksCollapsed: Bool = false
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
        subtaskSortOrder: Int = 0,
        areSubtasksCollapsed: Bool = false
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
        self.areSubtasksCollapsed = areSubtasksCollapsed
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
        applyCompletionState(completed, at: date)
        if parent == nil {
            for child in subtasks {
                child.applyCompletionState(completed, at: date)
            }
        } else if !completed, let parent, parent.isCompleted {
            parent.applyCompletionState(false, at: date)
        }
    }

    private func applyCompletionState(_ completed: Bool, at date: Date) {
        isCompleted = completed
        completedAt = completed ? date : nil
    }
}
