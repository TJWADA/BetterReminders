import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reminder.createdAt, order: .reverse) private var allReminders: [Reminder]
    @State private var settings = AppSettings.shared
    @State private var searchText = ""
    @State private var priorityFilter: PriorityFilter = .all

    private var filteredReminders: [Reminder] {
        ReminderFilters.apply(
            to: allReminders,
            searchText: searchText,
            hideCompleted: settings.hideCompleted,
            priorityFilter: priorityFilter
        )
    }

    private var overdue: [Reminder] {
        ReminderFilters.sortByDueDate(filteredReminders.filter { ReminderFilters.isOverdue($0) })
    }

    private var today: [Reminder] {
        ReminderFilters.sortByDueDate(filteredReminders.filter { ReminderFilters.isDueToday($0) })
    }

    private var upcoming: [Reminder] {
        ReminderFilters.sortByDueDate(filteredReminders.filter { ReminderFilters.isUpcoming($0) })
    }

    private var noDate: [Reminder] {
        filteredReminders
            .filter { $0.dueDate == nil && !$0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredReminders.isEmpty && searchText.isEmpty && !hasAnyReminders {
                    ContentUnavailableView(
                        "No Reminders Yet",
                        systemImage: "calendar",
                        description: Text("Record a voice memo to add reminders, or create one from a list.")
                    )
                } else if overdue.isEmpty && today.isEmpty && upcoming.isEmpty && noDate.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        if !overdue.isEmpty {
                            Section("Overdue") {
                                ForEach(overdue) { reminder in
                                    reminderRow(reminder)
                                }
                            }
                        }
                        if !today.isEmpty {
                            Section("Today") {
                                ForEach(today) { reminder in
                                    reminderRow(reminder)
                                }
                            }
                        }
                        if !upcoming.isEmpty {
                            Section("Upcoming") {
                                ForEach(upcoming) { reminder in
                                    reminderRow(reminder)
                                }
                            }
                        }
                        if !noDate.isEmpty && searchText.isEmpty {
                            Section("No Due Date") {
                                ForEach(noDate) { reminder in
                                    reminderRow(reminder)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Today")
            .searchable(text: $searchText, prompt: "Search reminders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle("Hide Completed", isOn: $settings.hideCompleted)
                        Picker("Priority", selection: $priorityFilter) {
                            ForEach(PriorityFilter.allCases) { filter in
                                Text(filter.label).tag(filter)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    private var hasAnyReminders: Bool {
        !allReminders.isEmpty
    }

    @ViewBuilder
    private func reminderRow(_ reminder: Reminder) -> some View {
        NavigationLink {
            ReminderDetailView(reminder: reminder)
        } label: {
            HStack(spacing: 12) {
                ReminderRowView(reminder: reminder)
                Spacer(minLength: 0)
                if let list = reminder.list {
                    Text(list.name)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: list.colorHex).opacity(0.15), in: Capsule())
                        .foregroundStyle(Color(hex: list.colorHex))
                }
            }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Reminder.self, ReminderList.self], inMemory: true)
}
