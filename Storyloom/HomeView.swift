import SwiftUI
import SwiftData

struct HomeView: View {
    @AppStorage("userName") private var userName = "John"
    @Query(sort: \StoryEntry.dateCreated, order: .reverse) private var stories: [StoryEntry]

    private var recentStories: [StoryEntry] { Array(stories.prefix(2)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Greeting
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Good morning, \(userName)")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text("Your story is growing beautifully")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }

                    // Progress bar
                    HStack(spacing: 12) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(SL.border)
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(SL.accent)
                                    .frame(width: geo.size.width * min(CGFloat(stories.count) / 10.0, 1.0), height: 8)
                                    .animation(.easeInOut, value: stories.count)
                            }
                        }
                        .frame(height: 8)

                        Text("\(stories.count) of 10 stories")
                            .font(SL.body(13))
                            .foregroundColor(SL.textSecondary)
                            .fixedSize()
                    }

                    // Today's question card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 14))
                                .foregroundColor(SL.accent)
                            Text("Today's question")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1)
                                .textCase(.uppercase)
                                .foregroundColor(SL.accent)
                        }

                        Text("What was your first job, and what did it teach you?")
                            .font(SL.serifMedium(20))
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Matched to your 1960s upbringing")
                            .font(SL.body(12))
                            .foregroundColor(SL.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SL.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Answer button
                    NavigationLink(destination: ChoosePromptView()) {
                        Text("Answer today's question")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(SL.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Divider
                    Rectangle()
                        .fill(SL.border)
                        .frame(height: 1)

                    // Recent stories
                    Text("Recent stories")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .textCase(.uppercase)
                        .foregroundColor(SL.textSecondary)

                    if recentStories.isEmpty {
                        Text("Your stories will appear here once you've recorded one.")
                            .font(SL.body(14))
                            .foregroundColor(SL.textSecondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(recentStories) { story in
                            RecentStoryCard(story: story)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(SL.background)
        }
    }
}

struct RecentStoryCard: View {
    let story: StoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(story.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SL.textPrimary)

            Text(story.preview)
                .font(SL.body(14))
                .foregroundColor(SL.textSecondary)
                .lineLimit(2)

            HStack {
                Text(story.dateFormatted)
                    .font(SL.body(13))
                    .foregroundColor(SL.textSecondary)
                Spacer()
                NavigationLink(destination: EditStoryView(story: story)) {
                    HStack(spacing: 5) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .medium))
                        Text("Edit")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "FDF9F0"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(SL.primary)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SL.border, lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
}
