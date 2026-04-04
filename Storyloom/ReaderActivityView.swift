import SwiftUI
import SwiftData

struct ReaderActivityView: View {
    @Query private var allStories: [StoryEntry]

    func story(titled title: String) -> StoryEntry? {
        allStories.first { $0.title == title }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Updates from your storytellers")
                        .font(SL.body(15))
                        .foregroundColor(SL.textSecondary)
                }
                .padding(.top, 4)

                // FOR YOU section
                VStack(alignment: .leading, spacing: 12) {
                    Label("FOR YOU", systemImage: "person.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(SL.accent)
                        .tracking(1)

                    ActivityItemCard(
                        icon: "checkmark.bubble.fill",
                        iconColor: Color(hex: "7A9E87"),
                        title: "Your question was answered",
                        subtitle: "\"The summer I turned sixteen\"",
                        detail: "Margaret replied to your question about the bakery job.",
                        timeAgo: "1 day ago",
                        actionLabel: "Read answer",
                        destination: story(titled: "The summer I turned sixteen")
                    )

                    ActivityItemCard(
                        icon: "book.fill",
                        iconColor: SL.accent,
                        title: "New story published",
                        subtitle: "\"The wisdom I wish I'd known\"",
                        detail: "A new memory was shared just for you.",
                        timeAgo: "3 days ago",
                        actionLabel: "Read now",
                        destination: story(titled: "The wisdom I wish I'd known")
                    )
                }

                Divider().background(SL.border)

                // STORY UPDATES section
                VStack(alignment: .leading, spacing: 12) {
                    Label("STORY UPDATES", systemImage: "bell.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(SL.textSecondary)
                        .tracking(1)

                    ActivityItemCard(
                        icon: "bubble.left.and.bubble.right.fill",
                        iconColor: SL.accent.opacity(0.7),
                        title: "Another question was answered",
                        subtitle: "\"Letters from your mother\"",
                        detail: "Marcus T. asked about life lessons — and got a beautiful reply.",
                        timeAgo: "2 days ago",
                        actionLabel: "See answer",
                        destination: story(titled: "Letters from your mother")
                    )

                    ActivityItemCard(
                        icon: "bubble.left.fill",
                        iconColor: SL.textSecondary,
                        title: "New comment on a story",
                        subtitle: "\"The tree house\"",
                        detail: "Elena R. left a comment on this memory.",
                        timeAgo: "4 days ago",
                        actionLabel: nil,
                        destination: nil
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 32)
        }
        .background(SL.background)
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(SL.background, for: .navigationBar)
    }
}

struct ActivityItemCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let detail: String
    let timeAgo: String
    var actionLabel: String?
    var destination: StoryEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SL.textPrimary)
                        Spacer()
                        Text(timeAgo)
                            .font(SL.body(11))
                            .foregroundColor(SL.textSecondary)
                    }
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(SL.accent)
                        .italic()
                    Text(detail)
                        .font(SL.body(13))
                        .foregroundColor(SL.textSecondary)
                        .lineSpacing(3)
                }
            }
            if let label = actionLabel {
                if let story = destination {
                    NavigationLink(destination: StoryDetailView(story: story)) {
                        Text(label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(SL.background)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(SL.border, lineWidth: 1))
                    }
                } else {
                    Button(action: {}) {
                        Text(label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(SL.background)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(SL.border, lineWidth: 1))
                    }
                }
            }
        }
        .padding(14)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
    }
}

#Preview {
    ReaderActivityView()
}
