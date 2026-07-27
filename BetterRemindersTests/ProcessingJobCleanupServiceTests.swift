import SwiftData
import XCTest
@testable import BetterReminders

@MainActor
final class ProcessingJobCleanupServiceTests: XCTestCase {
    func testCleanupRemovesOldDoneAndFailedJobs() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!

        context.insert(ProcessingJob(status: .done, audioFilePath: "/tmp/old.m4a", createdAt: oldDate))
        context.insert(ProcessingJob(status: .failed, audioFilePath: "/tmp/failed.m4a", createdAt: oldDate))
        context.insert(ProcessingJob(status: .done, audioFilePath: "/tmp/recent.m4a", createdAt: Date()))
        try context.save()

        ProcessingJobCleanupService.cleanup(modelContext: context)

        let remaining = try context.fetch(FetchDescriptor<ProcessingJob>())
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.audioFilePath, "/tmp/recent.m4a")
    }

    func testCleanupCapsTotalJobsAtTwenty() throws {
        let container = try makeContainer()
        let context = container.mainContext

        for index in 0..<25 {
            context.insert(
                ProcessingJob(
                    status: .done,
                    audioFilePath: "/tmp/\(index).m4a",
                    createdAt: Date().addingTimeInterval(TimeInterval(-index))
                )
            )
        }
        try context.save()

        ProcessingJobCleanupService.cleanup(modelContext: context)

        let remaining = try context.fetch(
            FetchDescriptor<ProcessingJob>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        )
        XCTAssertEqual(remaining.count, 20)
        XCTAssertEqual(remaining.first?.audioFilePath, "/tmp/0.m4a")
        XCTAssertEqual(remaining.last?.audioFilePath, "/tmp/19.m4a")
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([ProcessingJob.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
