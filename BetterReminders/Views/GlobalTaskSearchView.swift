import SwiftUI
import SwiftData
import BetterRemindersCore

struct GlobalTaskSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Reminder.createdAt, order: .reverse) private var allReminders: [Reminder]
    @State private var settings = AppSettings.shared
    @State private var searchText = ""
    @State private var sortMode: ReminderSortMode = .dueDate
    @State private var priorityFilter: PriorityFilter = .all
    @FocusState private var searchFocused: Bool

    private var filteredReminders: [Reminder] {
        ReminderFilters.sort(
            ReminderFilters.apply(
                to: allReminders,
                searchText: searchText,
                hideCompleted: settings.hideCompleted,
                priorityFilter: priorityFilter
            ),
            by: sortMode
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchHeader
                sortBar
                resultsList
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            searchFocused = true
        }
        .onDisappear {
            searchFocused = false
            searchText = ""
        }
    }

    private var searchHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search tasks", text: $searchText)
                .autocorrectionDisabled()
                .focused($searchFocused)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var sortBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReminderSortMode.allCases) { mode in
                    SortChip(
                        label: mode.label,
                        isSelected: sortMode == mode
                    ) {
                        sortMode = mode
                    }
                }

                Menu {
                    Picker("Priority", selection: $priorityFilter) {
                        ForEach(PriorityFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                    Toggle("Hide Completed", isOn: $settings.hideCompleted)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Filter")
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1), in: Capsule())
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var resultsList: some View {
        if filteredReminders.isEmpty {
            ContentUnavailableView.search(text: searchText)
                .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(filteredReminders) { reminder in
                    NavigationLink {
                        ReminderDetailView(reminder: reminder)
                    } label: {
                        GlobalSearchReminderRow(reminder: reminder)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

struct SortChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.1),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .secondary)
        }
    }
}

struct GlobalSearchReminderRow: View {
    @Bindable var reminder: Reminder

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(reminder.isCompleted ? .green : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .strikethrough(reminder.isCompleted)
                    .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let list = reminder.list {
                        ListNameBadge(name: list.name, colorHex: list.colorHex)
                    }
                    if reminder.priority > 0 {
                        Text(reminder.priorityLabel)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(reminder.priorityColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(reminder.priorityColor)
                    }
                    if let dueDate = reminder.dueDate {
                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(ReminderFilters.isOverdue(reminder) ? .red : .secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}
