import Foundation

enum DurationFormatter {
    static func mmss(from interval: TimeInterval) -> String {
        let seconds = Int(interval)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
