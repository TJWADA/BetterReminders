import SwiftUI
import SwiftData
import BetterRemindersCore

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

struct ListColorTheme {
    let colorHex: String

    var baseColor: Color { Color(hex: colorHex) }

    var tileGradient: LinearGradient {
        LinearGradient(
            colors: [
                baseColor.opacity(0.22),
                baseColor.opacity(0.12),
                baseColor.opacity(0.06),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var headerGradient: LinearGradient {
        LinearGradient(
            colors: [
                baseColor.opacity(0.20),
                baseColor.opacity(0.10),
                baseColor.opacity(0.03),
                Color(.systemBackground).opacity(0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var iconGradient: LinearGradient {
        LinearGradient(
            colors: [baseColor.opacity(0.95), baseColor.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private enum ListTileMetrics {
    static let aspectRatio: CGFloat = 1.22
    static let cornerRadius: CGFloat = 14
    static let padding: CGFloat = 11
    static let iconSize: CGFloat = 18
}

struct ListHeaderIcon: View {
    let icon: String
    let colorHex: String
    var size: CGFloat = 32

    private var theme: ListColorTheme { ListColorTheme(colorHex: colorHex) }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.5, weight: .medium))
            .foregroundStyle(theme.iconGradient)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                    .fill(theme.baseColor.opacity(0.15))
            )
    }
}

struct ListIconTile: View {
    let name: String
    let icon: String
    let colorHex: String
    var incompleteCount: Int = 0

    init(list: ReminderList) {
        self.name = list.name
        self.icon = list.icon
        self.colorHex = list.colorHex
        self.incompleteCount = list.incompleteCount
    }

    init(name: String, icon: String, colorHex: String, incompleteCount: Int = 0) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.incompleteCount = incompleteCount
    }

    private var theme: ListColorTheme { ListColorTheme(colorHex: colorHex) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: ListTileMetrics.cornerRadius, style: .continuous)
                .fill(theme.tileGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: ListTileMetrics.cornerRadius, style: .continuous)
                        .strokeBorder(theme.baseColor.opacity(0.12), lineWidth: 0.5)
                }

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: icon)
                        .font(.system(size: ListTileMetrics.iconSize, weight: .medium))
                        .foregroundStyle(theme.iconGradient)
                    Spacer(minLength: 4)
                    Text("\(incompleteCount)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.baseColor.opacity(0.75))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(ListTileMetrics.padding)
        }
        .aspectRatio(ListTileMetrics.aspectRatio, contentMode: .fit)
    }
}

struct AddListTile: View {
    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary.opacity(0.7))
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.06))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 0.5)
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

struct ReminderRowView: View {
    @Bindable var reminder: Reminder

    var body: some View {
        HStack(spacing: 12) {
            Button {
                reminder.isCompleted.toggle()
                HapticHelper.selection()
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
                Text(reminder.title)
                    .strikethrough(reminder.isCompleted)
                    .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                if let dueDate = reminder.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(ReminderFilters.isOverdue(reminder) ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct ScrollEdgeFade: View {
    let isTop: Bool

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(.systemBackground), location: 0),
                .init(color: Color(.systemBackground), location: 0.65),
                .init(color: Color(.systemBackground).opacity(0), location: 1),
            ],
            startPoint: isTop ? .top : .bottom,
            endPoint: isTop ? .bottom : .top
        )
        .allowsHitTesting(false)
    }
}

extension View {
    func listColoredHeaderBackground(colorHex: String) -> some View {
        let theme = ListColorTheme(colorHex: colorHex)
        return toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(theme.headerGradient, for: .navigationBar)
    }

    func topBarGradientBackground(fadeExtension: CGFloat = 40) -> some View {
        background(alignment: .top) {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground).opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: fadeExtension + 60)
            .allowsHitTesting(false)
        }
    }

    func bottomBarGradientBackground(fadeExtension: CGFloat = 40) -> some View {
        background(alignment: .bottom) {
            LinearGradient(
                colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: fadeExtension + 60)
            .allowsHitTesting(false)
        }
    }

    func scrollEdgeFadeOverlay(isTop: Bool, height: CGFloat = 72) -> some View {
        ScrollEdgeFade(isTop: isTop)
            .frame(height: height)
    }
}
