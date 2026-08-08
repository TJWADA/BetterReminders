import SwiftUI
import SwiftData
import BetterRemindersCore

struct ReminderRowView: View {
    @Bindable var reminder: Reminder
    var isExpanded: Bool = false
    var onToggleExpand: (() -> Void)? = nil
    var onCompletionChanged: (() -> Void)? = nil

    @State private var hasDueDate: Bool

    init(
        reminder: Reminder,
        isExpanded: Bool = false,
        onToggleExpand: (() -> Void)? = nil,
        onCompletionChanged: (() -> Void)? = nil
    ) {
        self.reminder = reminder
        self.isExpanded = isExpanded
        self.onToggleExpand = onToggleExpand
        self.onCompletionChanged = onCompletionChanged
        _hasDueDate = State(initialValue: reminder.dueDate != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    reminder.toggleCompletion()
                    HapticHelper.selection()
                    onCompletionChanged?()
                    Task {
                        await reminder.updateNotificationForCompletion()
                    }
                } label: {
                    Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(reminder.isCompleted ? .green : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if reminder.needsManualSort {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 7, height: 7)
                        }
                        TextField("Reminder", text: $reminder.title, axis: .vertical)
                            .lineLimit(1...3)
                            .strikethrough(reminder.isCompleted)
                            .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                    }

                    if !isExpanded, let dueDate = reminder.dueDate {
                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(ReminderFilters.isOverdue(reminder) ? .red : .secondary)
                    }
                }

                if let onToggleExpand {
                    Button(action: onToggleExpand) {
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .buttonStyle(.plain)
                }
            }

            if isExpanded {
                expandedControls
            }
        }
        .padding(.vertical, 2)
    }

    private var expandedControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Due Date", isOn: $hasDueDate)
                .onChange(of: hasDueDate) { _, enabled in
                    if enabled {
                        if reminder.dueDate == nil {
                            reminder.dueDate = Date()
                        }
                    } else {
                        reminder.dueDate = nil
                        Task { await NotificationSchedulingService.cancel(for: reminder.id) }
                    }
                }

            if hasDueDate {
                DatePicker(
                    "When",
                    selection: Binding(
                        get: { reminder.dueDate ?? Date() },
                        set: { reminder.dueDate = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            Picker("Priority", selection: $reminder.priority) {
                Text("None").tag(0)
                Text("Low").tag(1)
                Text("Medium").tag(2)
                Text("High").tag(3)
            }
        }
        .padding(.leading, 36)
    }
}
