import AVFoundation
import Foundation

@Observable
final class AudioPlaybackService: NSObject {
    static let shared = AudioPlaybackService()

    private(set) var isPlaying = false
    private(set) var currentURL: URL?
    private(set) var duration: TimeInterval = 0
    private(set) var currentTime: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?

    private override init() {
        super.init()
    }

    func fileExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    @discardableResult
    func togglePlayback(for path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        guard fileExists(at: path) else { return false }

        if isPlaying, currentURL == url {
            pause()
            return true
        }

        if currentURL == url, player != nil {
            resume()
            return true
        }

        return play(url: url)
    }

    @discardableResult
    func play(url: URL) -> Bool {
        stop()

        do {
            try configurePlaybackSession()
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            guard newPlayer.play() else { return false }

            player = newPlayer
            currentURL = url
            duration = newPlayer.duration
            currentTime = 0
            isPlaying = true
            startProgressTimer()
            return true
        } catch {
            stop()
            return false
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
    }

    func resume() {
        guard let player else { return }
        guard player.play() else { return }
        isPlaying = true
        startProgressTimer()
    }

    func stop() {
        player?.stop()
        player = nil
        currentURL = nil
        isPlaying = false
        duration = 0
        currentTime = 0
        stopProgressTimer()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func configurePlaybackSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio)
        try session.setActive(true)
    }

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.currentTime = player.currentTime
            self.duration = player.duration
        }
        if let progressTimer {
            RunLoop.main.add(progressTimer, forMode: .common)
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

extension AudioPlaybackService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
    }
}
