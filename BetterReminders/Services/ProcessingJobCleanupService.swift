import Foundation
import SwiftData

enum ProcessingJobCleanupService {
    private static let retentionDays = 7
    private static let maxRetainedJobs = 20

    @MainActor
    static func cleanup(modelContext: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()

        guard let allJobs = try? modelContext.fetch(
            FetchDescriptor<ProcessingJob>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        ) else { return }

        for job in allJobs where job.createdAt < cutoff && (job.status == .done || job.status == .failed) {
            modelContext.delete(job)
        }

        guard let remaining = try? modelContext.fetch(
            FetchDescriptor<ProcessingJob>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        ) else { return }

        if remaining.count > maxRetainedJobs {
            for job in remaining.dropFirst(maxRetainedJobs) {
                modelContext.delete(job)
            }
        }

        try? modelContext.save()
    }
}
