import SwiftUI
import SwiftData
import BetterRemindersCore

struct AddReminderSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let list: ReminderList

    @State private var title = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority = 0

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("What do you need to remember?", text: $title, axis: .vertical)
                        .lineLimit(2...4)
                    Toggle("Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker(
                            "When",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                    Picker("Priority", selection: $priority) {
                        Text("None").tag(0)
                        Text("Low").tag(1)
                        Text("Medium").tag(2)
                        Text("High").tag(3)
                    }
                }

                Section("List") {
                    HStack(spacing: 10) {
                        ListColorBadge(colorHex: list.colorHex, icon: list.icon)
                            .scaleEffect(0.8)
                        Text(list.name)
                    }
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let reminder = Reminder(
            title: trimmed,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            list: list
        )
        modelContext.insert(reminder)
        try? modelContext.save()

        Task { await NotificationSchedulingService.schedule(for: reminder) }

        HapticHelper.notification(.success)
        dismiss()
    }
}
