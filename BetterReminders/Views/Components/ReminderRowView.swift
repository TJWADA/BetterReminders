import SwiftUI
import SwiftData
import BetterRemindersCore

struct ScrollEdgeFade: View {
    let isTop: Bool

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(.systemBackground), location: 0),
                .init(color: Color(.systemBackground), location: 0.65),
                .init(color: Color(.systemBackground).opacity(0), location: 1),
            ],
            startPoint: isTop ? .top : .bottom,
            endPoint: isTop ? .bottom : .top
        )
        .allowsHitTesting(false)
    }
}

struct ReminderRowView: View {
    @Bindable var reminder: Reminder

    var body: some View {
        HStack(spacing: 12) {
            Button {
                reminder.isCompleted.toggle()
                HapticHelper.selection()
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
                Text(reminder.title)
                    .strikethrough(reminder.isCompleted)
                    .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                if let dueDate = reminder.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(ReminderFilters.isOverdue(reminder) ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
