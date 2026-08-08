import SwiftUI
import SwiftData
import BetterRemindersCore

struct ReminderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ReminderList.sortOrder) private var allLists: [ReminderList]
    @Bindable var reminder: Reminder
    @State private var showingDeleteConfirm = false
    @State private var hasDueDate: Bool

    private let priorityOptions: [(value: Int, label: String)] = [
        (0, "None"),
        (1, "Low"),
        (2, "Medium"),
        (3, "High"),
    ]

    init(reminder: Reminder) {
        self.reminder = reminder
        _hasDueDate = State(initialValue: reminder.dueDate != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $reminder.title, axis: .vertical)
                        .lineLimit(2...4)
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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            ForEach(priorityOptions, id: \.value) { option in
                                let isSelected = reminder.priority == option.value
                                let color = Reminder.color(forPriority: option.value)
                                Button {
                                    reminder.priority = option.value
                                } label: {
                                    Text(option.label)
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            isSelected ? color.opacity(0.2) : Color.secondary.opacity(0.08),
                                            in: Capsule()
                                        )
                                        .foregroundStyle(isSelected ? color : .secondary)
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(isSelected ? color : .clear, lineWidth: 1.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    Picker("List", selection: Binding(
                        get: { reminder.list?.id ?? allLists.first?.id ?? UUID() },
                        set: { newID in
                            let sourceList = reminder.list
                            if let newList = allLists.first(where: { $0.id == newID }),
                               sourceList?.id != newList.id {
                                ReminderList.recordMoveCorrection(
                                    from: sourceList,
                                    to: newList,
                                    reminderTitle: reminder.title
                                )
                                reminder.list = newList
                                reminder.needsManualSort = false
                            }
                        }
                    )) {
                        ForEach(allLists) { list in
                            Label {
                                Text(list.name)
                            } icon: {
                                Image(systemName: list.icon)
                                    .foregroundStyle(Color(hex: list.colorHex))
                            }
                            .tag(list.id)
                        }
                    }
                }

                if let audioPath = reminder.audioFilePath, !audioPath.isEmpty {
                    Section("Original Recording") {
                        AudioPlaybackView(audioPath: audioPath)
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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        Task { await NotificationSchedulingService.schedule(for: reminder) }
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Delete this reminder?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Task { await NotificationSchedulingService.cancel(for: reminder.id) }
                    modelContext.delete(reminder)
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    let list = ReminderList(name: "Groceries", icon: "cart.fill", colorHex: "34C759", sortOrder: 0)
    let reminder = Reminder(title: "Buy eggs", rawTranscript: "Remind me to buy eggs", list: list)
    ReminderDetailView(reminder: reminder)
        .modelContainer(for: [Reminder.self, ReminderList.self], inMemory: true)
}
