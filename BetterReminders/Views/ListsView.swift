import SwiftUI
import SwiftData
import BetterRemindersCore

struct ListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderList.sortOrder) private var lists: [ReminderList]
    @State private var showingNewList = false
    @State private var newListName = ""

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    ContentUnavailableView(
                        "No Lists",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Default lists will appear on first launch.")
                    )
                } else {
                    List(lists) { list in
                        NavigationLink {
                            ListDetailView(list: list)
                        } label: {
                            HStack {
                                ListColorBadge(colorHex: list.colorHex, icon: list.icon)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(list.name)
                                        .font(.headline)
                                    Text("\(list.incompleteCount) open")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Lists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewList = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New List", isPresented: $showingNewList) {
                TextField("List name", text: $newListName)
                Button("Cancel", role: .cancel) { newListName = "" }
                Button("Add") { addList() }
            } message: {
                Text("Create a custom reminder list.")
            }
            .onAppear {
                ListSeeder.seedIfNeeded(modelContext: modelContext)
            }
        }
    }

    private func addList() {
        let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let list = ReminderList(
            name: name,
            icon: "folder.fill",
            colorHex: "8E8E93",
            sortOrder: lists.count,
            isDefault: false
        )
        modelContext.insert(list)
        try? modelContext.save()
        newListName = ""
        HapticHelper.notification(.success)
    }
}

#Preview {
    ListsView()
        .modelContainer(for: [Reminder.self, ReminderList.self, ProcessingJob.self], inMemory: true)
}
