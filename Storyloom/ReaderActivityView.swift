import SwiftUI
import SwiftData

struct ReaderActivityView: View {

    // Only vault stories are relevant — predicated query avoids loading drafts.
    @Query(filter: #Predicate<StoryEntry> { $0.isInVault },
           sort: \StoryEntry.dateCreated, order: .reverse)
    private var vaultStories: [StoryEntry]

    @Query(sort: \StoryQuestion.dateCreated, order: .reverse)
    private var allQuestions: [StoryQuestion]

    /// Unix timestamp of the last time this screen was viewed.
    /// Any content created after this date is considered "new."
    @AppStorage("reader.lastActivityViewDate") private var lastViewTimestamp: Double = 0

    private var lastViewDate: Date {
        lastViewTimestamp == 0 ? .distantPast : Date(timeIntervalSince1970: lastViewTimestamp)
    }

    private var newStories: [StoryEntry] {
        vaultStories.filter { $0.dateCreated > lastViewDate }
    }

    /// Questions asked by this reader that were answered since last visit.
    /// Matches by userId (UUID) — not by display name — to avoid false positives
    /// when two readers share a name.
    private var answeredQuestions: [StoryQuestion] {
        guard let currentUserId = AuthManager.shared.supabaseUserId else { return [] }
        return allQuestions
            .filter {
                $0.isAnswered &&
                $0.userId == currentUserId &&
                ($0.answeredDate ?? .distantPast) > lastViewDate
            }
            .sorted { ($0.answeredDate ?? .distantPast) > ($1.answeredDate ?? .distantPast) }
    }

    /// Lookup table for resolving story titles in answered question rows.
    private var storyById: [UUID: StoryEntry] {
        Dictionary(uniqueKeysWithValues: vaultStories.map { ($0.uuid, $0) })
    }

    private var hasActivity: Bool { !newStories.isEmpty || !answeredQuestions.isEmpty }

    var body: some View {
        ScrollView {
            if !hasActivity {
                emptyState
            } else {
                activityFeed
            }
        }
        .background(SL.background)
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(SL.background, for: .navigationBar)
        .onAppear {
            // Delay the timestamp update slightly so the current batch of activity
            // is still visible during this visit; it marks as seen on the next open.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                lastViewTimestamp = Date().timeIntervalSince1970
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .fill(SL.surface)
                    .frame(width: 80, height: 80)
                Image(systemName: "bell")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(SL.accent.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text("All caught up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(SL.textPrimary)
                Text("New stories and answered questions will appear here.")
                    .font(SL.body(14))
                    .foregroundColor(SL.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Activity Feed

    private var activityFeed: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !newStories.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("New Stories", count: newStories.count)
                    ForEach(newStories) { story in
                        storyRow(story)
                    }
                }
            }

            if !answeredQuestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Questions Answered", count: answeredQuestions.count)
                    ForEach(answeredQuestions) { question in
                        answeredQuestionRow(question)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 40)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundColor(SL.textSecondary)
            Spacer()
            Text("\(count) new")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(SL.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(SL.accent.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    // MARK: - Story Row

    private func storyRow(_ story: StoryEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(SL.accent.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "book.fill")
                    .font(.system(size: 15))
                    .foregroundColor(SL.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(story.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(SL.textPrimary)
                    .lineLimit(2)
                if let author = story.authorName {
                    Text("by \(author)")
                        .font(SL.body(13))
                        .foregroundColor(SL.textSecondary)
                }
                Text(story.dateCreated.formatted(date: .abbreviated, time: .omitted))
                    .font(SL.body(12))
                    .foregroundColor(SL.textMuted)
            }

            Spacer()
        }
        .padding(14)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
    }

    // MARK: - Answered Question Row

    private func answeredQuestionRow(_ question: StoryQuestion) -> some View {
        let storyTitle = storyById[question.storyId]?.title ?? "a story"
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.bubble.fill")
                    .font(.system(size: 13))
                    .foregroundColor(SL.accent)
                Text("Your question was answered")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SL.textPrimary)
            }

            Text("\u{201C}\(question.text)\u{201D}")
                .font(SL.body(13))
                .foregroundColor(SL.textSecondary)
                .italic()
                .lineLimit(2)

            if let answer = question.answerText, !answer.isEmpty {
                Text(answer)
                    .font(SL.body(13))
                    .foregroundColor(SL.textPrimary)
                    .lineLimit(3)
            }

            Text("In \u{201C}\(storyTitle)\u{201D}")
                .font(SL.body(11))
                .foregroundColor(SL.textMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.accent.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        ReaderActivityView()
    }
}
