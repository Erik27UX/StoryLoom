import SwiftUI
import SwiftData

struct HomeView: View {
    @AppStorage("userName") private var userName = "John"
    @AppStorage("subscriptionTier") private var subscriptionTier = SubscriptionTier.free.rawValue
    @Query(sort: \StoryEntry.dateCreated, order: .reverse) private var stories: [StoryEntry]

    private var recentStories: [StoryEntry] { Array(stories.prefix(2)) }
    private var isPremium: Bool { subscriptionTier == SubscriptionTier.premium.rawValue }
    private var dailyLimit: Int { isPremium ? 30 : 3 }

    private var todayStories: Int {
        let start = Calendar.current.startOfDay(for: Date())
        return stories.filter { $0.dateCreated >= start }.count
    }
    private var remainingToday: Int { max(0, dailyLimit - todayStories) }
    private var resetHours: Int {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: Date()))!
        return max(1, Calendar.current.dateComponents([.hour], from: Date(), to: tomorrow).hour ?? 1)
    }

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

                    // Daily limit card
                    VStack(spacing: 12) {
                        // Progress bar row
                        HStack(spacing: 12) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(SL.border)
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(remainingToday == 0 ? Color(hex: "E63946").opacity(0.7) : SL.accent)
                                        .frame(width: geo.size.width * min(CGFloat(todayStories) / CGFloat(dailyLimit), 1.0), height: 8)
                                        .animation(.easeInOut, value: todayStories)
                                }
                            }
                            .frame(height: 8)

                            Text("\(remainingToday) left today")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(remainingToday == 0 ? Color(hex: "E63946") : SL.textSecondary)
                                .fixedSize()
                        }

                        // Reset info + upgrade
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                Text("Resets in \(resetHours)h")
                                    .font(SL.body(14))
                            }
                            .foregroundColor(SL.textSecondary)

                            Spacer()

                            if !isPremium {
                                NavigationLink(destination: AccountView()) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 11))
                                        Text(remainingToday == 0 ? "Upgrade to keep writing" : "Unlock more stories")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(Color(hex: "FDF9F0"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                                    .background(SL.primary)
                                    .clipShape(Capsule())
                                }
                            }
                        }
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
                    NavigationLink(destination: AnswerView(prompt: SampleData.prompts.first)) {
                        Text("Answer today's question")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(SL.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Secondary button
                    NavigationLink(destination: ChoosePromptView()) {
                        Text("Choose different question")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(SL.border, lineWidth: 1.5)
                            )
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
        NavigationLink(destination: StoryDetailView(story: story)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(story.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SL.textPrimary)
                    Spacer()
                    if story.isInVault {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("Published")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(SL.accent)
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
                            .background(SL.border.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }

                Text(story.preview)
                    .font(SL.body(14))
                    .foregroundColor(SL.textSecondary)
                    .lineLimit(2)

                HStack {
                    Text(story.dateFormatted)
                        .font(SL.body(13))
                        .foregroundColor(SL.textSecondary)
                    Spacer()
                    if story.likeCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "C17B6A"))
                            Text("\(story.likeCount)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(SL.textSecondary)
                        }
                    }
                }
            }
            .padding(18)
            .background(SL.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(SL.border, lineWidth: 1)
            )
        }
    }
}

#Preview {
    HomeView()
}
