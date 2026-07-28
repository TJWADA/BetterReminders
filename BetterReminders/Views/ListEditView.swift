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

@MainActor
enum ListEditActions {
    static func save(
        name: String,
        icon: String,
        colorHex: String,
        existingList: ReminderList?,
        allLists: [ReminderList],
        modelContext: ModelContext
    ) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

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
        return true
    }

    static func delete(list: ReminderList, modelContext: ModelContext) {
        modelContext.delete(list)
        try? modelContext.save()
    }
}

struct ListIconPickerRow: View {
    @Binding var icon: String
    var colorHex: String
    var compact: Bool = false

    private var cellSize: CGFloat { compact ? 36 : 44 }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: compact ? 8 : 12) {
                ForEach(ListStyle.presetIcons, id: \.self) { symbol in
                    Button {
                        icon = symbol
                        HapticHelper.selection()
                        // #region agent log
                        DebugSessionLog.write(
                            location: "ListIconPickerRow.swift:iconTap",
                            message: "Icon picker selection changed",
                            hypothesisId: "H5",
                            data: ["symbol": symbol, "compact": compact]
                        )
                        // #endregion
                    } label: {
                        Image(systemName: symbol)
                            .font(compact ? .body : .title2)
                            .frame(width: cellSize, height: cellSize)
                            .background(
                                icon == symbol
                                    ? Color(hex: colorHex).opacity(0.2)
                                    : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: compact ? 8 : 10)
                            )
                            .foregroundStyle(
                                icon == symbol ? Color(hex: colorHex) : .secondary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, compact ? 16 : 0)
        }
    }
}

struct ListColorPickerRow: View {
    @Binding var colorHex: String
    var compact: Bool = false

    private var cellSize: CGFloat { compact ? 32 : 36 }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: compact ? 10 : 12) {
                ForEach(ListStyle.presetColors, id: \.self) { hex in
                    Button {
                        colorHex = hex
                        HapticHelper.selection()
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: cellSize, height: cellSize)
                            .overlay {
                                if colorHex == hex {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, compact ? 16 : 0)
        }
    }
}

struct ListEditCompactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var list: ReminderList

    @State private var name: String
    @State private var icon: String
    @State private var colorHex: String
    @State private var showingDeleteConfirm = false

    init(list: ReminderList) {
        self.list = list
        _name = State(initialValue: list.name)
        _icon = State(initialValue: list.icon)
        _colorHex = State(initialValue: list.colorHex)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                TextField("List name", text: $name)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                Button("Save") { save() }
                    .font(.body.weight(.semibold))
                    .disabled(!isValid)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                ListIconPickerRow(icon: $icon, colorHex: colorHex, compact: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                ListColorPickerRow(colorHex: $colorHex, compact: true)
            }

            ListIconTile(
                name: name.isEmpty ? list.name : name,
                icon: icon,
                colorHex: colorHex,
                incompleteCount: list.incompleteCount
            )
            .frame(maxWidth: 180)
            .padding(.horizontal, 16)

            Spacer(minLength: 0)

            Button("Delete List", role: .destructive) {
                showingDeleteConfirm = true
            }
            .padding(.bottom, 8)
        }
        .onAppear {
            // #region agent log
            DebugSessionLog.write(
                location: "ListEditCompactView.swift:onAppear",
                message: "Compact edit sheet appeared",
                hypothesisId: "H5",
                data: ["icon": icon, "colorHex": colorHex]
            )
            // #endregion
        }
        .confirmationDialog(
            "Delete this list and all its reminders?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                ListEditActions.delete(list: list, modelContext: modelContext)
                dismiss()
            }
        }
    }

    private func save() {
        guard ListEditActions.save(
            name: name,
            icon: icon,
            colorHex: colorHex,
            existingList: list,
            allLists: [],
            modelContext: modelContext
        ) else { return }
        dismiss()
    }
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
                    ListIconPickerRow(icon: $icon, colorHex: colorHex)
                        .padding(.vertical, 4)
                }

                Section("Color") {
                    ListColorPickerRow(colorHex: $colorHex)
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
        guard ListEditActions.save(
            name: name,
            icon: icon,
            colorHex: colorHex,
            existingList: existingList,
            allLists: allLists,
            modelContext: modelContext
        ) else { return }
        dismiss()
    }

    private func deleteList() {
        guard let list = existingList else { return }
        ListEditActions.delete(list: list, modelContext: modelContext)
        dismiss()
    }
}
