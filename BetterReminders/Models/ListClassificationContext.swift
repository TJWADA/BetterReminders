import Foundation

struct ListClassificationContext: Equatable {
    let name: String
    let description: String
    let exampleTitles: [String]
    let misclassificationNotes: [String]

    static let maxExampleTitles = 8

    static func from(list: ReminderList) -> ListClassificationContext {
        let examples = list.reminders
            .filter { !$0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(maxExampleTitles)
            .map(\.title)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return ListClassificationContext(
            name: list.name,
            description: list.listDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            exampleTitles: Array(examples),
            misclassificationNotes: list.misclassificationLog
        )
    }

    static func formatListsBlock(_ contexts: [ListClassificationContext]) -> String {
        guard !contexts.isEmpty else { return "None" }

        return contexts.map { context in
            var lines = ["- \(context.name)"]
            if context.description.isEmpty {
                lines.append("  Description: (none)")
            } else {
                lines.append("  Description: \(context.description)")
            }

            if context.exampleTitles.isEmpty {
                lines.append("  Current incomplete reminders: (none)")
            } else {
                lines.append(
                    "  Current incomplete reminders: \(context.exampleTitles.joined(separator: ", "))"
                )
            }

            if context.misclassificationNotes.isEmpty {
                lines.append("  Past corrections: (none)")
            } else {
                lines.append(
                    "  Past corrections: \(context.misclassificationNotes.joined(separator: "; "))"
                )
            }
            return lines.joined(separator: "\n")
        }
        .joined(separator: "\n")
    }
}
