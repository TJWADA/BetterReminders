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

        let afterAgeFilter = allJobs.filter {
            !($0.createdAt < cutoff && ($0.status == .done || $0.status == .failed))
        }
        let jobsToKeep = Set(afterAgeFilter.prefix(maxRetainedJobs).map(\.persistentModelID))

        for job in allJobs {
            let isStale = job.createdAt < cutoff && (job.status == .done || job.status == .failed)
            if isStale || !jobsToKeep.contains(job.persistentModelID) {
                modelContext.delete(job)
            }
        }

        try? modelContext.save()
    }
}
