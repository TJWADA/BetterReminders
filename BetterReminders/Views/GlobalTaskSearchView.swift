import SwiftUI
import SwiftData
import BetterRemindersCore

struct GlobalTaskSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Reminder.createdAt, order: .reverse) private var allReminders: [Reminder]
    @State private var searchText = ""
    @State private var sortMode: ReminderSortMode = .dueDate
    @State private var priorityFilter: PriorityFilter = .all
    @State private var editingReminder: Reminder?
    @FocusState private var searchFocused: Bool
    @State private var seenPlacementIDs: Set<UUID> = []

    private var activeReminders: [Reminder] {
        ReminderFilters.sort(
            ReminderFilters.apply(
                to: allReminders,
                searchText: searchText,
                hideCompleted: true,
                priorityFilter: priorityFilter
            ),
            by: sortMode
        )
    }

    private var recentlyCompletedReminders: [Reminder] {
        let completed = ReminderFilters.recentlyCompleted(allReminders)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return completed }
        return completed.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.rawTranscript.localizedCaseInsensitiveContains(query)
                || ($0.list?.name.localizedCaseInsensitiveContains(query) ?? false)
        }
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
        .sheet(item: $editingReminder) { reminder in
            ReminderDetailView(reminder: reminder)
        }
        .onAppear {
            searchFocused = true
        }
        .onDisappear {
            searchFocused = false
            searchText = ""
            confirmSeenPlacements()
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
        if activeReminders.isEmpty && recentlyCompletedReminders.isEmpty {
            ContentUnavailableView.search(text: searchText)
                .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(activeReminders) { reminder in
                    Button {
                        editingReminder = reminder
                    } label: {
                        GlobalSearchReminderRow(
                            reminder: reminder,
                            onBecameVisible: { markPlacementVisible(reminder) }
                        )
                    }
                    .buttonStyle(.plain)
                }

                if !recentlyCompletedReminders.isEmpty {
                    DisclosureGroup("Recently Completed") {
                        ForEach(recentlyCompletedReminders) { reminder in
                            Button {
                                editingReminder = reminder
                            } label: {
                                GlobalSearchReminderRow(
                                    reminder: reminder,
                                    onBecameVisible: { markPlacementVisible(reminder) }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private func markPlacementVisible(_ reminder: Reminder) {
        if reminder.needsManualSort {
            seenPlacementIDs.insert(reminder.id)
        }
    }

    private func confirmSeenPlacements() {
        PlacementReview.confirmVisiblePlacements(ids: seenPlacementIDs, in: allReminders)
        try? modelContext.save()
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
    var onBecameVisible: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(reminder.isCompleted ? .green : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if reminder.needsManualSort {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 7, height: 7)
                    }
                    Text(reminder.title)
                        .strikethrough(reminder.isCompleted)
                        .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if reminder.isSubtask, let parentTitle = reminder.parent?.title, !parentTitle.isEmpty {
                        Text("Subtask of \(parentTitle)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
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
        .padding(.leading, reminder.isSubtask ? 28 : 0)
        .onAppear {
            onBecameVisible?()
        }
    }
}
