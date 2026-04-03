import AVFoundation
import Combine
import SwiftUI

class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingDuration: TimeInterval = 0

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var durationTimer: Timer?

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
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            DispatchQueue.main.async {
                self.isPlaying = true
            }
        } catch {
            DispatchQueue.main.async {
                self.isPlaying = false
            }
        }
    }

    func stop() {
        audioPlayer?.stop()
        DispatchQueue.main.async {
            self.isPlaying = false
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
