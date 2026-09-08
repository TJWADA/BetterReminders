import SwiftUI
import SwiftData
import BetterRemindersCore

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

struct ListTileIcon: View {
    let icon: String
    let colorHex: String

    private var theme: ListColorTheme { ListColorTheme(colorHex: colorHex) }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: ListTileMetrics.iconSize, weight: .medium))
            .foregroundStyle(theme.iconGradient)
    }
}

struct ListIconTile: View {
    let name: String
    let icon: String
    let colorHex: String
    var incompleteCount: Int = 0
    var needsManualSortCount: Int = 0

    init(list: ReminderList) {
        self.name = list.name
        self.icon = list.icon
        self.colorHex = list.colorHex
        self.incompleteCount = list.incompleteCount
        self.needsManualSortCount = list.needsManualSortCount
    }

    init(name: String, icon: String, colorHex: String, incompleteCount: Int = 0, needsManualSortCount: Int = 0) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.incompleteCount = incompleteCount
        self.needsManualSortCount = needsManualSortCount
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
                    ListTileIcon(icon: icon, colorHex: colorHex)
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(incompleteCount)")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.baseColor.opacity(0.75))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        if needsManualSortCount > 0 {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                        }
                    }
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

struct EmptyListGridCell: View {
    var body: some View {
        Color.clear
            .aspectRatio(ListTileMetrics.aspectRatio, contentMode: .fit)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
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
            .padding(ListTileMetrics.padding)
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

struct ProcessingBannerView: View {
    let status: String

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text(status)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

struct RecordingErrorBannerView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .lineLimit(2)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
