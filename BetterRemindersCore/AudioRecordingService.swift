import AVFoundation
import Foundation

@Observable
public final class AudioRecordingService {
    public static let shared = AudioRecordingService()

    public private(set) var recordingStartDate: Date?
    public private(set) var currentRecordingURL: URL?

    private var audioRecorder: AVAudioRecorder?

    private init() {}

    public var isRecording: Bool {
        (audioRecorder?.isRecording == true) || RecordingSessionStore.isSessionActive
    }

    public var hasMicrophonePermission: Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }

    public func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    public func startRecording() throws -> URL {
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
    public func stopRecording() -> URL? {
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

    public var elapsedTime: TimeInterval {
        if let start = recordingStartDate {
            return Date().timeIntervalSince(start)
        }
        return RecordingSessionStore.sessionElapsedTime
    }

    public func currentAudioLevel() -> Double {
        guard let recorder = audioRecorder, recorder.isRecording else { return 0 }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let minDb: Float = -60
        let clamped = max(minDb, power)
        return Double((clamped - minDb) / -minDb)
    }

    public func resetStaleSession() {
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

    public enum RecordingError: LocalizedError {
        case alreadyRecording
        case failedToStart
        case permissionDenied

        public var errorDescription: String? {
            switch self {
            case .alreadyRecording: return "Already recording"
            case .failedToStart: return "Failed to start recording"
            case .permissionDenied: return "Microphone permission denied"
            }
        }
    }
}
