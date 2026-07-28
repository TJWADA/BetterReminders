import SwiftUI
import SwiftData
import BetterRemindersCore

enum ListStyle {
    static let presetColors = [
        "34C759", "007AFF", "AF52DE", "FF3B30",
        "FF9500", "FFD60A", "5856D6", "FF2D55",
        "00C7BE", "8E8E93",
    ]

    static let presetIcons = [
        "cart.fill", "briefcase.fill", "person.fill", "heart.fill",
        "car.fill", "lightbulb.fill", "house.fill", "book.fill",
        "star.fill", "flag.fill", "gift.fill", "bell.fill",
        "fork.knife", "pawprint.fill", "airplane", "graduationcap.fill",
    ]
}

struct ListEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ReminderList.sortOrder) private var allLists: [ReminderList]

    let existingList: ReminderList?

    @State private var name: String
    @State private var icon: String
    @State private var colorHex: String
    @State private var showingDeleteConfirm = false

    init(list: ReminderList? = nil) {
        self.existingList = list
        _name = State(initialValue: list?.name ?? "")
        _icon = State(initialValue: list?.icon ?? ListStyle.presetIcons[0])
        _colorHex = State(initialValue: list?.colorHex ?? ListStyle.presetColors[0])
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("List name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(ListStyle.presetIcons, id: \.self) { symbol in
                            Button {
                                icon = symbol
                                HapticHelper.selection()
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        icon == symbol
                                            ? Color(hex: colorHex).opacity(0.2)
                                            : Color.secondary.opacity(0.08),
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                    .foregroundStyle(
                                        icon == symbol ? Color(hex: colorHex) : .secondary
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(ListStyle.presetColors, id: \.self) { hex in
                            Button {
                                colorHex = hex
                                HapticHelper.selection()
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if colorHex == hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    ListIconTile(
                        name: name.isEmpty ? "New List" : name,
                        icon: icon,
                        colorHex: colorHex,
                        incompleteCount: existingList?.incompleteCount ?? 0
                    )
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                if existingList != nil {
                    Section {
                        Button("Delete List", role: .destructive) {
                            showingDeleteConfirm = true
                        }
                    }
                }
            }
            .navigationTitle(existingList == nil ? "New List" : "Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .confirmationDialog(
                "Delete this list and all its reminders?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteList()
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let list = existingList {
            list.name = trimmed
            list.icon = icon
            list.colorHex = colorHex
        } else {
            let nextOrder = (allLists.map(\.sortOrder).max() ?? -1) + 1
            let list = ReminderList(
                name: trimmed,
                icon: icon,
                colorHex: colorHex,
                sortOrder: nextOrder
            )
            modelContext.insert(list)
        }

        try? modelContext.save()
        HapticHelper.notification(.success)
        dismiss()
    }

    private func deleteList() {
        guard let list = existingList else { return }
        modelContext.delete(list)
        try? modelContext.save()
        dismiss()
    }
}
