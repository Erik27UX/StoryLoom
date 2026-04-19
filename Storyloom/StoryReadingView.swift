import SwiftUI
import SwiftData

// MARK: - StoryReadingView
// Reader-only view for reading a story. Shows content, narration player,
// comments section, and questions section (Story Legend tier only).
// No edit, delete, or vault controls.

struct StoryReadingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var audio = AudioManager.shared
    @ObservedObject private var authManager = AuthManager.shared

    let story: StoryEntry

    @Query private var allComments: [StoryComment]
    @Query private var allQuestions: [StoryQuestion]

    @AppStorage("setting.commentsEnabled") private var commentsEnabled = true
    @AppStorage("setting.reactionsEnabled") private var reactionsEnabled = true
    @AppStorage("setting.questionsEnabled") private var questionsEnabled = true

    private var storyComments: [StoryComment] {
        allComments.filter { $0.storyId == story.uuid }
            .sorted { $0.dateCreated < $1.dateCreated }
    }
    private var storyQuestions: [StoryQuestion] {
        allQuestions.filter { $0.storyId == story.uuid }
            .sorted { $0.dateCreated < $1.dateCreated }
    }

    @State private var selectedPlaybackSpeed: Float = 1.0
    @State private var newCommentText = ""
    @State private var isSubmittingComment = false
    @State private var newQuestionText = ""
    @State private var isSubmittingQuestion = false
    @State private var isLiked = false
    @State private var showShareSheet = false

    private var questionsUnlocked: Bool {
        story.authorSubscriptionTier == .family && questionsEnabled
    }

    private var currentUserName: String {
        authManager.currentUser?.name ?? "Reader"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Title + metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text(story.title)
                        .font(SL.heading(26))
                        .foregroundColor(SL.textPrimary)

                    HStack(spacing: 8) {
                        Text(story.dateFormatted)
                            .font(SL.body(13))
                            .foregroundColor(SL.textSecondary)
                        if let year = story.year {
                            Text("·")
                                .foregroundColor(SL.textSecondary)
                            Text(formatYear(year))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(SL.accent)
                        }
                        if let author = story.authorName {
                            Text("·")
                                .foregroundColor(SL.textSecondary)
                            Text("by \(author)")
                                .font(SL.body(13))
                                .foregroundColor(SL.textSecondary)
                        }
                    }
                }

                // Narration player
                if story.publishNarration, let fileName = story.narrationFileName {
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            Button(action: {
                                if audio.isPlaying {
                                    audio.pause()
                                } else {
                                    if audio.currentTime > 0 {
                                        audio.resume()
                                    } else {
                                        audio.play(fileName: fileName)
                                        audio.setPlaybackRate(selectedPlaybackSpeed)
                                    }
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(SL.primary)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 15))
                                        .foregroundColor(SL.accent)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(audio.isPlaying ? "Playing narration…" : "Listen to narration")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SL.textPrimary)

                                HStack(spacing: 3) {
                                    ForEach([0.5, 0.8, 1.0, 0.6, 0.9, 0.4, 0.7, 0.5, 1.0, 0.6], id: \.self) { h in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(audio.isPlaying ? SL.accent : SL.border)
                                            .frame(width: 3, height: 20 * h)
                                    }
                                }
                                .frame(height: 20)
                            }

                            Spacer()

                            Image(systemName: audio.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                                .font(.system(size: 16))
                                .foregroundColor(audio.isPlaying ? SL.accent : SL.textSecondary)
                                .padding(8)
                                .background(SL.surface)
                                .clipShape(Circle())
                        }

                        // Progress scrubber
                        VStack(spacing: 6) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(SL.border)
                                    let progress = audio.duration > 0 ? audio.currentTime / audio.duration : 0
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(SL.accent)
                                        .frame(width: geo.size.width * CGFloat(progress))
                                }
                                .gesture(DragGesture().onChanged { value in
                                    let pct = min(max(value.location.x / geo.size.width, 0), 1)
                                    audio.seek(to: Double(pct) * audio.duration)
                                })
                            }
                            .frame(height: 6)

                            HStack {
                                Text(formatTime(audio.currentTime))
                                    .font(SL.body(11))
                                    .foregroundColor(SL.textSecondary)
                                    .monospacedDigit()
                                Spacer()
                                Text("-\(formatTime(max(0, audio.duration - audio.currentTime)))")
                                    .font(SL.body(11))
                                    .foregroundColor(SL.textSecondary)
                                    .monospacedDigit()
                            }
                        }

                        // Playback speed controls
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Speed")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(SL.textSecondary)
                                .tracking(0.5)
                            HStack(spacing: 8) {
                                ForEach([0.5, 1.0, 1.5, 2.0] as [Double], id: \.self) { speed in
                                    Button(action: {
                                        selectedPlaybackSpeed = Float(speed)
                                        audio.setPlaybackRate(Float(speed))
                                    }) {
                                        Text(speedLabel(speed))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(selectedPlaybackSpeed == Float(speed) ? Color(hex: "FDF9F0") : SL.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 6)
                                            .background(selectedPlaybackSpeed == Float(speed) ? SL.accent : SL.background)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(audio.isPlaying ? SL.accent.opacity(0.4) : SL.border, lineWidth: audio.isPlaying ? 1.5 : 1))
                }

                // Likes row (if reactions enabled)
                if reactionsEnabled {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isLiked.toggle()
                            if isLiked {
                                story.likeCount += 1
                                LikeManager.shared.like(story.uuid)
                                SyncManager.shared.pushLike(storyUUID: story.uuid)
                            } else {
                                story.likeCount = max(0, story.likeCount - 1)
                                LikeManager.shared.unlike(story.uuid)
                                SyncManager.shared.removeLike(storyUUID: story.uuid)
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 16))
                                .foregroundColor(isLiked ? Color(hex: "C17B6A") : SL.textSecondary)
                            Text(isLiked ? "Loved this" : "Love this story")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isLiked ? Color(hex: "C17B6A") : SL.textSecondary)
                            if story.likeCount > 0 {
                                Text("· \(story.likeCount)")
                                    .font(.system(size: 14))
                                    .foregroundColor(SL.textSecondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isLiked ? Color(hex: "C17B6A").opacity(0.1) : SL.surface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isLiked ? Color(hex: "C17B6A").opacity(0.3) : SL.border, lineWidth: 1))
                    }
                }

                Rectangle()
                    .fill(SL.border)
                    .frame(height: 1)

                // Story content (serif font)
                Text(story.content.isEmpty ? "No story content yet." : story.content)
                    .font(SL.serif(18))
                    .foregroundColor(SL.textPrimary)
                    .lineSpacing(8)

                Rectangle()
                    .fill(SL.border)
                    .frame(height: 1)

                // Comments section
                if commentsEnabled {
                    commentsSection
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 14))
                            .foregroundColor(SL.textSecondary)
                        Text("Comments are disabled for this story")
                            .font(SL.body(14))
                            .foregroundColor(SL.textSecondary)
                    }
                    .padding(12)
                    .background(SL.surface.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Questions section — only for Story Legend tier
                if story.authorSubscriptionTier == .family {
                    Rectangle()
                        .fill(SL.border)
                        .frame(height: 1)
                    if questionsEnabled {
                        questionsSection
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 14))
                                .foregroundColor(SL.textSecondary)
                            Text("Questions are disabled for this story")
                                .font(SL.body(14))
                                .foregroundColor(SL.textSecondary)
                        }
                        .padding(12)
                        .background(SL.surface.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(SL.background)
        .navigationBarBackButtonHidden(true)
        .onAppear { isLiked = LikeManager.shared.isLiked(story.uuid) }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("storyloom.newActivity"))) { _ in
            // SwiftData will auto-refresh via @Query; no manual fetch needed
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                    }
                    .foregroundColor(SL.accent)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: story.content, subject: Text(story.title)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17))
                        .foregroundColor(SL.accent)
                }
            }
        }
    }

    // MARK: - Comments Section

    @ViewBuilder
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Comments")
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundColor(SL.textSecondary)

            if storyComments.isEmpty {
                Text("No comments yet. Be the first!")
                    .font(SL.body(14))
                    .foregroundColor(SL.textSecondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 12) {
                    ForEach(storyComments) { comment in
                        CommentBubble(comment: comment)
                    }
                }
            }

            // New comment input
            VStack(spacing: 8) {
                TextField("", text: $newCommentText,
                          prompt: Text("Leave a comment...").foregroundColor(SL.textSecondary),
                          axis: .vertical)
                    .font(SL.body(15))
                    .foregroundColor(SL.textPrimary)
                    .padding(12)
                    .background(SL.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
                    .lineLimit(1...4)

                if !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: { submitComment() }) {
                        HStack(spacing: 6) {
                            if isSubmittingComment {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                            Text("Post Comment")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(isSubmittingComment ? SL.primary.opacity(0.6) : SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isSubmittingComment)
                }
            }
        }
    }

    // MARK: - Questions Section

    @ViewBuilder
    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(SL.accent)
                Text("Ask a Question")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.5)
                    .textCase(.uppercase)
                    .foregroundColor(SL.textSecondary)
            }

            Text("Ask the storyteller something about this memory. They can answer when they're ready.")
                .font(SL.body(13))
                .foregroundColor(SL.textSecondary)
                .lineSpacing(3)

            // Answered questions
            let answered = storyQuestions.filter { $0.isAnswered }
            if !answered.isEmpty {
                VStack(spacing: 12) {
                    ForEach(answered) { question in
                        AnsweredQuestionCard(question: question)
                    }
                }
            }

            // Unanswered questions from this user
            let myUnanswered = storyQuestions.filter { !$0.isAnswered && $0.userName == currentUserName }
            if !myUnanswered.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your pending questions")
                        .font(SL.body(12))
                        .foregroundColor(SL.textSecondary)
                    ForEach(myUnanswered) { question in
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(SL.textSecondary)
                            Text(question.text)
                                .font(SL.body(13))
                                .foregroundColor(SL.textSecondary)
                                .italic()
                        }
                        .padding(10)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Submit a new question
            VStack(spacing: 8) {
                TextField("", text: $newQuestionText,
                          prompt: Text("Ask the storyteller something...").foregroundColor(SL.textSecondary),
                          axis: .vertical)
                    .font(SL.body(15))
                    .foregroundColor(SL.textPrimary)
                    .padding(12)
                    .background(SL.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
                    .lineLimit(1...4)

                if !newQuestionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: { submitQuestion() }) {
                        HStack(spacing: 6) {
                            if isSubmittingQuestion {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                            Text("Submit Question")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(isSubmittingQuestion ? SL.primary.opacity(0.6) : SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isSubmittingQuestion)
                }
            }
        }
    }

    // MARK: - Actions

    private func submitComment() {
        let trimmed = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSubmittingComment = true

        let comment = StoryComment(
            storyId: story.uuid,
            userName: currentUserName,
            text: trimmed
        )
        if let uid = authManager.supabaseUserId {
            comment.userId = uid
        }
        modelContext.insert(comment)
        SyncManager.shared.pushComment(comment)

        newCommentText = ""
        isSubmittingComment = false
    }

    private func submitQuestion() {
        let trimmed = newQuestionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSubmittingQuestion = true

        let question = StoryQuestion(
            storyId: story.uuid,
            userName: currentUserName,
            text: trimmed
        )
        if let uid = authManager.supabaseUserId {
            question.userId = uid
        }
        modelContext.insert(question)
        SyncManager.shared.pushQuestion(question)

        newQuestionText = ""
        isSubmittingQuestion = false
    }

    // MARK: - Helpers

    private func formatYear(_ year: Int) -> String {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ""
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: year)) ?? "\(year)"
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func speedLabel(_ speed: Double) -> String {
        switch speed {
        case 0.5: return "0.5x"
        case 1.0: return "1x"
        case 1.5: return "1.5x"
        case 2.0: return "2x"
        default:  return "\(speed)x"
        }
    }
}

