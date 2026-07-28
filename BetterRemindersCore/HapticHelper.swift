import UIKit

public enum HapticHelper {
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    public static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    public static func recordingStarted() {
        impact(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            impact(.rigid)
        }
    }

    public static func recordingStopped() {
        impact(.medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            notification(.success)
        }
    }
}
