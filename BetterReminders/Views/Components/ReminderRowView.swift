import SwiftUI
import SwiftData
import BetterRemindersCore

struct ReminderRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var reminder: Reminder
    var indentLevel: Int = 0
    var isDropTargeted: Bool = false
    var onCompletionChanged: (() -> Void)? = nil
    var onCollapseChanged: (() -> Void)? = nil
    var onBecameVisible: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil

    @State private var isEditingTitle = false
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Button {
                reminder.toggleCompletion()
                HapticHelper.selection()
                onCompletionChanged?()
                Task {
                    await reminder.updateNotificationForCompletion()
                }
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(reminder.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if reminder.needsManualSort {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 7, height: 7)
                    }
                    titleView
                }

                if let dueDate = reminder.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(ReminderFilters.isOverdue(reminder) ? .red : .secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                onEdit?()
            }
            .onTapGesture(count: 1) {
                guard !isEditingTitle else { return }
                isEditingTitle = true
            }

            if !reminder.subtasks.isEmpty {
                Button {
                    reminder.areSubtasksCollapsed.toggle()
                    HapticHelper.selection()
                    onCollapseChanged?()
                } label: {
                    Image(systemName: reminder.areSubtasksCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
        .padding(.leading, CGFloat(indentLevel) * 28)
        .padding(.horizontal, 4)
        .background(dropHighlight, in: RoundedRectangle(cornerRadius: 8))
        .onAppear {
            onBecameVisible?()
        }
        .onChange(of: isTitleFocused) { _, focused in
            if !focused {
                isEditingTitle = false
                try? modelContext.save()
            }
        }
    }

    @ViewBuilder
    private var titleView: some View {
        if isEditingTitle {
            TextField("Title", text: $reminder.title)
                .focused($isTitleFocused)
                .strikethrough(reminder.isCompleted)
                .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                .lineLimit(1)
                .submitLabel(.done)
                .onSubmit {
                    isTitleFocused = false
                }
                .onAppear {
                    isTitleFocused = true
                }
        } else {
            Text(reminder.title.isEmpty ? "New Reminder" : reminder.title)
                .strikethrough(reminder.isCompleted)
                .foregroundStyle(reminder.isCompleted || reminder.title.isEmpty ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dropHighlight: Color {
        guard isDropTargeted else { return .clear }
        if reminder.parent == nil {
            return Color.indigo.opacity(0.18)
        }
        return Color.secondary.opacity(0.12)
    }
}
