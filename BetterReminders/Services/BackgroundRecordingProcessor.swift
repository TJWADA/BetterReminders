import BackgroundTasks
import Foundation
import SwiftData

enum BackgroundRecordingProcessor {
    static let taskIdentifier = "com.betterreminders.app.processRecording"

    static func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handle(processingTask)
        }
    }

    static func scheduleProcessing() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        try? BGTaskScheduler.shared.submit(request)
    }

    @MainActor
    static func processAllPending() async {
        guard let container = try? ModelContainer(
            for: Reminder.self, ReminderList.self, ProcessingJob.self
        ) else { return }

        while let url = PendingRecordingStore.dequeue() {
            await ReminderProcessingService.shared.processRecording(
                audioURL: url,
                modelContext: container.mainContext,
                retainAudio: AppSettings.shared.retainAudio,
                updatesLiveActivity: true
            )
        }
        ProcessingJobCleanupService.cleanup(modelContext: container.mainContext)
    }

    private static func handle(_ task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task { @MainActor in
            await processAllPending()
            task.setTaskCompleted(success: true)
        }
    }
}
