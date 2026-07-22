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
        retainAudio: Bool
    ) async {
        isProcessing = true
        lastError = nil
        lastCreatedTitles = []
        currentStatus = .pending

        let audioPath = audioURL.path
        let job = ProcessingJob(status: .pending, audioFilePath: audioPath)
        modelContext.insert(job)

        do {
            currentStatus = .transcribing
            job.status = .transcribing
            try modelContext.save()

            let transcript = try await SpeechService.transcribe(audioURL: audioURL)
            job.transcript = transcript

            currentStatus = .parsing
            job.status = .parsing
            try modelContext.save()

            let lists = try modelContext.fetch(FetchDescriptor<ReminderList>(
                sortBy: [SortDescriptor(\.sortOrder)]
            ))
            let listNames = lists.map(\.name)

            let parsed = try await ReminderParserService.parse(
                transcript: transcript,
                listNames: listNames,
                recentCorrections: AppSettings.shared.recentCorrections
            )

            for item in parsed.reminders {
                let targetList = ListSeeder.findList(named: item.list, in: lists)
                    ?? ListSeeder.fallbackList(from: lists)

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
            }

            if !retainAudio {
                try? FileManager.default.removeItem(at: audioURL)
            }

            job.status = .done
            currentStatus = .done
            try modelContext.save()

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

    @MainActor
    func retryJob(_ job: ProcessingJob, modelContext: ModelContext, retainAudio: Bool) async {
        guard let transcript = job.transcript, !transcript.isEmpty else {
            let url = URL(fileURLWithPath: job.audioFilePath)
            await processRecording(audioURL: url, modelContext: modelContext, retainAudio: retainAudio)
            return
        }

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
            let parsed = try await ReminderParserService.parse(
                transcript: transcript,
                listNames: lists.map(\.name),
                recentCorrections: AppSettings.shared.recentCorrections
            )

            for item in parsed.reminders {
                let targetList = ListSeeder.findList(named: item.list, in: lists)
                    ?? ListSeeder.fallbackList(from: lists)
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
            }

            job.status = .done
            currentStatus = .done
            try modelContext.save()
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
