import SwiftUI
import SwiftData

struct QuestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager = AuthManager.shared
    @Query private var questions: [StoryQuestion]
    @State private var showAskQuestion = false

    let story: StoryEntry

    var filteredQuestions: [StoryQuestion] {
        questions.filter { $0.storyId == story.uuid }.sorted { $0.dateCreated > $1.dateCreated }
    }

    var isQuestionsLocked: Bool {
        story.authorSubscriptionTier != .family
    }

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    if authManager.currentUser?.role == .storyteller && isQuestionsLocked {
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(SL.accent)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Questions not enabled")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(SL.textPrimary)
                                    Text("Upgrade to Story Legend plan to let readers ask you questions about your stories.")
                                        .font(SL.body(12))
                                        .foregroundColor(SL.textSecondary)
                                }
                            }
                            .padding(14)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    if filteredQuestions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 40))
                                .foregroundColor(SL.textSecondary)
                            Text("No questions yet")
                                .font(SL.heading(18))
                                .foregroundColor(SL.textPrimary)
                            Text("Ask the storyteller anything about their story")
                                .font(SL.body(14))
                                .foregroundColor(SL.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredQuestions) { question in
                                QuestionCard(question: question, isStorytellerView: authManager.currentUser?.role == .storyteller)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }

                Divider().background(SL.border)

                // Ask question button
                if authManager.currentUser?.role == .reader {
                    if isQuestionsLocked {
                        VStack(spacing: 8) {
                            Text("Questions only available for storytellers with Story Legend subscription")
                                .font(SL.body(12))
                                .foregroundColor(SL.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    } else {
                        Button(action: { showAskQuestion = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("Ask a question")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(SL.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .navigationTitle("Questions")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAskQuestion) {
            AskQuestionSheet(isPresented: $showAskQuestion, story: story, authManager: authManager)
        }
    }
}

struct QuestionCard: View {
    let question: StoryQuestion
    let isStorytellerView: Bool
    @State private var showAnswerSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(SL.surface)
                            .frame(width: 32, height: 32)
                        Text(String(question.userName.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SL.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(question.userName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(SL.textPrimary)
                        Text(formatDate(question.dateCreated))
                            .font(SL.body(11))
                            .foregroundColor(SL.textSecondary)
                    }

                    Spacer()

                    if question.isAudio {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(SL.accent)
                    }
                }

                if !question.isAudio {
                    Text(question.text)
                        .font(SL.body(13))
                        .foregroundColor(SL.textPrimary)
                        .lineSpacing(4)
                }
            }
            .padding(12)
            .background(SL.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Answer (if exists)
            if question.isAnswered, let answerText = question.answerText {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(SL.accent)
                        Text("Answered")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(SL.accent)
                        Spacer()
                    }

                    if !answerText.isEmpty {
                        Text(answerText)
                            .font(SL.body(13))
                            .foregroundColor(SL.textPrimary)
                            .lineSpacing(4)
                    }

                    if let _ = question.answerAudioFileName {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(SL.accent)
                            Text("Audio answer")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(SL.textSecondary)
                        }
                    }
                }
                .padding(12)
                .background(SL.accent.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.accent.opacity(0.2), lineWidth: 1))
            } else if isStorytellerView {
                Button(action: { showAnswerSheet = true }) {
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 14))
                        Text("Answer question")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(SL.accent)
                    .padding(10)
                    .background(SL.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .sheet(isPresented: $showAnswerSheet) {
                    AnswerQuestionSheet(isPresented: $showAnswerSheet, question: question)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct AskQuestionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    let story: StoryEntry
    @ObservedObject var authManager: AuthManager
    @ObservedObject private var audio = AudioManager.shared
    @State private var questionText = ""
    @State private var pendingAudioFileName: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Ask a question")
                    .font(SL.heading(22))
                    .foregroundColor(SL.textPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Type your question")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SL.textSecondary)
                    TextEditor(text: $questionText)
                        .font(SL.body(14))
                        .frame(height: 100)
                        .padding(12)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                }

                if audio.isRecording {
                    HStack(spacing: 12) {
                        Circle().fill(Color.red).frame(width: 10, height: 10)
                        Text(audio.formatDuration(audio.recordingDuration))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                            .monospacedDigit()
                        Spacer()
                        Button(action: { AudioManager.shared.stopRecording() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "stop.fill").font(.system(size: 12))
                                Text("Stop").font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(Color.red).clipShape(Capsule())
                        }
                    }
                    .padding(14)
                    .background(Color.red.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
                } else if pendingAudioFileName != nil {
                    HStack(spacing: 12) {
                        Button(action: {
                            guard let f = pendingAudioFileName else { return }
                            if audio.isPlaying { audio.stop() } else { audio.play(fileName: f) }
                        }) {
                            ZStack {
                                Circle().fill(SL.primary).frame(width: 36, height: 36)
                                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 13)).foregroundColor(SL.accent)
                            }
                        }
                        Text(audio.isPlaying ? "Playing..." : "Question recorded")
                            .font(.system(size: 14, weight: .medium)).foregroundColor(SL.textPrimary)
                        Spacer()
                        Button(action: {
                            audio.stop()
                            if let f = pendingAudioFileName { AudioManager.shared.deleteRecording(fileName: f) }
                            pendingAudioFileName = nil
                        }) {
                            Image(systemName: "trash").font(.system(size: 13))
                                .foregroundColor(Color.red.opacity(0.7))
                                .padding(8).background(Color.red.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.2), lineWidth: 1))
                        }
                    }
                    .padding(14).background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                } else {
                    Button(action: {
                        Task {
                            let granted = await AudioManager.shared.requestMicrophonePermission()
                            guard granted else { return }
                            await MainActor.run {
                                pendingAudioFileName = AudioManager.shared.startRecording()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform.circle.fill").font(.system(size: 16))
                            Text("Record audio question (optional)").font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(SL.accent).frame(maxWidth: .infinity).padding(12)
                        .background(SL.accent.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: { isPresented = false }) {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                    }

                    Button(action: { submitQuestion() }) {
                        Text("Ask")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(SL.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(questionText.isEmpty)
                }
            }
            .padding(20)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func submitQuestion() {
        let question = StoryQuestion(
            storyId: story.uuid,
            userName: authManager.currentUser?.name ?? "User",
            text: questionText,
            isAudio: pendingAudioFileName != nil,
            audioFileName: pendingAudioFileName
        )
        modelContext.insert(question)
        SyncManager.shared.pushQuestion(question)
        questionText = ""
        pendingAudioFileName = nil
        isPresented = false
    }
}

struct AnswerQuestionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    let question: StoryQuestion
    @ObservedObject private var audio = AudioManager.shared
    @State private var answerText = ""
    @State private var pendingAudioFileName: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Answer question")
                    .font(SL.heading(22))
                    .foregroundColor(SL.textPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Question from \(question.userName)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SL.textSecondary)
                    Text(question.text)
                        .font(SL.body(13))
                        .foregroundColor(SL.textPrimary)
                        .padding(12)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Type your answer")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SL.textSecondary)
                    TextEditor(text: $answerText)
                        .font(SL.body(14))
                        .frame(height: 120)
                        .padding(12)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                }

                if audio.isRecording {
                    HStack(spacing: 12) {
                        Circle().fill(Color.red).frame(width: 10, height: 10)
                        Text(audio.formatDuration(audio.recordingDuration))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                            .monospacedDigit()
                        Spacer()
                        Button(action: { AudioManager.shared.stopRecording() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "stop.fill").font(.system(size: 12))
                                Text("Stop").font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(Color.red).clipShape(Capsule())
                        }
                    }
                    .padding(14)
                    .background(Color.red.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
                } else if pendingAudioFileName != nil {
                    HStack(spacing: 12) {
                        Button(action: {
                            guard let f = pendingAudioFileName else { return }
                            if audio.isPlaying { audio.stop() } else { audio.play(fileName: f) }
                        }) {
                            ZStack {
                                Circle().fill(SL.primary).frame(width: 36, height: 36)
                                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 13)).foregroundColor(SL.accent)
                            }
                        }
                        Text(audio.isPlaying ? "Playing..." : "Answer recorded")
                            .font(.system(size: 14, weight: .medium)).foregroundColor(SL.textPrimary)
                        Spacer()
                        Button(action: {
                            audio.stop()
                            if let f = pendingAudioFileName { AudioManager.shared.deleteRecording(fileName: f) }
                            pendingAudioFileName = nil
                        }) {
                            Image(systemName: "trash").font(.system(size: 13))
                                .foregroundColor(Color.red.opacity(0.7))
                                .padding(8).background(Color.red.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.2), lineWidth: 1))
                        }
                    }
                    .padding(14).background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                } else {
                    Button(action: {
                        Task {
                            let granted = await AudioManager.shared.requestMicrophonePermission()
                            guard granted else { return }
                            await MainActor.run {
                                pendingAudioFileName = AudioManager.shared.startRecording()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform.circle.fill").font(.system(size: 16))
                            Text("Record audio answer (optional)").font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(SL.accent).frame(maxWidth: .infinity).padding(12)
                        .background(SL.accent.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: { isPresented = false }) {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                    }

                    Button(action: { submitAnswer() }) {
                        Text("Post answer")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(SL.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(answerText.isEmpty)
                }
            }
            .padding(20)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func submitAnswer() {
        question.answerText = answerText
        question.isAnswered = true
        question.answeredDate = Date()
        if let audioFile = pendingAudioFileName {
            question.answerAudioFileName = audioFile
        }
        pendingAudioFileName = nil
        SyncManager.shared.pushQuestion(question)
        isPresented = false
    }
}

#Preview {
    QuestionsView(story: StoryEntry(title: "Test", content: "Test content"))
}
