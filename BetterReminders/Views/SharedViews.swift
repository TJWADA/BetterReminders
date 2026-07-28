import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0.5; g = 0.5; b = 0.5
        }
        self.init(red: r, green: g, blue: b)
    }
}

struct ListColorBadge: View {
    let colorHex: String
    let icon: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: colorHex).opacity(0.15))
                .frame(width: 44, height: 44)
            Image(systemName: icon)
                .foregroundStyle(Color(hex: colorHex))
        }
    }
}

struct ListNameBadge: View {
    let name: String
    let colorHex: String

    var body: some View {
        Text(name)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: colorHex).opacity(0.15), in: Capsule())
            .foregroundStyle(Color(hex: colorHex))
    }
}

struct ReminderFilterToolbar: View {
    @Binding var hideCompleted: Bool
    @Binding var priorityFilter: PriorityFilter

    var body: some View {
        Menu {
            Toggle("Hide Completed", isOn: $hideCompleted)
            Picker("Priority", selection: $priorityFilter) {
                ForEach(PriorityFilter.allCases) { filter in
                    Text(filter.label).tag(filter)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
}

struct SetupStepRow: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 24, height: 24)
                .background(Color.accentColor.opacity(0.15), in: Circle())
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
