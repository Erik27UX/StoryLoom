import SwiftUI
import SwiftData

struct StoriesLibraryView: View {
    @Query(sort: \StoryEntry.dateCreated, order: .reverse) private var stories: [StoryEntry]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your stories")
                        .font(SL.heading(28))
                        .foregroundColor(SL.textPrimary)

                    if stories.isEmpty {
                        LibraryEmptyState()
                    } else {
                        ForEach(stories) { story in
                            StoryLibraryCard(story: story)
                        }
                    }

                    // Locked upgrade card
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(SL.primary)
                                .frame(width: 44, height: 44)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "FDF9F0"))
                        }

                        Text("More stories waiting")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(SL.textPrimary)

                        Text("Upgrade to unlock and share with family")
                            .font(SL.body(14))
                            .foregroundColor(SL.textSecondary)

                        Button(action: {}) {
                            Text("Unlock \u{2014} $12/month")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "FDF9F0"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(SL.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(SL.surface.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SL.border, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(SL.background)
        }
    }
}

struct StoryLibraryCard: View {
    let story: StoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(SL.accent.opacity(0.15))
                    .frame(height: 80)
                Image(systemName: "photo.fill")
                    .font(.system(size: 24))
                    .foregroundColor(SL.accent.opacity(0.4))
            }

            HStack(alignment: .top) {
                Text(story.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SL.textPrimary)
                Spacer()
                if story.isInVault {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 11))
                        Text("Vault")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(SL.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(SL.accent.opacity(0.1))
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

struct LibraryEmptyState: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.stack")
                .font(.system(size: 32))
                .foregroundColor(SL.accent.opacity(0.5))
            Text("No stories yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(SL.textPrimary)
            Text("Head to the Home tab to answer your first prompt.")
                .font(SL.body(14))
                .foregroundColor(SL.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
    }
}

#Preview {
    StoriesLibraryView()
}
