import BackgroundTasks
import Foundation

enum BackgroundRecordingScheduler {
    static let taskIdentifier = "com.betterreminders.app.processRecording"

    static func scheduleProcessing() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        try? BGTaskScheduler.shared.submit(request)
    }
}
