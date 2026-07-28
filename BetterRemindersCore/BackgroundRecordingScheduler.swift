import BackgroundTasks
import Foundation

public enum BackgroundRecordingScheduler {
    public static let taskIdentifier = "com.betterreminders.app.processRecording"

    public static func scheduleProcessing() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        try? BGTaskScheduler.shared.submit(request)
    }
}
