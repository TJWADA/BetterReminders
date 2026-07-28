import Foundation

struct ParsedReminder: Codable {
    let title: String
    let list: String
    let dueDate: String?
    let priority: String?

    init(title: String, list: String, dueDate: String? = nil, priority: String? = nil) {
        self.title = title
        self.list = list
        self.dueDate = dueDate
        self.priority = priority
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        list = try container.decode(String.self, forKey: .list)
        dueDate = try container.decodeIfPresent(String.self, forKey: .dueDate)
        if let priorityString = try? container.decode(String.self, forKey: .priority) {
            priority = priorityString
        } else if let priorityInt = try? container.decode(Int.self, forKey: .priority) {
            priority = String(priorityInt)
        } else {
            priority = nil
        }
    }
}

struct ParsedReminderResponse: Codable {
    let reminders: [ParsedReminder]
    let confidence: Double?
}
