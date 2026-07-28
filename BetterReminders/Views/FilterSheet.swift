import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var settings: AppSettings
    @Binding var groupMode: ReminderGroupMode
    @Binding var sortMode: ReminderSortMode
    @Binding var priorityFilter: PriorityFilter
    @Binding var searchText: String

    var body: some View {
        NavigationStack {
            Form {
                Section("Search") {
                    TextField("Search reminders", text: $searchText)
                        .autocorrectionDisabled()
                }

                Section("Group By") {
                    Picker("Group", selection: $groupMode) {
                        ForEach(ReminderGroupMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Sort") {
                    Picker("Sort", selection: $sortMode) {
                        ForEach(ReminderSortMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                }

                Section("Filter") {
                    Toggle("Hide Completed", isOn: $settings.hideCompleted)
                    Picker("Priority", selection: $priorityFilter) {
                        ForEach(PriorityFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
