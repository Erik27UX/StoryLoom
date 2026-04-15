import SwiftUI
import SwiftData

struct StoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var audio = AudioManager.shared
    @ObservedObject var authManager = AuthManager.shared
    let story: StoryEntry

    @Query private var allComments: [StoryComment]
    @Query private var allQuestions: [StoryQuestion]

    private var commentCount: Int { allComments.filter { $0.storyId == story.uuid }.count }
    private var questionCount: Int { allQuestions.filter { $0.storyId == story.uuid }.count }

    @State private var isEditingMode = false
    @State private var selectedPlaybackSpeed: Float = 1.0
    @State private var isLiked = false
    @State private var isImageExpanded = false

    var body: some View {
        if isEditingMode {
            EditStoryView(story: story, onDismiss: { isEditingMode = false })
        } else {
            viewMode
        }
    }

    @ViewBuilder
    private var viewMode: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Title + metadata
                    VStack(alignment: .leading, spacing: 8) {
                        Text(story.title)
                            .font(SL.heading(26))
                            .foregroundColor(SL.textPrimary)

                        HStack(spacing: 8) {
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
                            }

                            if story.isInVault {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(SL.accent)
                                    Text("Published")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(SL.textPrimary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(SL.accent.opacity(0.1))
                                .clipShape(Capsule())
                            } else {
                                Text("Private")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(SL.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(SL.surface)
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            // Likes — interactive for readers
                            if authManager.currentUser?.role == .reader {
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
                                            .font(.system(size: 18))
                                            .foregroundColor(isLiked ? Color(hex: "C17B6A") : SL.textSecondary)
                                        Text("\(story.likeCount)")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(isLiked ? Color(hex: "C17B6A") : SL.textSecondary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isLiked ? Color(hex: "C17B6A").opacity(0.1) : SL.surface)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(isLiked ? Color(hex: "C17B6A").opacity(0.3) : SL.border, lineWidth: 1))
                                }
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "C17B6A"))
                                    Text("\(story.likeCount)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(SL.textSecondary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(SL.surface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(SL.border, lineWidth: 1))
                            }
                        }
                    }

                    Rectangle()
                        .fill(SL.border)
                        .frame(height: 1)

                    // Image thumbnail + Comments & Questions side by side
                    HStack(alignment: .top, spacing: 12) {

                        // Tappable image thumbnail on the left
                        Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isImageExpanded = true } }) {
                            ZStack(alignment: .bottomTrailing) {
                                StoryImagePlaceholder(story: story)
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(5)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .padding(6)
                            }
                            .frame(width: 68)
                            .frame(maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        // Comments & Questions stacked on the right
                        VStack(spacing: 10) {
                            // Comments: always available
                            NavigationLink(destination: CommentsView(story: story)) {
                                HStack(spacing: 10) {
                                    Image(systemName: "bubble.left.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(SL.accent)
                                    Text("Comments")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(SL.textPrimary)
                                    Spacer()
                                    if commentCount > 0 {
                                        Text("\(commentCount)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(SL.textSecondary)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundColor(SL.textSecondary)
                                }
                                .padding(12)
                                .background(SL.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                            }

                            // Questions: only if storyteller has Story Legend tier
                            let questionsUnlocked = story.authorSubscriptionTier == .family
                            NavigationLink(destination: QuestionsView(story: story)) {
                                HStack(spacing: 10) {
                                    Image(systemName: questionsUnlocked ? "questionmark.circle.fill" : "lock.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(questionsUnlocked ? SL.accent : SL.textSecondary)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("Questions")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(questionsUnlocked ? SL.textPrimary : SL.textSecondary)
                                        if !questionsUnlocked {
                                            Text("Story Legend plan required")
                                                .font(SL.body(10))
                                                .foregroundColor(SL.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    if questionsUnlocked && questionCount > 0 {
                                        Text("\(questionCount)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(SL.textSecondary)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundColor(SL.textSecondary)
                                }
                                .padding(12)
                                .background(questionsUnlocked ? SL.surface : SL.surface.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                            }
                            .disabled(!questionsUnlocked)
                        }
                    }

                    // Narration player — show if story has a recording
                    if story.hasNarration, let fileName = story.narrationFileName {
                        VStack(spacing: 12) {
                            // Player controls
                            HStack(spacing: 14) {
                                Button(action: {
                                    if audio.isPlaying {
                                        audio.pause()
                                    } else {
                                        if audio.currentTime > 0 {
                                            audio.resume()
                                        } else {
                                            audio.play(fileName: fileName)
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
                            .padding(14)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(audio.isPlaying ? SL.accent.opacity(0.4) : SL.border, lineWidth: audio.isPlaying ? 1.5 : 1))

                            // Audio progress bar
                            VStack(spacing: 8) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(SL.border)
                                        let progress = audio.duration > 0 ? audio.currentTime / audio.duration : 0
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(SL.accent)
                                            .frame(width: geo.size.width * progress)
                                    }
                                    .gesture(DragGesture().onChanged { value in
                                        let percentage = min(max(value.location.x / geo.size.width, 0), 1)
                                        audio.seek(to: percentage * audio.duration)
                                    })
                                }
                                .frame(height: 6)

                                HStack {
                                    Text("Remaining")
                                        .font(SL.body(12))
                                        .foregroundColor(SL.textSecondary)
                                    Spacer()
                                    let remaining = max(0, audio.duration - audio.currentTime)
                                    Text(formatTime(remaining))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(SL.textSecondary)
                                }
                            }

                            // Playback speed (reader only)
                            if authManager.currentUser?.role == .reader {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Playback speed")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(SL.textSecondary)
                                    HStack(spacing: 8) {
                                        ForEach([0.75, 1.0, 1.25], id: \.self) { speed in
                                            Button(action: { selectedPlaybackSpeed = Float(speed) }) {
                                                Text("\(String(format: "%.2f", speed))x")
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
                                .padding(12)
                                .background(SL.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }

                    // Content
                    Text(story.content.isEmpty ? "No story content yet." : story.content)
                        .font(SL.serif(18))
                        .foregroundColor(SL.textPrimary)
                        .lineSpacing(8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(SL.background)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                isLiked = LikeManager.shared.isLiked(story.uuid)
            }
            .fullScreenCover(isPresented: $isImageExpanded) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 0) {
                        HStack {
                            Button(action: { isImageExpanded = false }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        Spacer()

                        StoryImagePlaceholder(story: story)
                            .aspectRatio(4/3, contentMode: .fit)
                            .padding(.horizontal, 24)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        Text(story.title)
                            .font(SL.heading(18))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                            .padding(.horizontal, 32)

                        Spacer()
                    }
                }
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
                if authManager.currentUser?.role == .storyteller {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { isEditingMode = true }) {
                            HStack(spacing: 5) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Edit")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(SL.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(SL.surface)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(SL.border, lineWidth: 1))
                        }
                    }
                }
            }
        }
    }

    private func formatYear(_ year: Int) -> String {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ""
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: year)) ?? "\(year)"
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StoryEntry.self, Folder.self, configurations: config)
    let sampleStory = StoryEntry(
        title: "Lost in Barcelona",
        content: "We wandered the Gothic Quarter for hours without a map, completely lost but completely happy. The narrow cobblestone streets twisted in impossible directions, and every corner revealed something new—a hidden chapel, a street musician, a café where locals gathered to watch the world go by. My friend laughed at our predicament, but I wouldn't have had it any other way. Sometimes the best memories come from being exactly where you don't mean to be.",
        category: "Adventure",
        year: 2003,
        folder: nil,
        hasNarration: true,
        publishNarration: true
    )
    container.mainContext.insert(sampleStory)

    return NavigationStack {
        StoryDetailView(story: sampleStory)
    }
    .modelContainer(container)
}
