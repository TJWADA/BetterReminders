import Foundation
import SwiftData
import UserNotifications
import BetterRemindersCore

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
        defaultList: ReminderList? = nil
    ) async {
        guard !isProcessing else { return }

        isProcessing = true
        lastError = nil
        lastCreatedTitles = []
        currentStatus = .pending

        let audioPath = audioURL.path
        let job = ProcessingJob(status: .pending, audioFilePath: audioPath)
        modelContext.insert(job)

        do {
            guard FileManager.default.fileExists(atPath: audioPath) else {
                throw ProcessingError.recordingFileMissing
            }

            currentStatus = .transcribing
            job.status = .transcribing
            try modelContext.save()

            let transcript = try await SpeechService.transcribe(audioURL: audioURL)
            job.transcript = transcript

            try await runParsingPipeline(
                job: job,
                transcript: transcript,
                modelContext: modelContext,
                defaultList: defaultList,
                retainAudioPath: retainAudio ? audioPath : nil
            )

            if !retainAudio {
                try? FileManager.default.removeItem(at: audioURL)
            }
        } catch {
            job.status = .failed
            job.errorMessage = error.localizedDescription
            currentStatus = .failed
            lastError = error.localizedDescription
            try? modelContext.save()
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
                return "No reminder lists available. Create a list first, then try again."
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
                retainAudio: retainAudio
            )
            return
        }

        guard !isProcessing else { return }

        isProcessing = true
        lastError = nil
        lastCreatedTitles = []
        currentStatus = .parsing
        job.status = .parsing
        job.errorMessage = nil

        do {
            try await runParsingPipeline(
                job: job,
                transcript: transcript,
                modelContext: modelContext,
                retainAudioPath: retainAudio ? job.audioFilePath : nil
            )
        } catch {
            job.status = .failed
            job.errorMessage = error.localizedDescription
            currentStatus = .failed
            lastError = error.localizedDescription
            try? modelContext.save()
        }

        isProcessing = false
    }

    @MainActor
    private func runParsingPipeline(
        job: ProcessingJob,
        transcript: String,
        modelContext: ModelContext,
        defaultList: ReminderList? = nil,
        retainAudioPath: String?
    ) async throws {
        currentStatus = .parsing
        job.status = .parsing
        try modelContext.save()

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

        _ = await insertParsedReminders(
            parsed.reminders,
            transcript: transcript,
            lists: lists,
            defaultList: defaultList,
            retainAudioPath: retainAudioPath,
            modelContext: modelContext
        )

        job.status = .done
        currentStatus = .done
        try modelContext.save()
        ProcessingJobCleanupService.cleanup(modelContext: modelContext)
        await sendConfirmationNotification(titles: lastCreatedTitles)
    }

    @MainActor
    private func insertParsedReminders(
        _ items: [ParsedReminder],
        transcript: String,
        lists: [ReminderList],
        defaultList: ReminderList? = nil,
        retainAudioPath: String?,
        modelContext: ModelContext
    ) async -> (firstTitle: String?, firstListName: String?, firstListIcon: String?) {
        var firstTitle: String?
        var firstListName: String?
        var firstListIcon: String?

        for item in items {
            let targetList = ListSeeder.findList(named: item.list, in: lists)
                ?? defaultList
                ?? ListSeeder.fallbackList(from: lists)

            guard let targetList else { continue }

            let reminder = Reminder(
                title: item.title,
                rawTranscript: transcript,
                dueDate: ReminderParserService.parseDueDate(item.dueDate),
                priority: ReminderParserService.priorityValue(from: item.priority),
                audioFilePath: retainAudioPath,
                list: targetList
            )
            modelContext.insert(reminder)
            lastCreatedTitles.append(item.title)
            await NotificationSchedulingService.schedule(for: reminder)

            if firstTitle == nil {
                firstTitle = item.title
                firstListName = targetList.name
                firstListIcon = targetList.icon
            }
        }

        return (firstTitle, firstListName, firstListIcon)
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
