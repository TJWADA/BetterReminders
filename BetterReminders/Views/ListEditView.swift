import SwiftUI
import SwiftData
import BetterRemindersCore

@MainActor
enum ListEditActions {
    static func save(
        name: String,
        icon: String,
        colorHex: String,
        listDescription: String,
        existingList: ReminderList?,
        allLists: [ReminderList],
        modelContext: ModelContext
    ) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let trimmedDescription = listDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        if let list = existingList {
            list.name = trimmed
            list.icon = icon
            list.colorHex = colorHex
            list.listDescription = trimmedDescription
        } else {
            let nextOrder = (allLists.map(\.sortOrder).max() ?? -1) + 1
            let list = ReminderList(
                name: trimmed,
                icon: icon,
                colorHex: colorHex,
                sortOrder: nextOrder,
                listDescription: trimmedDescription
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

struct ListColorGrid: View {
    @Binding var colorHex: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
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
                                Circle()
                                    .fill(.white)
                                    .frame(width: 10, height: 10)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ListIconGrid: View {
    @Binding var icon: String
    var colorHex: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ListStyle.presetIcons, id: \.self) { symbol in
                Button {
                    icon = symbol
                    HapticHelper.selection()
                } label: {
                    Image(systemName: symbol)
                        .font(.body)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(icon == symbol ? Color(hex: colorHex) : .secondary)
                        .background(
                            Circle()
                                .fill(icon == symbol ? Color(hex: colorHex).opacity(0.18) : Color.secondary.opacity(0.08))
                        )
                        .overlay {
                            if icon == symbol {
                                Circle()
                                    .strokeBorder(Color(hex: colorHex), lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ListEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let existingList: ReminderList?

    @State private var name: String
    @State private var icon: String
    @State private var colorHex: String
    @State private var listDescription: String
    @State private var showingDeleteConfirm = false
    @FocusState private var isNameFieldFocused: Bool

    init(list: ReminderList? = nil) {
        self.existingList = list
        _name = State(initialValue: list?.name ?? "")
        _icon = State(initialValue: list?.icon ?? ListStyle.presetIcons[0])
        _colorHex = State(initialValue: list?.colorHex ?? ListStyle.presetColors[0])
        _listDescription = State(initialValue: list?.listDescription ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 10) {
                        Text("Name:")
                            .foregroundStyle(.secondary)
                        TextField("List name", text: $name)
                            .focused($isNameFieldFocused)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.5)
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description:")
                            .foregroundStyle(.secondary)
                        TextField(
                            "e.g. CSE 121 programming class. Prefer short titles like \"Finish Lab 3\".",
                            text: $listDescription,
                            axis: .vertical
                        )
                        .lineLimit(3...6)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.5)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color:")
                            .foregroundStyle(.secondary)
                        ListColorGrid(colorHex: $colorHex)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Icon:")
                            .foregroundStyle(.secondary)
                        ListIconGrid(icon: $icon, colorHex: colorHex)
                    }

                    if existingList != nil {
                        Button("Delete List", role: .destructive) {
                            showingDeleteConfirm = true
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { closeSheet() }
                    .buttonStyle(.bordered)
                Button("OK") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
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
        .onAppear {
            isNameFieldFocused = existingList == nil
        }
    }

    private func closeSheet() {
        isNameFieldFocused = false
        Task { @MainActor in
            dismiss()
        }
    }

    private func save() {
        let allLists = (try? modelContext.fetch(FetchDescriptor<ReminderList>())) ?? []
        guard ListEditActions.save(
            name: name,
            icon: icon,
            colorHex: colorHex,
            listDescription: listDescription,
            existingList: existingList,
            allLists: allLists,
            modelContext: modelContext
        ) else { return }
        closeSheet()
    }

    private func deleteList() {
        guard let list = existingList else { return }
        ListEditActions.delete(list: list, modelContext: modelContext)
        closeSheet()
    }
}