// MARK: - CommentBubble

struct CommentBubble: View {
    let comment: StoryComment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(comment.userName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(SL.textPrimary)
                Spacer()
                Text(comment.dateCreated.formatted(date: .abbreviated, time: .omitted))
                    .font(SL.body(11))
                    .foregroundColor(SL.textSecondary)
            }
            Text(comment.text)
                .font(SL.body(14))
                .foregroundColor(SL.textPrimary)
        }
        .padding(12)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
    }
}

// MARK: - AnsweredQuestionCard

struct AnsweredQuestionCard: View {
    let question: StoryQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(SL.accent)
                Text(question.userName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(SL.textSecondary)
                Spacer()
                Text(question.dateCreated.formatted(date: .abbreviated, time: .omitted))
                    .font(SL.body(11))
                    .foregroundColor(SL.textSecondary)
            }
            Text(question.text)
                .font(SL.body(14))
                .foregroundColor(SL.textPrimary)
                .italic()

            if let answer = question.answerText {
                Divider()
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrowshape.turn.up.right.fill")
                        .font(.system(size: 11))
                        .foregroundColor(SL.accent)
                        .padding(.top, 2)
                    Text(answer)
                        .font(SL.body(14))
                        .foregroundColor(SL.textPrimary)
                }
            }
        }
        .padding(12)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.accent.opacity(0.2), lineWidth: 1))
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StoryEntry.self, Folder.self, StoryComment.self, StoryQuestion.self, configurations: config)
    let story = StoryEntry(
        title: "The Summer I Turned Sixteen",
        content: "My first job was at a bakery on Elm Street, the summer I turned sixteen. Mr. Hawthorn had hands like worn leather and a laugh you could hear from the street.",
        category: "Work",
        year: 1972,
        authorSubscriptionTier: .family,
        authorName: "Margaret"
    )
    container.mainContext.insert(story)
    return NavigationStack {
        StoryReadingView(story: story)
    }
    .modelContainer(container)
}
