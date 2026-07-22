import Foundation
import SwiftData

@Model
final class ProcessingJob {
    var id: UUID
    var statusRaw: String
    var audioFilePath: String
    var errorMessage: String?
    var createdAt: Date
    var transcript: String?

    init(
        id: UUID = UUID(),
        status: JobStatus = .pending,
        audioFilePath: String,
        errorMessage: String? = nil,
        createdAt: Date = Date(),
        transcript: String? = nil
    ) {
        self.id = id
        self.statusRaw = status.rawValue
        self.audioFilePath = audioFilePath
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.transcript = transcript
    }

    var status: JobStatus {
        get { JobStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
}
