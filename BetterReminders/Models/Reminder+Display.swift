import SwiftUI

extension Reminder {
    var priorityColor: Color {
        Self.color(forPriority: priority)
    }

    static func color(forPriority priority: Int) -> Color {
        switch priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .yellow
        default: return .secondary
        }
    }
}
