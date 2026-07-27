import AVFoundation
import Foundation

@Observable
final class AudioRecordingService {
    static let shared = AudioRecordingService()

    private(set) var recordingStartDate: Date?
    private(set) var currentRecordingURL: URL?

    private var audioRecorder: AVAudioRecorder?

    private init() {}

    /// True if the recorder is running or a persisted Action Button session is active.
    var isRecording: Bool {
        (audioRecorder?.isRecording == true) || RecordingSessionStore.isSessionActive
    }

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

        try configureAudioSession()

        let url = Self.makeRecordingURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
        guard audioRecorder?.record() == true else {
            throw RecordingError.failedToStart
        }

        recordingStartDate = Date()
        currentRecordingURL = url
        RecordingSessionStore.markStarted(path: url.path)
        return url
    }

    @discardableResult
    func stopRecording() -> URL? {
        if let recorder = audioRecorder, recorder.isRecording {
            recorder.stop()
            audioRecorder = nil
            recordingStartDate = nil
            let url = currentRecordingURL
            currentRecordingURL = nil
            RecordingSessionStore.markStopped()
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            return url
        }

        // Recover when Action Button stop runs in a new intent invocation without a live recorder.
        if RecordingSessionStore.isSessionActive,
           let path = RecordingSessionStore.activeRecordingPath {
            RecordingSessionStore.markStopped()
            audioRecorder = nil
            recordingStartDate = nil
            currentRecordingURL = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            return URL(fileURLWithPath: path)
        }

        return nil
    }

    var elapsedTime: TimeInterval {
        guard let start = recordingStartDate else { return 0 }
        return Date().timeIntervalSince(start)
    }

    func currentAudioLevel() -> Double {
        guard let recorder = audioRecorder, recorder.isRecording else { return 0 }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let minDb: Float = -60
        let clamped = max(minDb, power)
        return Double((clamped - minDb) / -minDb)
    }

    func resetStaleSession() {
        if RecordingSessionStore.isSessionActive, audioRecorder == nil {
            RecordingSessionStore.markStopped()
        }
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
        )
        try session.setActive(true)
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
