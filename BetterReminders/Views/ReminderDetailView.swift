import SwiftUI
import SwiftData

struct ReminderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ReminderList.sortOrder) private var allLists: [ReminderList]
    @Bindable var reminder: Reminder
    @State private var showingDeleteConfirm = false

    var body: some View {
        Form {
            Section("Reminder") {
                TextField("Title", text: $reminder.title, axis: .vertical)
                    .lineLimit(2...4)
                Toggle("Completed", isOn: $reminder.isCompleted)
                DatePicker(
                    "Due Date",
                    selection: Binding(
                        get: { reminder.dueDate ?? Date() },
                        set: { reminder.dueDate = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                Picker("Priority", selection: $reminder.priority) {
                    Text("None").tag(0)
                    Text("Low").tag(1)
                    Text("Medium").tag(2)
                    Text("High").tag(3)
                }
            }

            Section("List") {
                Picker("List", selection: Binding(
                    get: { reminder.list?.id ?? allLists.first?.id ?? UUID() },
                    set: { newID in
                        let oldListName = reminder.list?.name ?? "Unknown"
                        if let newList = allLists.first(where: { $0.id == newID }) {
                            reminder.list = newList
                            if oldListName != newList.name {
                                AppSettings.shared.recordCorrection(
                                    from: oldListName,
                                    to: newList.name,
                                    reminderTitle: reminder.title
                                )
                            }
                        }
                    }
                )) {
                    ForEach(allLists) { list in
                        Text(list.name).tag(list.id)
                    }
                }
            }

            if !reminder.rawTranscript.isEmpty {
                Section("Original Transcript") {
                    Text(reminder.rawTranscript)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Delete Reminder", role: .destructive) {
                    showingDeleteConfirm = true
                }
            }
        }
        .navigationTitle("Edit Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            try? modelContext.save()
        }
        .confirmationDialog("Delete this reminder?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(reminder)
                try? modelContext.save()
                dismiss()
            }
        }
    }
}

#Preview {
    let list = ReminderList(name: "Groceries", icon: "cart.fill", colorHex: "34C759", sortOrder: 0)
    let reminder = Reminder(title: "Buy eggs", rawTranscript: "Remind me to buy eggs", list: list)
    NavigationStack {
        ReminderDetailView(reminder: reminder)
    }
    .modelContainer(for: [Reminder.self, ReminderList.self], inMemory: true)
}
