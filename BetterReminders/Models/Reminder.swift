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
    var createdAt: Date
    var audioFilePath: String?
    var list: ReminderList?

    init(
        id: UUID = UUID(),
        title: String,
        rawTranscript: String = "",
        dueDate: Date? = nil,
        priority: Int = 0,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        audioFilePath: String? = nil,
        list: ReminderList? = nil
    ) {
        self.id = id
        self.title = title
        self.rawTranscript = rawTranscript
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.audioFilePath = audioFilePath
        self.list = list
    }

    var priorityLabel: String {
        switch priority {
        case 3: return "High"
        case 2: return "Medium"
        case 1: return "Low"
        default: return "None"
        }
    }
}
