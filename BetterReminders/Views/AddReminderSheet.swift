import SwiftUI
import SwiftData
import BetterRemindersCore

struct AddReminderSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ReminderList.sortOrder) private var allLists: [ReminderList]

    private let preselectedList: ReminderList?
    private let allowListPicker: Bool

    @State private var title = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority = 0
    @State private var selectedListID: UUID?

    init(list: ReminderList? = nil, allowListPicker: Bool = false) {
        self.preselectedList = list
        self.allowListPicker = allowListPicker || list == nil
        _selectedListID = State(initialValue: list?.id)
    }

    private var selectedList: ReminderList? {
        if let selectedListID {
            return allLists.first { $0.id == selectedListID }
        }
        return preselectedList
            ?? ListSeeder.findList(named: AppConfiguration.fallbackListName, in: allLists)
            ?? allLists.first
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedList != nil
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
                    if allowListPicker {
                        Picker("List", selection: Binding(
                            get: { selectedList?.id ?? allLists.first?.id ?? UUID() },
                            set: { selectedListID = $0 }
                        )) {
                            ForEach(allLists) { list in
                                Text(list.name).tag(list.id)
                            }
                        }
                    } else if let selectedList {
                        HStack(spacing: 10) {
                            ListColorBadge(colorHex: selectedList.colorHex, icon: selectedList.icon)
                                .scaleEffect(0.8)
                            Text(selectedList.name)
                        }
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
            .onAppear {
                if selectedListID == nil {
                    selectedListID = selectedList?.id
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let list = selectedList else { return }

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
