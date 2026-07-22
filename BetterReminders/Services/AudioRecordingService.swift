import AVFoundation
import Foundation

@Observable
final class AudioRecordingService {
    static let shared = AudioRecordingService()

    private(set) var isRecording = false
    private(set) var recordingStartDate: Date?
    private(set) var currentRecordingURL: URL?

    private var audioRecorder: AVAudioRecorder?

    private init() {}

    var hasMicrophonePermission: Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() throws -> URL {
        if isRecording {
            throw RecordingError.alreadyRecording
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)

        let url = Self.makeRecordingURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        guard audioRecorder?.record() == true else {
            throw RecordingError.failedToStart
        }

        isRecording = true
        recordingStartDate = Date()
        currentRecordingURL = url
        return url
    }

    @discardableResult
    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        recordingStartDate = nil
        let url = currentRecordingURL
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return url
    }

    func toggleRecording() throws -> (started: Bool, url: URL?) {
        if isRecording {
            let url = stopRecording()
            return (false, url)
        } else {
            let url = try startRecording()
            return (true, url)
        }
    }

    var elapsedTime: TimeInterval {
        guard let start = recordingStartDate else { return 0 }
        return Date().timeIntervalSince(start)
    }

    private static func makeRecordingURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(UUID().uuidString).m4a")
    }

    enum RecordingError: LocalizedError {
        case alreadyRecording
        case failedToStart
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .alreadyRecording: return "Already recording"
            case .failedToStart: return "Failed to start recording"
            case .permissionDenied: return "Microphone permission denied"
            }
        }
    }
}
