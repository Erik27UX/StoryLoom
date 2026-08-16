import Foundation

/// Collects the running best transcription from `SFSpeechRecognizer` and
/// guarantees the continuation waiting on it is resumed exactly once.
///
/// Two problems this solves:
///
/// 1. **Truncated transcripts.** The recogniser can report an `isFinal` result
///    that covers only part of the audio. Keeping the longest transcription seen
///    so far means a short final callback can't discard everything that came
///    before it.
///
/// 2. **Double resume.** `recognitionTask`'s handler fires many times and can
///    deliver a result *and* an error. Resuming a `CheckedContinuation` twice
///    traps at runtime, so `finish()` hands back a value only on the first call.
///
/// The handler is invoked on an arbitrary queue, so all state is mutex-guarded.
final class TranscriptionAccumulator: @unchecked Sendable {
    private let lock = NSLock()
    private var best = ""
    private var hasFinished = false

    /// Records a transcription candidate, keeping it if it's the longest so far.
    func record(_ candidate: String) {
        lock.lock()
        defer { lock.unlock() }
        if candidate.count > best.count {
            best = candidate
        }
    }

    /// Returns the best transcription the first time it's called, and nil on
    /// every call after that, so callers can use it to gate a single resume.
    func finish() -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard !hasFinished else { return nil }
        hasFinished = true
        return best
    }
}
