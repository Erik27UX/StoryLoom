import SwiftUI
import Speech

struct AnswerView: View {
    @Environment(\.dismiss) private var dismiss
    let prompt: StoryPrompt?
    @ObservedObject private var audio = AudioManager.shared
    @State private var answerText = ""
    @State private var pendingNarrationFileName: String? = nil
    @State private var transcriptionState: TranscriptionState = .idle
    @State private var transcribedText: String = ""

    enum TranscriptionState {
        case idle           // No recording done yet, or transcription not requested
        case available      // Recording done, transcription offered
        case transcribing   // Actively transcribing
        case done           // Transcription succeeded (text shown, user can use or ignore)
        case failed         // Transcription failed
    }

    private var generatedStory: String { answerText }

    private var canProceed: Bool {
        !answerText.trimmingCharacters(in: .whitespaces).isEmpty || pendingNarrationFileName != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Prompt card
                    if let prompt {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(SL.accent)
                                Text("Your prompt")
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(1)
                                    .textCase(.uppercase)
                                    .foregroundColor(SL.accent)
                            }
                            Text(prompt.question)
                                .font(SL.serifMedium(18))
                                .foregroundColor(Color(hex: "FDF9F0"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Text editor
                    ZStack(alignment: .topLeading) {
                        if answerText.isEmpty {
                            Text("Type your answer here, or tap the microphone to speak...")
                                .font(SL.body(16))
                                .foregroundColor(SL.textSecondary)
                                .italic()
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                        }
                        TextEditor(text: $answerText)
                            .font(SL.body(16))
                            .foregroundColor(SL.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .frame(minHeight: 100)
                    }
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SL.border, lineWidth: 1)
                    )

                    // Voice section
                    VStack(spacing: 12) {
                        Text("or speak your answer")
                            .font(SL.body(13))
                            .foregroundColor(SL.textSecondary)

                        if audio.isRecording {
                            // Recording in progress
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                Text(audio.formatDuration(audio.recordingDuration))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(SL.textPrimary)
                                    .monospacedDigit()
                                Spacer()
                                Button(action: stopRecording) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "stop.fill")
                                            .font(.system(size: 12))
                                        Text("Stop")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(14)
                            .background(Color.red.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))

                        } else if pendingNarrationFileName != nil {
                            // Has a recording
                            VStack(spacing: 10) {
                                HStack(spacing: 12) {
                                    Button(action: togglePlayback) {
                                        ZStack {
                                            Circle()
                                                .fill(SL.primary)
                                                .frame(width: 40, height: 40)
                                            Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(SL.accent)
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(audio.isPlaying ? "Playing..." : "Your recording")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(SL.textPrimary)
                                        HStack(spacing: 3) {
                                            ForEach([0.4, 0.7, 1.0, 0.6, 0.9, 0.5, 0.8, 0.3], id: \.self) { h in
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(audio.isPlaying ? SL.accent : SL.border)
                                                    .frame(width: 3, height: 18 * h)
                                            }
                                        }
                                        .frame(height: 18)
                                    }
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Button(action: deleteRecording) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 13))
                                                .foregroundColor(Color.red.opacity(0.7))
                                                .padding(8)
                                                .background(Color.red.opacity(0.07))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.2), lineWidth: 1))
                                        }
                                        Button(action: startRecording) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "arrow.clockwise")
                                                    .font(.system(size: 12))
                                                Text("Re-record")
                                                    .font(.system(size: 13, weight: .medium))
                                            }
                                            .foregroundColor(SL.textSecondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 7)
                                            .background(SL.background)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(SL.border, lineWidth: 1))
                                        }
                                    }
                                }
                                .padding(14)
                                .background(SL.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))

                                // Speech-to-text offer
                                transcriptionSection
                            }

                        } else {
                            // No recording yet
                            Button(action: startRecording) {
                                ZStack {
                                    Circle()
                                        .fill(SL.primary)
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(SL.accent)
                                }
                            }
                            Text("Tap to record")
                                .font(SL.body(13))
                                .foregroundColor(SL.accent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            // Bottom button — passes prompt + generated story forward
            VStack {
                NavigationLink(destination: StoryReadyView(
                    prompt: prompt,
                    storyText: generatedStory,
                    narrationFileName: pendingNarrationFileName
                )) {
                    Text("Turn into a story")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canProceed ? SL.primary : SL.primary.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canProceed)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .padding(.top, 12)
            .background(
                SL.background
                    .shadow(color: .black.opacity(0.06), radius: 8, y: -4)
            )
        }
        .background(SL.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    audio.stop()
                    if let pending = pendingNarrationFileName {
                        AudioManager.shared.deleteRecording(fileName: pending)
                    }
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                    }
                    .foregroundColor(SL.accent)
                }
            }
        }
    }
    private func startRecording() {
        audio.stop()
        if let pending = pendingNarrationFileName {
            AudioManager.shared.deleteRecording(fileName: pending)
            pendingNarrationFileName = nil
        }
        Task {
            let granted = await AudioManager.shared.requestMicrophonePermission()
            guard granted else { return }
            await MainActor.run {
                pendingNarrationFileName = AudioManager.shared.startRecording()
            }
        }
    }

    private func stopRecording() {
        AudioManager.shared.stopRecording()
    }

    private func togglePlayback() {
        guard let fileName = pendingNarrationFileName else { return }
        if audio.isPlaying { audio.stop() } else { audio.play(fileName: fileName) }
    }

    private func deleteRecording() {
        audio.stop()
        if let pending = pendingNarrationFileName {
            AudioManager.shared.deleteRecording(fileName: pending)
            pendingNarrationFileName = nil
        }
        transcriptionState = .idle
        transcribedText = ""
    }

    // MARK: - Speech-to-Text

    @ViewBuilder
    private var transcriptionSection: some View {
        switch transcriptionState {
        case .idle, .available:
            // Offer to transcribe
            Button(action: transcribeRecording) {
                HStack(spacing: 8) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 14))
                    Text("Transcribe to text (optional)")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(SL.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(SL.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.accent.opacity(0.3), lineWidth: 1))
            }

        case .transcribing:
            HStack(spacing: 10) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: SL.accent))
                    .scaleEffect(0.85)
                Text("Transcribing your recording…")
                    .font(SL.body(14))
                    .foregroundColor(SL.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(SL.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))

        case .done:
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 12))
                        .foregroundColor(SL.accent)
                    Text("Transcription ready")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.4)
                        .textCase(.uppercase)
                        .foregroundColor(SL.accent)
                }

                Text(transcribedText)
                    .font(SL.body(14))
                    .foregroundColor(SL.textPrimary)
                    .lineSpacing(4)

                HStack(spacing: 8) {
                    Button(action: {
                        // Use transcription as the answer text
                        answerText = transcribedText
                        transcriptionState = .idle
                    }) {
                        Text("Use this text")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(SL.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Button(action: {
                        // Dismiss transcription, keep writing manually
                        transcriptionState = .idle
                        transcribedText = ""
                    }) {
                        Text("Ignore")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SL.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
                    }
                }
            }
            .padding(14)
            .background(SL.accent.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.accent.opacity(0.25), lineWidth: 1))

        case .failed:
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 14))
                    .foregroundColor(SL.textSecondary)
                Text("Transcription unavailable — type your answer below.")
                    .font(SL.body(13))
                    .foregroundColor(SL.textSecondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SL.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func transcribeRecording() {
        guard let fileName = pendingNarrationFileName else { return }
        let url = AudioManager.narrationURL(fileName: fileName)

        transcriptionState = .transcribing

        Task {
            // Check speech recognition permission
            let authStatus = SFSpeechRecognizer.authorizationStatus()
            if authStatus == .notDetermined {
                let granted = await withCheckedContinuation { cont in
                    SFSpeechRecognizer.requestAuthorization { status in
                        cont.resume(returning: status == .authorized)
                    }
                }
                guard granted else {
                    await MainActor.run { transcriptionState = .failed }
                    return
                }
            } else if authStatus != .authorized {
                await MainActor.run { transcriptionState = .failed }
                return
            }

            guard let recognizer = SFSpeechRecognizer(locale: Locale.current),
                  recognizer.isAvailable else {
                await MainActor.run { transcriptionState = .failed }
                return
            }

            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false

            do {
                let result = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<SFSpeechRecognitionResult, Error>) in
                    recognizer.recognitionTask(with: request) { result, error in
                        if let result = result, result.isFinal {
                            cont.resume(returning: result)
                        } else if let error = error {
                            cont.resume(throwing: error)
                        }
                    }
                }
                let text = result.bestTranscription.formattedString
                await MainActor.run {
                    if text.trimmingCharacters(in: .whitespaces).isEmpty {
                        transcriptionState = .failed
                    } else {
                        transcribedText = text
                        transcriptionState = .done
                    }
                }
            } catch {
                await MainActor.run { transcriptionState = .failed }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnswerView(prompt: SampleData.prompts.first)
    }
}
