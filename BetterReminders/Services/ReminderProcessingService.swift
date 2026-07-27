import Foundation
import SwiftData
import UserNotifications

@Observable
final class ReminderProcessingService {
    static let shared = ReminderProcessingService()

    private(set) var isProcessing = false
    private(set) var currentStatus: JobStatus?
    private(set) var lastError: String?
    private(set) var lastCreatedTitles: [String] = []

    private init() {}

    @MainActor
    func processRecording(
        audioURL: URL,
        modelContext: ModelContext,
        retainAudio: Bool,
        updatesLiveActivity: Bool = true
    ) async {
        guard !isProcessing else { return }

        isProcessing = true
        lastError = nil
        lastCreatedTitles = []
        currentStatus = .pending

        ListSeeder.seedIfNeeded(modelContext: modelContext)

        let audioPath = audioURL.path
        let job = ProcessingJob(status: .pending, audioFilePath: audioPath)
        modelContext.insert(job)

        var firstResultTitle: String?
        var firstResultListName: String?
        var firstResultListIcon: String?

        do {
            guard FileManager.default.fileExists(atPath: audioPath) else {
                throw ProcessingError.recordingFileMissing
            }

            currentStatus = .transcribing
            job.status = .transcribing
            try modelContext.save()
            if updatesLiveActivity {
                await RecordingLiveActivityManager.showTranscribing()
            }

            let transcript = try await SpeechService.transcribe(audioURL: audioURL)
            job.transcript = transcript

            currentStatus = .parsing
            job.status = .parsing
            try modelContext.save()
            if updatesLiveActivity {
                await RecordingLiveActivityManager.showParsing()
            }

            let lists = try modelContext.fetch(FetchDescriptor<ReminderList>(
                sortBy: [SortDescriptor(\.sortOrder)]
            ))
            guard !lists.isEmpty else {
                throw ProcessingError.noListsAvailable
            }

            let parsed = try await ReminderParserService.parse(
                transcript: transcript,
                listNames: lists.map(\.name),
                recentCorrections: AppSettings.shared.recentCorrections
            )

            for item in parsed.reminders {
                let targetList = ListSeeder.findList(named: item.list, in: lists)
                    ?? ListSeeder.fallbackList(from: lists)

                guard let targetList else {
                    throw ProcessingError.noListsAvailable
                }

                let reminder = Reminder(
                    title: item.title,
                    rawTranscript: transcript,
                    dueDate: ReminderParserService.parseDueDate(item.dueDate),
                    priority: ReminderParserService.priorityValue(from: item.priority),
                    audioFilePath: retainAudio ? audioPath : nil,
                    list: targetList
                )
                modelContext.insert(reminder)
                lastCreatedTitles.append(item.title)
                await NotificationSchedulingService.schedule(for: reminder)

                if firstResultTitle == nil {
                    firstResultTitle = item.title
                    firstResultListName = targetList.name
                    firstResultListIcon = targetList.icon
                }
            }

            job.status = .done
            currentStatus = .done
            try modelContext.save()

            ProcessingJobCleanupService.cleanup(modelContext: modelContext)

            if !retainAudio {
                try? FileManager.default.removeItem(at: audioURL)
            }

            if updatesLiveActivity,
               let firstResultTitle,
               let firstResultListName,
               let firstResultListIcon {
                await RecordingLiveActivityManager.showCompleted(
                    title: firstResultTitle,
                    listName: firstResultListName,
                    listIcon: firstResultListIcon
                )
            }

            await sendConfirmationNotification(titles: lastCreatedTitles)
        } catch {
            job.status = .failed
            job.errorMessage = error.localizedDescription
            currentStatus = .failed
            lastError = error.localizedDescription
            try? modelContext.save()

            if updatesLiveActivity {
                await RecordingLiveActivityManager.showFailed(message: error.localizedDescription)
            }
        }

        isProcessing = false
    }

    enum ProcessingError: LocalizedError {
        case recordingFileMissing
        case noListsAvailable

        var errorDescription: String? {
            switch self {
            case .recordingFileMissing:
                return "Recording file could not be found"
            case .noListsAvailable:
                return "No reminder lists available. Open the Lists tab once, then try again."
            }
        }
    }

    @MainActor
    func retryJob(_ job: ProcessingJob, modelContext: ModelContext, retainAudio: Bool) async {
        guard let transcript = job.transcript, !transcript.isEmpty else {
            let url = URL(fileURLWithPath: job.audioFilePath)
            guard FileManager.default.fileExists(atPath: url.path) else {
                job.status = .failed
                job.errorMessage = ProcessingError.recordingFileMissing.localizedDescription
                lastError = job.errorMessage
                try? modelContext.save()
                return
            }
            await processRecording(
                audioURL: url,
                modelContext: modelContext,
                retainAudio: retainAudio,
                updatesLiveActivity: false
            )
            return
        }

        guard !isProcessing else { return }

        ListSeeder.seedIfNeeded(modelContext: modelContext)

        isProcessing = true
        lastError = nil
        lastCreatedTitles = []
        currentStatus = .parsing
        job.status = .parsing
        job.errorMessage = nil

        do {
            let lists = try modelContext.fetch(FetchDescriptor<ReminderList>(
                sortBy: [SortDescriptor(\.sortOrder)]
            ))
            guard !lists.isEmpty else {
                throw ProcessingError.noListsAvailable
            }

            let parsed = try await ReminderParserService.parse(
                transcript: transcript,
                listNames: lists.map(\.name),
                recentCorrections: AppSettings.shared.recentCorrections
            )

            for item in parsed.reminders {
                let targetList = ListSeeder.findList(named: item.list, in: lists)
                    ?? ListSeeder.fallbackList(from: lists)
                guard let targetList else {
                    throw ProcessingError.noListsAvailable
                }
                let reminder = Reminder(
                    title: item.title,
                    rawTranscript: transcript,
                    dueDate: ReminderParserService.parseDueDate(item.dueDate),
                    priority: ReminderParserService.priorityValue(from: item.priority),
                    audioFilePath: retainAudio ? job.audioFilePath : nil,
                    list: targetList
                )
                modelContext.insert(reminder)
                lastCreatedTitles.append(item.title)
                await NotificationSchedulingService.schedule(for: reminder)
            }

            job.status = .done
            currentStatus = .done
            try modelContext.save()
            ProcessingJobCleanupService.cleanup(modelContext: modelContext)
            await sendConfirmationNotification(titles: lastCreatedTitles)
        } catch {
            job.status = .failed
            job.errorMessage = error.localizedDescription
            currentStatus = .failed
            lastError = error.localizedDescription
            try? modelContext.save()
        }

        isProcessing = false
    }

    private func sendConfirmationNotification(titles: [String]) async {
        guard !titles.isEmpty else { return }
        let content = UNMutableNotificationContent()
        if titles.count == 1 {
            content.title = "Reminder added"
            content.body = titles[0]
        } else {
            content.title = "\(titles.count) reminders added"
            content.body = titles.joined(separator: ", ")
        }
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
