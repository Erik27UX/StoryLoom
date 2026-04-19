import AVFoundation
import Combine
import SwiftUI

class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var durationTimer: Timer?
    private var playbackTimer: Timer?
    private var currentFileName: String?
    /// Persists the selected playback rate so it's applied on every play/resume
    private(set) var playbackRate: Float = 1.0

    static let shared = AudioManager()

    override private init() {
        super.init()
    }

    // MARK: - File helpers

    static func narrationURL(fileName: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }

    static func narrationExists(fileName: String?) -> Bool {
        guard let name = fileName else { return false }
        return FileManager.default.fileExists(atPath: narrationURL(fileName: name).path)
    }

    // MARK: - Recording

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() -> String? {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
        } catch {
            return nil
        }

        let fileName = UUID().uuidString + ".m4a"
        let url = AudioManager.narrationURL(fileName: fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            DispatchQueue.main.async {
                self.isRecording = true
                self.recordingDuration = 0
            }
            durationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.recordingDuration = self?.audioRecorder?.currentTime ?? 0
                }
            }
            return fileName
        } catch {
            return nil
        }
    }

    func stopRecording() {
        durationTimer?.invalidate()
        durationTimer = nil
        audioRecorder?.stop()
        DispatchQueue.main.async {
            self.isRecording = false
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func deleteRecording(fileName: String) {
        let url = AudioManager.narrationURL(fileName: fileName)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Playback

    func play(fileName: String) {
        let url = AudioManager.narrationURL(fileName: fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            // If already playing this file, resume; otherwise create new player
            if currentFileName == fileName && audioPlayer != nil {
                audioPlayer?.enableRate = true
                audioPlayer?.rate = playbackRate
                audioPlayer?.play()
            } else {
                let player = try AVAudioPlayer(contentsOf: url)
                player.delegate = self
                player.enableRate = true
                player.rate = playbackRate
                player.play()
                audioPlayer = player
                currentFileName = fileName
                DispatchQueue.main.async {
                    self.duration = player.duration
                    self.currentTime = 0
                }
            }

            DispatchQueue.main.async {
                self.isPlaying = true
            }

            startPlaybackTimer()
        } catch {
            DispatchQueue.main.async {
                self.isPlaying = false
            }
        }
    }

    func pause() {
        audioPlayer?.pause()
        playbackTimer?.invalidate()
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }

    func resume() {
        audioPlayer?.enableRate = true
        audioPlayer?.rate = playbackRate
        audioPlayer?.play()
        startPlaybackTimer()
        DispatchQueue.main.async {
            self.isPlaying = true
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentFileName = nil
        playbackTimer?.invalidate()
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentTime = 0
        }
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        DispatchQueue.main.async {
            self.currentTime = time
        }
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        guard let player = audioPlayer else { return }
        player.enableRate = true
        player.rate = rate
    }

    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.currentTime = self?.audioPlayer?.currentTime ?? 0
            }
        }
    }

    func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

extension AudioManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}
