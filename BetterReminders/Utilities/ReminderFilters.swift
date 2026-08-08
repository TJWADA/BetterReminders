import Foundation

enum ReminderSortMode: String, CaseIterable, Identifiable {
    case dueDate
    case createdNewest
    case createdOldest
    case priority
    case title

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dueDate: return "Due Date"
        case .createdNewest: return "Newest First"
        case .createdOldest: return "Oldest First"
        case .priority: return "Priority"
        case .title: return "Title"
        }
    }
}

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
    static let completionGracePeriod: TimeInterval = 3
    static let recentlyCompletedDays = 7

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

    /// Incomplete reminders, plus completed ones still inside the grace buffer.
    static func visibleInList(
        _ reminders: [Reminder],
        now: Date = Date(),
        gracePeriod: TimeInterval = completionGracePeriod
    ) -> [Reminder] {
        reminders.filter { reminder in
            if !reminder.isCompleted { return true }
            guard let completedAt = reminder.completedAt else { return false }
            return now.timeIntervalSince(completedAt) < gracePeriod
        }
    }

    static func recentlyCompleted(
        _ reminders: [Reminder],
        now: Date = Date(),
        withinDays: Int = recentlyCompletedDays
    ) -> [Reminder] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -withinDays, to: now) ?? now
        return reminders
            .filter { reminder in
                guard reminder.isCompleted, let completedAt = reminder.completedAt else { return false }
                return completedAt >= cutoff
            }
            .sorted { lhs, rhs in
                (lhs.completedAt ?? .distantPast) > (rhs.completedAt ?? .distantPast)
            }
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

    static func sortForListView(_ reminders: [Reminder]) -> [Reminder] {
        reminders.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?):
                return l < r
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            case (nil, nil):
                return lhs.createdAt > rhs.createdAt
            }
        }
    }

    static func sort(_ reminders: [Reminder], by mode: ReminderSortMode) -> [Reminder] {
        switch mode {
        case .dueDate:
            return sortByDueDate(reminders)
        case .createdNewest:
            return reminders.sorted { $0.createdAt > $1.createdAt }
        case .createdOldest:
            return reminders.sorted { $0.createdAt < $1.createdAt }
        case .priority:
            return reminders.sorted { lhs, rhs in
                if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
                return lhs.createdAt > rhs.createdAt
            }
        case .title:
            return reminders.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }
    }

    static func isOverdue(_ reminder: Reminder, now: Date = Date()) -> Bool {
        guard let dueDate = reminder.dueDate, !reminder.isCompleted else { return false }
        return dueDate < now
    }

    static func isDueToday(_ reminder: Reminder, now: Date = Date()) -> Bool {
        guard let dueDate = reminder.dueDate, !reminder.isCompleted else { return false }
        return Calendar.current.isDate(dueDate, inSameDayAs: now) && dueDate >= now
    }

    static func isUpcoming(_ reminder: Reminder, now: Date = Date(), withinDays: Int = 7) -> Bool {
        guard let dueDate = reminder.dueDate, !reminder.isCompleted else { return false }
        guard !Calendar.current.isDate(dueDate, inSameDayAs: now) else { return false }
        guard dueDate > now else { return false }
        let end = Calendar.current.date(byAdding: .day, value: withinDays, to: Calendar.current.startOfDay(for: now)) ?? now
        return dueDate < end
    }
}
