import SwiftUI

extension Reminder {
    var priorityColor: Color {
        switch priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .yellow
        default: return .secondary
        }
    }
}
