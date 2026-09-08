import SwiftUI
import SwiftData
import BetterRemindersCore

struct ReminderRowView: View {
    @Bindable var reminder: Reminder
    var indentLevel: Int = 0
    var onCompletionChanged: (() -> Void)? = nil
    var onBecameVisible: (() -> Void)? = nil

    var body: some View {
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

                if let dueDate = reminder.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(ReminderFilters.isOverdue(reminder) ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .padding(.leading, CGFloat(indentLevel) * 28)
        .onAppear {
            onBecameVisible?()
        }
    }
}
