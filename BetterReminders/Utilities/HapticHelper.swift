import UIKit

enum HapticHelper {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func recordingStarted() {
        impact(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            impact(.rigid)
        }
    }

    static func recordingStopped() {
        impact(.medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            notification(.success)
        }
    }
}
