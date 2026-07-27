import Foundation

enum PriorityFilter: Int, CaseIterable, Identifiable {
    case all = 0
    case lowOrHigher = 1
    case mediumOrHigher = 2
    case highOnly = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .all: return "All Priorities"
        case .lowOrHigher: return "Low+"
        case .mediumOrHigher: return "Medium+"
        case .highOnly: return "High Only"
        }
    }

    func matches(priority: Int) -> Bool {
        priority >= rawValue
    }
}

enum ReminderFilters {
    static func apply(
        to reminders: [Reminder],
        searchText: String,
        hideCompleted: Bool,
        priorityFilter: PriorityFilter
    ) -> [Reminder] {
        var result = reminders

        if hideCompleted {
            result = result.filter { !$0.isCompleted }
        }

        if priorityFilter != .all {
            result = result.filter { priorityFilter.matches(priority: $0.priority) }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(query)
                    || $0.rawTranscript.localizedCaseInsensitiveContains(query)
                    || ($0.list?.name.localizedCaseInsensitiveContains(query) ?? false)
            }
        }

        return result
    }

    static func sortByDueDate(_ reminders: [Reminder]) -> [Reminder] {
        reminders.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?):
                if l != r { return l < r }
                return lhs.createdAt > rhs.createdAt
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            case (nil, nil):
                return lhs.createdAt > rhs.createdAt
            }
        }
    }

    static func isOverdue(_ reminder: Reminder, now: Date = Date()) -> Bool {
        guard let dueDate = reminder.dueDate, !reminder.isCompleted else { return false }
        return dueDate < now
    }

    static func isDueToday(_ reminder: Reminder, now: Date = Date()) -> Bool {
        guard let dueDate = reminder.dueDate, !reminder.isCompleted else { return false }
        return Calendar.current.isDateInToday(dueDate) && dueDate >= now
    }

    static func isUpcoming(_ reminder: Reminder, now: Date = Date(), withinDays: Int = 7) -> Bool {
        guard let dueDate = reminder.dueDate, !reminder.isCompleted else { return false }
        guard !Calendar.current.isDateInToday(dueDate) else { return false }
        guard dueDate > now else { return false }
        let end = Calendar.current.date(byAdding: .day, value: withinDays, to: Calendar.current.startOfDay(for: now)) ?? now
        return dueDate < end
    }
}
