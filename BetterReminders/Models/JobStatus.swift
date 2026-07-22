import Foundation

enum JobStatus: String, Codable, CaseIterable {
    case pending
    case transcribing
    case parsing
    case done
    case failed
}
