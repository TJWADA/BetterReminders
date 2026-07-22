import SwiftUI
import SwiftData

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var list: ReminderList
    @State private var showingAddReminder = false
    @State private var newTitle = ""

    private var sortedReminders: [Reminder] {
        list.reminders.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    var body: some View {
        List {
            if sortedReminders.isEmpty {
                ContentUnavailableView(
                    "No Reminders",
                    systemImage: "checkmark.circle",
                    description: Text("Record a voice memo to add reminders to this list.")
                )
            } else {
                ForEach(sortedReminders) { reminder in
                    NavigationLink {
                        ReminderDetailView(reminder: reminder)
                    } label: {
                        ReminderRowView(reminder: reminder)
                    }
                }
                .onDelete(perform: deleteReminders)
            }
        }
        .navigationTitle(list.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddReminder = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Add Reminder", isPresented: $showingAddReminder) {
            TextField("Title", text: $newTitle)
            Button("Cancel", role: .cancel) { newTitle = "" }
            Button("Add") { addReminder() }
        }
    }

    private func addReminder() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let reminder = Reminder(title: title, list: list)
        modelContext.insert(reminder)
        try? modelContext.save()
        newTitle = ""
    }

    private func deleteReminders(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedReminders[index])
        }
        try? modelContext.save()
    }
}

struct ReminderRowView: View {
    @Bindable var reminder: Reminder

    var body: some View {
        HStack(spacing: 12) {
            Button {
                reminder.isCompleted.toggle()
                HapticHelper.selection()
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
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let list = ReminderList(name: "Groceries", icon: "cart.fill", colorHex: "34C759", sortOrder: 0)
    NavigationStack {
        ListDetailView(list: list)
    }
    .modelContainer(for: [Reminder.self, ReminderList.self], inMemory: true)
}
